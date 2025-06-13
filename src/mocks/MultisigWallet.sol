pragma solidity 0.8.26;

/// @notice This is a modified version of the Safe contract for testing purposes only.
/// @dev Forked from and heavily simplified:
/// https://github.com/safe-global/safe-smart-account/blob/13c0494aca15985023b40c159c94163a4847307d/contracts/Safe.sol
/// https://github.com/safe-global/safe-smart-account/blob/13c0494aca15985023b40c159c94163a4847307d/contracts/base/Executor.sol
contract MultisigWallet {
  constructor() {}

  function execTransaction(
    address to,
    bytes memory data,
    bool useDelegateCall
  ) external returns (bool success) {
    uint256 gasToUse = gasleft() - 2500;
    if (useDelegateCall) {
      assembly {
        success := delegatecall(gasToUse, to, add(data, 0x20), mload(data), 0, 0)
      }
    } else {
      assembly {
        success := call(gasToUse, to, 0, add(data, 0x20), mload(data), 0, 0)
      }
    }
  }

  // added to be excluded from coverage report
  function test() public {}
}
