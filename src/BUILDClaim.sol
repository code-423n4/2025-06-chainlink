// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IBUILDClaim} from "./interfaces/IBUILDClaim.sol";
import {IBUILDFactory} from "./interfaces/IBUILDFactory.sol";
import {ITypeAndVersion} from "chainlink/contracts/src/v0.8/shared/interfaces/ITypeAndVersion.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

import {BUILDFactory} from "./BUILDFactory.sol";
import {Closable} from "./Closable.sol";

import {FixedPointMathLib} from "@solmate/FixedPointMathLib.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract BUILDClaim is IBUILDClaim, ITypeAndVersion, ReentrancyGuard {
  using SafeERC20 for IERC20;
  using FixedPointMathLib for uint256;

  /// @notice The unlock state for a season at a given time
  struct UnlockState {
    uint256 unlockElapsedDuration; // The amount of time that has elapsed since
      // the unlock delay started
    bool isBeforeUnlock; // Whether the unlock period has started (including the delay)
    bool isUnlocking; // Whether the unlock period is in progress
  }

  /// @inheritdoc ITypeAndVersion
  string public constant override typeAndVersion = "BUILDClaim 1.0.0";

  /// @notice The claimed and early claimed states for a user per season
  mapping(address user => mapping(uint256 seasonId => UserState)) private s_userStates;

  /// @notice The global states for a season
  mapping(uint256 seasonId => GlobalState globalState) private s_globalStates;

  /// @notice The project token
  IERC20 private immutable i_token;

  /// @notice The factory that deployed this contract
  BUILDFactory private immutable i_factory;

  /// @notice The basis points denominator for percentages
  uint256 private constant PERCENTAGE_BASIS_POINTS_DENOMINATOR = 10_000;

  // ================================================================
  // |                       Initialization                         |
  // ================================================================

  /// @notice constructor
  /// @param token The project token
  constructor(
    address token
  ) {
    i_token = IERC20(token);
    i_factory = BUILDFactory(msg.sender);
  }

  /// @inheritdoc IBUILDClaim
  function getFactory() external view override returns (BUILDFactory) {
    return i_factory;
  }

  /// @inheritdoc IBUILDClaim
  function getToken() external view override returns (IERC20) {
    return i_token;
  }

  /// @inheritdoc IERC165
  function supportsInterface(
    bytes4 interfaceId
  ) external pure override returns (bool) {
    return interfaceId == type(IBUILDClaim).interfaceId || interfaceId == type(IERC165).interfaceId;
  }

  // ================================================================
  // |                        Token Deposits                        |
  // ================================================================

  /// @inheritdoc IBUILDClaim
  function deposit(
    uint256 amount
  ) external override nonReentrant whenClaimNotPaused onlyProjectAdmin {
    // only callable when factory contract is open
    if (!i_factory.isOpen()) {
      revert Closable.AlreadyClosed();
    }

    uint256 balanceBefore = i_token.balanceOf(address(this));
    uint256 totalDeposited = i_factory.addTotalDeposited(address(i_token), amount);
    i_token.safeTransferFrom(msg.sender, address(this), amount);
    uint256 balanceAfter = i_token.balanceOf(address(this));
    if (balanceBefore + amount != balanceAfter) {
      revert InvalidDeposit(balanceBefore, balanceAfter);
    }

    emit Deposited(address(i_token), msg.sender, amount, totalDeposited);
  }

  // ================================================================
  // |                       Token Withdrawals                      |
  // ================================================================

  /// @inheritdoc IBUILDClaim
  function withdraw() external override nonReentrant onlyProjectAdmin {
    (IBUILDFactory.Withdrawal memory withdrawal, uint256 totalWithdrawn) =
      i_factory.executeWithdraw(address(i_token));
    i_token.safeTransfer(withdrawal.recipient, withdrawal.amount);
    emit Withdrawn(address(i_token), withdrawal.recipient, withdrawal.amount, totalWithdrawn);
  }

  // ================================================================
  // |                         Token Claims                         |
  // ================================================================

  /// @inheritdoc IBUILDClaim
  function claim(
    address user,
    ClaimParams[] calldata params
  ) external override nonReentrant whenClaimNotPaused {
    _claim(user, params);
  }

  /// @inheritdoc IBUILDClaim
  function getGlobalState(
    uint256 seasonId
  ) external view returns (GlobalState memory) {
    return s_globalStates[seasonId];
  }

  /// @inheritdoc IBUILDClaim
  function getUserState(
    UserSeasonId[] calldata usersAndSeasonIds
  ) external view returns (UserState[] memory) {
    uint256 count = usersAndSeasonIds.length;
    UserState[] memory states = new UserState[](count);
    for (uint256 i; i < count; ++i) {
      states[i] = s_userStates[usersAndSeasonIds[i].user][usersAndSeasonIds[i].seasonId];
    }
    return states;
  }

  /// @inheritdoc IBUILDClaim
  function getCurrentClaimValues(
    address user,
    uint256 seasonId,
    uint256 maxTokenAmount
  ) external view returns (ClaimableState memory) {
    (IBUILDFactory.ProjectSeasonConfig memory config, uint256 unlockStartsAt) =
      i_factory.getProjectSeasonConfig(address(i_token), seasonId);
    UnlockState memory unlockState =
      _getUnlockState(unlockStartsAt, config.unlockDelay, config.unlockDuration, block.timestamp);
    return _getClaimableState(
      config, s_globalStates[seasonId], s_userStates[user][seasonId], unlockState, maxTokenAmount
    );
  }

  /// @notice Validates if the user is eligible to claim the amount of tokens for a season
  /// A merkle tree's leaf consists of a user address, their max token amount for the season and a
  /// salt
  /// @param root The merkle root of a season
  /// @param user The user's address
  /// @param proof The merkle proof of the user's address, max token amount and salt
  /// @param maxTokenAmount The user's total claimable token amount for the season
  /// @param isEarlyClaim Whether the user is claiming early
  /// @param salt A randomly generated salt to prevent brute-force guessing of merkle proofs
  /// @return bool Returns true if the user's proof, maxTokenAmount and salt are valid
  function _verifyMerkleProof(
    bytes32 root,
    address user,
    bytes32[] memory proof,
    uint256 maxTokenAmount,
    bool isEarlyClaim,
    uint256 salt
  ) private pure returns (bool) {
    bytes32 leaf =
      keccak256(bytes.concat(keccak256(abi.encode(user, maxTokenAmount, isEarlyClaim, salt))));
    return MerkleProof.verify(proof, root, leaf);
  }

  /// @notice Calculates the amount of tokens that can be claimed by a user for a season
  /// without requiring an early claim at a particular timestamp.
  /// This amount is the sum of the base tokens amount that is released all at once after the
  /// unlock delay and the unlocked amount that is released linearly over the unlock duration.
  /// This does not factor in any claimed amounts
  /// @param config The project season config
  /// @param globalState The global state for the season
  /// @param userState The user state for the season
  /// @param unlockState The unlock state for the season
  /// @param maxTokenAmount The maximum token amount for the user
  /// @return ClaimableState The amount of tokens that can be claimed
  function _getClaimableState(
    IBUILDFactory.ProjectSeasonConfig memory config,
    IBUILDClaim.GlobalState memory globalState,
    UserState memory userState,
    UnlockState memory unlockState,
    uint256 maxTokenAmount
  ) internal pure returns (ClaimableState memory) {
    ClaimableState memory claimableState;
    claimableState.base =
      (maxTokenAmount * config.baseTokenClaimBps) / PERCENTAGE_BASIS_POINTS_DENOMINATOR;
    claimableState.bonus = maxTokenAmount - claimableState.base;

    if (config.tokenAmount == 0 || (config.isRefunding && userState.claimed == 0)) {
      return claimableState;
    }

    claimableState.claimed = userState.claimed;

    if (userState.hasEarlyClaimed || unlockState.isBeforeUnlock) return claimableState;
    // calculate share of loyalty pool to receive
    // The loyalty bonus is informative only in the unlock period, as it is not
    // claimable until the vesting is completed.
    claimableState.loyaltyBonus = maxTokenAmount * globalState.totalLoyalty
      / (config.tokenAmount - globalState.totalLoyaltyIneligible);

    if (unlockState.isUnlocking) {
      // unlock period is in progress
      claimableState.vested =
        (claimableState.bonus * unlockState.unlockElapsedDuration) / config.unlockDuration;
      claimableState.claimable =
        claimableState.base + claimableState.vested - claimableState.claimed;
      claimableState.earlyVestableBonus =
        _calcEarlyVestableBonus(claimableState, config, unlockState.unlockElapsedDuration);
    } else {
      // unlock completed
      claimableState.claimable =
        maxTokenAmount + claimableState.loyaltyBonus - claimableState.claimed;
    }

    return claimableState;
  }

  /// @notice Calculates the amount of bonus tokens that can be claimed early
  /// @param claimableState The claimable state for the user
  /// @param config The project season config
  /// @param timeElapsed The amount of time that has elapsed since the unlock delay started
  /// @return uint256 The amount of bonus tokens that can be claimed early
  function _calcEarlyVestableBonus(
    ClaimableState memory claimableState,
    IBUILDFactory.ProjectSeasonConfig memory config,
    uint256 timeElapsed
  ) private pure returns (uint256) {
    return FixedPointMathLib.mulWadDown(
      claimableState.bonus - claimableState.vested,
      FixedPointMathLib.divWadDown(config.earlyVestRatioMinBps, PERCENTAGE_BASIS_POINTS_DENOMINATOR)
        + (
          FixedPointMathLib.divWadDown(
            config.earlyVestRatioMaxBps - config.earlyVestRatioMinBps,
            PERCENTAGE_BASIS_POINTS_DENOMINATOR
          ) * timeElapsed
        ) / config.unlockDuration
    );
  }

  /// @notice Returns the unlock progress for a season
  /// @param unlockStartsAt The timestamp when the unlock period starts
  /// @param unlockDelay The delay before the unlock period starts
  /// @param unlockDuration The duration of the unlock period
  /// @param targetTime The timestamp to evaluate the unlock progress at
  /// @return UnlockState The unlock state for the target time
  function _getUnlockState(
    uint256 unlockStartsAt,
    uint256 unlockDelay,
    uint256 unlockDuration,
    uint256 targetTime
  ) internal pure returns (UnlockState memory) {
    uint256 unlockDelayEndsAt = unlockStartsAt + unlockDelay;
    if (targetTime < unlockDelayEndsAt) {
      return UnlockState({isBeforeUnlock: true, isUnlocking: false, unlockElapsedDuration: 0});
    }
    return UnlockState({
      isBeforeUnlock: false,
      isUnlocking: targetTime < unlockDelayEndsAt + unlockDuration,
      unlockElapsedDuration: targetTime - unlockDelayEndsAt
    });
  }

  /// @notice Validates the claim parameters for a user
  /// @param user The user address
  /// @param userState The user state for the season
  /// @param param The claim parameters for a user
  /// @param config The project season config
  /// @param unlockStartsAt The timestamp when the unlock period starts
  /// @param unlockState The unlock state for the season
  /// @dev Reverts if the claim parameters are invalid
  /// @dev Reverts if the unlock period has not started yet, including the configured unlock delay
  /// @dev Reverts if the project season does not exist for the given token address
  /// @dev Reverts if the user's proof is invalid
  /// @dev Reverts if user attempts to earlyClaim after previously early claiming during the unlock
  /// period
  function _validateClaimParams(
    address user,
    UserState memory userState,
    ClaimParams memory param,
    IBUILDFactory.ProjectSeasonConfig memory config,
    uint256 unlockStartsAt,
    UnlockState memory unlockState
  ) private view {
    if (user == address(0)) {
      revert InvalidUser(user);
    }
    if (unlockStartsAt == 0) {
      revert IBUILDFactory.SeasonDoesNotExist(param.seasonId);
    }
    if (unlockState.isBeforeUnlock) {
      revert UnlockNotStarted(param.seasonId);
    }
    if (config.tokenAmount == 0) {
      revert IBUILDFactory.ProjectSeasonDoesNotExist(param.seasonId, address(i_token));
    }
    if (
      !_verifyMerkleProof(
        config.merkleRoot, user, param.proof, param.maxTokenAmount, param.isEarlyClaim, param.salt
      )
    ) {
      revert InvalidMerkleProof();
    }
    if (unlockState.isUnlocking && param.isEarlyClaim && userState.hasEarlyClaimed) {
      revert InvalidEarlyClaim(user, param.seasonId);
    }
    if (userState.claimed == 0 && config.isRefunding) {
      // If the user hasn't claimed for this season before the refunding starts, the user will
      // be refunded their allocated credits but can no longer claim tokens
      revert IBUILDFactory.ProjectSeasonIsRefunding(address(i_token), param.seasonId);
    }
  }

  /// @notice Util function that claims tokens for a user for multiple seasons
  /// @param user The user address
  /// @param params An array of claim params including the season ID, proof, and max token amount
  /// for each season
  function _claim(address user, ClaimParams[] memory params) private {
    uint256 totalClaimableAmount;
    bool isEarlyClaim = false;

    // Cache array length outside loop
    uint256 paramsLength = params.length;
    for (uint256 i = 0; i < paramsLength; ++i) {
      ClaimParams memory param = params[i];
      if (param.isEarlyClaim) {
        isEarlyClaim = true;
      }
      (IBUILDFactory.ProjectSeasonConfig memory config, uint256 unlockStartsAt) =
        i_factory.getProjectSeasonConfig(address(i_token), param.seasonId);

      UserState memory userState = s_userStates[user][param.seasonId];
      UnlockState memory unlockState =
        _getUnlockState(unlockStartsAt, config.unlockDelay, config.unlockDuration, block.timestamp);

      _validateClaimParams(user, userState, param, config, unlockStartsAt, unlockState);

      if (userState.hasEarlyClaimed) {
        continue;
      }

      GlobalState storage globalState = s_globalStates[param.seasonId];
      ClaimableState memory claimableState =
        _getClaimableState(config, globalState, userState, unlockState, param.maxTokenAmount);

      // short-circuit on potential zero claim value before consuming refundable amount
      // if regular claim, claimable must be > 0
      // if early claim, earlyClaimable must be > 0
      if (
        (claimableState.claimable == 0 && !param.isEarlyClaim)
          || (
            claimableState.claimable == 0 && claimableState.earlyVestableBonus == 0
              && param.isEarlyClaim
          )
      ) {
        continue;
      }

      if (claimableState.claimed == 0) {
        // User is claiming for the first time for this particular season, so the project can no
        // longer reclaim the refundable amount for this user's credits
        i_factory.reduceRefundableAmount(address(i_token), param.seasonId, param.maxTokenAmount);
      }
      uint256 toBeClaimed = claimableState.claimable;
      if (unlockState.isUnlocking && param.isEarlyClaim) {
        globalState.totalLoyalty +=
          claimableState.bonus - claimableState.vested - claimableState.earlyVestableBonus;
        globalState.totalLoyaltyIneligible += param.maxTokenAmount;
        userState.hasEarlyClaimed = true;
        toBeClaimed += claimableState.earlyVestableBonus;
      }

      totalClaimableAmount += toBeClaimed;
      _updateClaimedAmounts(
        user,
        globalState,
        userState,
        param,
        toBeClaimed,
        param.isEarlyClaim ? claimableState.earlyVestableBonus : 0
      );
    }

    if (isEarlyClaim && user != msg.sender) {
      if (
        !i_factory.getDelegateRegistry().checkDelegateForContract({
          to: msg.sender,
          from: user,
          contract_: address(i_factory),
          rights: bytes32(0)
        })
      ) {
        revert InvalidSender(msg.sender);
      }
    }

    if (totalClaimableAmount == 0) {
      return;
    }
    i_token.safeTransfer(user, totalClaimableAmount);
  }

  /// @notice Updates the claimed amounts for a user and the season
  /// @param user The user address
  /// @param globalState The global state for the season
  /// @param userState The user state for the season
  /// @param param The input parameters for the claim
  /// @param toBeClaimed The amount of tokens to be claimed by the user
  /// @param earlyVestableBonus The amount of bonus tokens that can be claimed early
  /// @dev This function is called when a user claims tokens
  function _updateClaimedAmounts(
    address user,
    GlobalState storage globalState,
    UserState memory userState,
    ClaimParams memory param,
    uint256 toBeClaimed,
    uint256 earlyVestableBonus
  ) private {
    userState.claimed += uint248(toBeClaimed);
    s_userStates[user][param.seasonId] = userState;

    globalState.totalClaimed += toBeClaimed;

    emit Claimed(
      user,
      param.seasonId,
      toBeClaimed,
      param.isEarlyClaim,
      earlyVestableBonus,
      userState.claimed,
      globalState.totalClaimed,
      globalState.totalLoyalty,
      globalState.totalLoyaltyIneligible
    );
  }

  /// @notice Only callable by the factory contract admin
  modifier onlyProjectAdmin() {
    if (msg.sender != i_factory.getProjectConfig(address(i_token)).admin) {
      revert IAccessControl.AccessControlUnauthorizedAccount(msg.sender, keccak256("PROJECT_ADMIN"));
    }
    _;
  }

  /// @notice Only callable when claim contract is not paused
  modifier whenClaimNotPaused() {
    if (i_factory.isClaimContractPaused(address(i_token))) {
      revert Pausable.EnforcedPause();
    }
    _;
  }
}
