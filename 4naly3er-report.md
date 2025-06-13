# Report


## Gas Optimizations


| |Issue|Instances|
|-|:-|:-:|
| [GAS-1](#GAS-1) | `a = a + b` is more gas effective than `a += b` for state variables (excluding arrays and mappings) | 9 |
| [GAS-2](#GAS-2) | Using bools for storage incurs overhead | 1 |
| [GAS-3](#GAS-3) | Cache array length outside of loop | 1 |
| [GAS-4](#GAS-4) | For Operations that will not overflow, you could use unchecked | 69 |
| [GAS-5](#GAS-5) | Avoid contract existence checks by using low level calls | 2 |
| [GAS-6](#GAS-6) | Functions guaranteed to revert when called by normal users can be marked `payable` | 1 |
| [GAS-7](#GAS-7) | Using `private` rather than `public` for constants, saves gas | 2 |
| [GAS-8](#GAS-8) | Increments/decrements can be unchecked in for-loops | 5 |
### <a name="GAS-1"></a>[GAS-1] `a = a + b` is more gas effective than `a += b` for state variables (excluding arrays and mappings)
This saves **16 gas per instance.**

*Instances (9)*:
```solidity
File: ./src/BUILDClaim.sol

385:         globalState.totalLoyalty +=

387:         globalState.totalLoyaltyIneligible += param.maxTokenAmount;

389:         toBeClaimed += claimableState.earlyVestableBonus;

392:       totalClaimableAmount += toBeClaimed;

438:     userState.claimed += uint248(toBeClaimed);

441:     globalState.totalClaimed += toBeClaimed;

```

```solidity
File: ./src/BUILDFactory.sol

333:     tokenAmounts.totalAllocatedToAllSeasons += amount;

414:     s_tokenAmounts[token].totalRefunded += refundEligible + totalLoyaltyRefundEligible;

518:     s_tokenAmounts[token].totalWithdrawn += withdrawal.amount;

```

### <a name="GAS-2"></a>[GAS-2] Using bools for storage incurs overhead
Use uint256(1) and uint256(2) for true/false to avoid a Gwarmaccess (100 gas), and to avoid Gsset (20000 gas) when changing from ‘false’ to ‘true’, after having been ‘true’ in the past. See [source](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/58f635312aa21f947cae5f8578638a85aa2519f5/contracts/security/ReentrancyGuard.sol#L23-L27).

*Instances (1)*:
```solidity
File: ./src/BUILDFactory.sol

64:   mapping(address token => bool paused) private s_claimPaused;

```

### <a name="GAS-3"></a>[GAS-3] Cache array length outside of loop
If not cached, the solidity compiler will always read the length of the array during each iteration. That is, if it is a storage array, this is an extra sload operation (100 additional extra gas for each iteration except for the first) and if it is a memory array, this is an extra mload operation (3 additional gas for each iteration except for the first).

*Instances (1)*:
```solidity
File: ./src/BUILDFactory.sol

230:     for (uint256 i = 0; i < params.length; ++i) {

```

### <a name="GAS-4"></a>[GAS-4] For Operations that will not overflow, you could use unchecked

*Instances (69)*:
```solidity
File: ./src/BUILDClaim.sol

4: import {IBUILDClaim} from "./interfaces/IBUILDClaim.sol";

5: import {IBUILDFactory} from "./interfaces/IBUILDFactory.sol";

6: import {ITypeAndVersion} from "chainlink/contracts/src/v0.8/shared/interfaces/ITypeAndVersion.sol";

7: import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

8: import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

9: import {IAccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

11: import {BUILDFactory} from "./BUILDFactory.sol";

12: import {Closable} from "./Closable.sol";

14: import {FixedPointMathLib} from "@solmate/FixedPointMathLib.sol";

15: import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

16: import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";

17: import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

18: import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

26:     uint256 unlockElapsedDuration; // The amount of time that has elapsed since

28:     bool isBeforeUnlock; // Whether the unlock period has started (including the delay)

29:     bool isUnlocking; // Whether the unlock period is in progress

97:     if (balanceBefore + amount != balanceAfter) {

141:     for (uint256 i; i < count; ++i) {

205:       (maxTokenAmount * config.baseTokenClaimBps) / PERCENTAGE_BASIS_POINTS_DENOMINATOR;

206:     claimableState.bonus = maxTokenAmount - claimableState.base;

218:     claimableState.loyaltyBonus = maxTokenAmount * globalState.totalLoyalty

219:       / (config.tokenAmount - globalState.totalLoyaltyIneligible);

224:         (claimableState.bonus * unlockState.unlockElapsedDuration) / config.unlockDuration;

226:         claimableState.base + claimableState.vested - claimableState.claimed;

232:         maxTokenAmount + claimableState.loyaltyBonus - claimableState.claimed;

249:       claimableState.bonus - claimableState.vested,

251:         + (

253:             config.earlyVestRatioMaxBps - config.earlyVestRatioMinBps,

255:           ) * timeElapsed

256:         ) / config.unlockDuration

272:     uint256 unlockDelayEndsAt = unlockStartsAt + unlockDelay;

278:       isUnlocking: targetTime < unlockDelayEndsAt + unlockDuration,

279:       unlockElapsedDuration: targetTime - unlockDelayEndsAt

343:     for (uint256 i = 0; i < paramsLength; ++i) {

385:         globalState.totalLoyalty +=

386:           claimableState.bonus - claimableState.vested - claimableState.earlyVestableBonus;

387:         globalState.totalLoyaltyIneligible += param.maxTokenAmount;

389:         toBeClaimed += claimableState.earlyVestableBonus;

392:       totalClaimableAmount += toBeClaimed;

438:     userState.claimed += uint248(toBeClaimed);

441:     globalState.totalClaimed += toBeClaimed;

```

```solidity
File: ./src/BUILDFactory.sol

4: import {IBUILDFactory} from "./interfaces/IBUILDFactory.sol";

5: import {ITypeAndVersion} from "chainlink/contracts/src/v0.8/shared/interfaces/ITypeAndVersion.sol";

7: import {IBUILDClaim} from "./interfaces/IBUILDClaim.sol";

8: import {BUILDClaim} from "./BUILDClaim.sol";

9: import {ManagedAccessControl} from "./ManagedAccessControl.sol";

11: import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

12: import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

13: import {FixedPointMathLib} from "@solmate/FixedPointMathLib.sol";

14: import {IDelegateRegistry} from "@delegatexyz/delegate-registry/v2.0/src/IDelegateRegistry.sol";

25:     address admin; // ───────────────────╮ The initial factory admin address

26:     uint40 maxUnlockDuration; //         │ The initial max unlock duration

27:     uint40 maxUnlockDelay; // ───────────╯ The initial max unlock delay

28:     IDelegateRegistry delegateRegistry; // The initial delegate registry contract

98:     for (uint256 i = 0; i < projectsLength; ++i) {

121:     for (uint256 i = 0; i < tokensLength; ++i) {

230:     for (uint256 i = 0; i < params.length; ++i) {

325:     maxAvailable = maxAvailable + currentAmount - s_withdrawals[token].amount;

331:       tokenAmounts.totalAllocatedToAllSeasons -= currentAmount;

333:     tokenAmounts.totalAllocatedToAllSeasons += amount;

366:     uint256 newTotalDeposited = tokenAmounts.totalDeposited + amount;

384:     s_refundableAmounts[token][seasonId] -= amount;

386:       token, seasonId, amount, currentRefundableAmount - amount

414:     s_tokenAmounts[token].totalRefunded += refundEligible + totalLoyaltyRefundEligible;

435:     uint256 totalLoyaltyEligible = tokenAmount - globalState.totalLoyaltyIneligible;

458:     return s_refundableAmounts[token][seasonId] + totalLoyaltyRefundEligible;

474:     return tokenAmounts.totalDeposited + tokenAmounts.totalRefunded - tokenAmounts.totalWithdrawn

475:       - tokenAmounts.totalAllocatedToAllSeasons;

518:     s_tokenAmounts[token].totalWithdrawn += withdrawal.amount;

```

### <a name="GAS-5"></a>[GAS-5] Avoid contract existence checks by using low level calls
Prior to 0.8.10 the compiler inserted extra code, including `EXTCODESIZE` (**100 gas**), to check for contract existence for external function calls. In more recent solidity versions, the compiler will not insert these checks if the external call has a return value. Similar behavior can be achieved in earlier versions by using low-level calls, since low level calls never check for contract existence

*Instances (2)*:
```solidity
File: ./src/BUILDClaim.sol

93:     uint256 balanceBefore = i_token.balanceOf(address(this));

96:     uint256 balanceAfter = i_token.balanceOf(address(this));

```

### <a name="GAS-6"></a>[GAS-6] Functions guaranteed to revert when called by normal users can be marked `payable`
If a function modifier such as `onlyOwner` is used, the function will revert if a normal user tries to pay the function. Marking the function as `payable` will lower the gas cost for legitimate callers because the compiler will not include checks for whether a payment was provided.

*Instances (1)*:
```solidity
File: ./src/BUILDClaim.sol

109:   function withdraw() external override nonReentrant onlyProjectAdmin {

```

### <a name="GAS-7"></a>[GAS-7] Using `private` rather than `public` for constants, saves gas
If needed, the values can be read from the verified contract source code, or if there are multiple values there can be a single getter function that [returns a tuple](https://github.com/code-423n4/2022-08-frax/blob/90f55a9ce4e25bceed3a74290b854341d8de6afa/src/contracts/FraxlendPair.sol#L156-L178) of the values of all currently-public constants. Saves **3406-3606 gas** in deployment gas due to the compiler not having to create non-payable getter functions for deployment calldata, not having to store the bytes of the value outside of where it's used, and not adding another entry to the method ID table

*Instances (2)*:
```solidity
File: ./src/BUILDClaim.sol

33:   string public constant override typeAndVersion = "BUILDClaim 1.0.0";

```

```solidity
File: ./src/BUILDFactory.sol

21:   string public constant override typeAndVersion = "BUILDFactory 1.0.0";

```

### <a name="GAS-8"></a>[GAS-8] Increments/decrements can be unchecked in for-loops
In Solidity 0.8+, there's a default overflow check on unsigned integers. It's possible to uncheck this in for-loops and save some gas at each iteration, but at the cost of some code readability, as this uncheck cannot be made inline.

[ethereum/solidity#10695](https://github.com/ethereum/solidity/issues/10695)

The change would be:

```diff
- for (uint256 i; i < numIterations; i++) {
+ for (uint256 i; i < numIterations;) {
 // ...  
+   unchecked { ++i; }
}  
```

These save around **25 gas saved** per instance.

The same can be applied with decrements (which should use `break` when `i == 0`).

The risk of overflow is non-existent for `uint256`.

*Instances (5)*:
```solidity
File: ./src/BUILDClaim.sol

141:     for (uint256 i; i < count; ++i) {

343:     for (uint256 i = 0; i < paramsLength; ++i) {

```

```solidity
File: ./src/BUILDFactory.sol

98:     for (uint256 i = 0; i < projectsLength; ++i) {

121:     for (uint256 i = 0; i < tokensLength; ++i) {

230:     for (uint256 i = 0; i < params.length; ++i) {

```


## Non Critical Issues


| |Issue|Instances|
|-|:-|:-:|
| [NC-1](#NC-1) | Control structures do not follow the Solidity Style Guide | 12 |
| [NC-2](#NC-2) | Functions should not be longer than 50 lines | 11 |
| [NC-3](#NC-3) | Use a `modifier` instead of a `require/if` statement for a special `msg.sender` actor | 4 |
| [NC-4](#NC-4) | Take advantage of Custom Error's return value property | 13 |
| [NC-5](#NC-5) | Variables need not be initialized to zero | 4 |
### <a name="NC-1"></a>[NC-1] Control structures do not follow the Solidity Style Guide
See the [control structures](https://docs.soliditylang.org/en/latest/style-guide.html#control-structures) section of the Solidity Style Guide

*Instances (12)*:
```solidity
File: ./src/BUILDClaim.sol

172:   function _verifyMerkleProof(

182:     return MerkleProof.verify(proof, root, leaf);

214:     if (userState.hasEarlyClaimed || unlockState.isBeforeUnlock) return claimableState;

316:     if (

317:       !_verifyMerkleProof(

368:       if (

404:       if (

```

```solidity
File: ./src/BUILDFactory.sol

100:       if (

150:     if (msg.sender != project.admin) revert Unauthorized();

271:     if (

282:     if (

600:     if (!s_projectsList.contains(token)) revert ProjectDoesNotExist(token);

```

### <a name="NC-2"></a>[NC-2] Functions should not be longer than 50 lines
Overly complex code can make understanding functionality more difficult, try to further modularize your code to ensure readability 

*Instances (11)*:
```solidity
File: ./src/BUILDClaim.sol

64:   function getFactory() external view override returns (BUILDFactory) {

69:   function getToken() external view override returns (IERC20) {

109:   function withdraw() external override nonReentrant onlyProjectAdmin {

337:   function _claim(address user, ClaimParams[] memory params) private {

```

```solidity
File: ./src/BUILDFactory.sol

133:   function getProjects() external view override returns (address[] memory) {

207:   function getUnlockConfigMaxValues() external view override returns (UnlockMaxConfigs memory) {

360:   function addTotalDeposited(address token, uint256 amount) external override returns (uint256) {

445:   function isRefunding(address token, uint256 seasonId) external view override returns (bool) {

471:   function _calcMaxAvailableForWithdrawalOrNewSeason(

539:   function _validateNewWithdrawal(address token, uint256 amount) private view {

607:   function getDelegateRegistry() external view returns (IDelegateRegistry) {

```

### <a name="NC-3"></a>[NC-3] Use a `modifier` instead of a `require/if` statement for a special `msg.sender` actor
If a function is supposed to be access-controlled, a `modifier` should be used instead of a `require/if` statement for more readability.

*Instances (4)*:
```solidity
File: ./src/BUILDClaim.sol

403:     if (isEarlyClaim && user != msg.sender) {

458:     if (msg.sender != i_factory.getProjectConfig(address(i_token)).admin) {

```

```solidity
File: ./src/BUILDFactory.sol

150:     if (msg.sender != project.admin) revert Unauthorized();

166:     if (address(s_projects[token].claim) != msg.sender) {

```

### <a name="NC-4"></a>[NC-4] Take advantage of Custom Error's return value property
An important feature of Custom Error is that values such as address, tokenID, msg.value can be written inside the () sign, this kind of approach provides a serious advantage in debugging and examining the revert details of dapps such as tenderly.

*Instances (13)*:
```solidity
File: ./src/BUILDClaim.sol

90:       revert Closable.AlreadyClosed();

321:       revert InvalidMerkleProof();

467:       revert Pausable.EnforcedPause();

```

```solidity
File: ./src/BUILDFactory.sol

104:         revert InvalidAddProjectParams();

150:     if (msg.sender != project.admin) revert Unauthorized();

167:       revert Unauthorized();

188:       revert InvalidZeroMaxUnlockDuration();

192:       revert InvalidZeroMaxUnlockDelay();

363:       revert InvalidAmount();

382:       revert InvalidAmount();

571:       revert ExpectedPause();

591:       revert EnforcedPause();

621:       revert InvalidZeroAddress();

```

### <a name="NC-5"></a>[NC-5] Variables need not be initialized to zero
The default value for variables is zero, so initializing them to zero is superfluous.

*Instances (4)*:
```solidity
File: ./src/BUILDClaim.sol

343:     for (uint256 i = 0; i < paramsLength; ++i) {

```

```solidity
File: ./src/BUILDFactory.sol

98:     for (uint256 i = 0; i < projectsLength; ++i) {

121:     for (uint256 i = 0; i < tokensLength; ++i) {

230:     for (uint256 i = 0; i < params.length; ++i) {

```


## Low Issues


| |Issue|Instances|
|-|:-|:-:|
| [L-1](#L-1) | `decimals()` is not a part of the ERC-20 standard | 1 |
| [L-2](#L-2) | Division by zero not prevented | 2 |
| [L-3](#L-3) | Signature use at deadlines should be allowed | 3 |
| [L-4](#L-4) | Possible rounding issue | 1 |
| [L-5](#L-5) | Loss of precision | 2 |
### <a name="L-1"></a>[L-1] `decimals()` is not a part of the ERC-20 standard
The `decimals()` function is not a part of the [ERC-20 standard](https://eips.ethereum.org/EIPS/eip-20), and was added later as an [optional extension](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/extensions/IERC20Metadata.sol). As such, some valid ERC20 tokens do not support this interface, so it is unsafe to blindly cast all tokens to this interface, and then call this function.

*Instances (1)*:
```solidity
File: ./src/BUILDFactory.sol

102:           || IERC20Metadata(params.token).decimals() == 0

```

### <a name="L-2"></a>[L-2] Division by zero not prevented
The divisions below take an input parameter which does not have any zero-value checks, which may lead to the functions reverting when zero is passed.

*Instances (2)*:
```solidity
File: ./src/BUILDClaim.sol

219:       / (config.tokenAmount - globalState.totalLoyaltyIneligible);

256:         ) / config.unlockDuration

```

### <a name="L-3"></a>[L-3] Signature use at deadlines should be allowed
According to [EIP-2612](https://github.com/ethereum/EIPs/blob/71dc97318013bf2ac572ab63fab530ac9ef419ca/EIPS/eip-2612.md?plain=1#L58), signatures used on exactly the deadline timestamp are supposed to be allowed. While the signature may or may not be used for the exact EIP-2612 use case (transfer approvals), for consistency's sake, all deadlines should follow this semantic. If the timestamp is an expiration rather than a deadline, consider whether it makes more sense to include the expiration timestamp as a valid timestamp, as is done for deadlines.

*Instances (3)*:
```solidity
File: ./src/BUILDFactory.sol

218:     bool hasUnlockStarted = currentUnlockStartTime != 0 && currentUnlockStartTime <= block.timestamp;

219:     if (hasUnlockStarted || unlockStartsAt <= block.timestamp) {

247:     if (unlockStartsAt <= block.timestamp) {

```

### <a name="L-4"></a>[L-4] Possible rounding issue
Division by large numbers may result in the result being zero, due to solidity not supporting fractions. Consider requiring a minimum amount for the numerator to ensure that it is always larger than the denominator. Also, there is indication of multiplication and division without the use of parenthesis which could result in issues.

*Instances (1)*:
```solidity
File: ./src/BUILDClaim.sol

219:       / (config.tokenAmount - globalState.totalLoyaltyIneligible);

```

### <a name="L-5"></a>[L-5] Loss of precision
Division by large numbers may result in the result being zero, due to solidity not supporting fractions. Consider requiring a minimum amount for the numerator to ensure that it is always larger than the denominator

*Instances (2)*:
```solidity
File: ./src/BUILDClaim.sol

205:       (maxTokenAmount * config.baseTokenClaimBps) / PERCENTAGE_BASIS_POINTS_DENOMINATOR;

219:       / (config.tokenAmount - globalState.totalLoyaltyIneligible);

```


## Medium Issues


| |Issue|Instances|
|-|:-|:-:|
| [M-1](#M-1) | Centralization Risk for trusted owners | 13 |
### <a name="M-1"></a>[M-1] Centralization Risk for trusted owners

#### Impact:
Contracts have owners with privileged rights to perform admin tasks and need to be trusted to not perform malicious updates or drain funds.

*Instances (13)*:
```solidity
File: ./src/BUILDFactory.sol

16: contract BUILDFactory is IBUILDFactory, ITypeAndVersion, ManagedAccessControl {

78:   ) ManagedAccessControl(0, params.admin) {

95:   ) external override whenOpen onlyRole(DEFAULT_ADMIN_ROLE) {

117:   ) external override whenOpen onlyRole(DEFAULT_ADMIN_ROLE) {

178:   ) external override onlyRole(DEFAULT_ADMIN_ROLE) whenOpen {

215:   ) external override whenOpen onlyRole(DEFAULT_ADMIN_ROLE) {

229:   ) external override whenOpen onlyRole(DEFAULT_ADMIN_ROLE) {

401:   ) external override onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {

487:   ) external override onlyRole(DEFAULT_ADMIN_ROLE) {

499:   ) external override onlyRole(DEFAULT_ADMIN_ROLE) {

559:   ) external override onlyRole(PAUSER_ROLE) {

569:   ) external override onlyRole(PAUSER_ROLE) {

613:   ) external onlyRole(DEFAULT_ADMIN_ROLE) {

```
