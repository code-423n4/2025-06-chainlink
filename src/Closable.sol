// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/// @notice Abstract contract that adds closing functionality
abstract contract Closable {
  /// @notice This event is emitted when the factory is closed
  event Closed();

  /// @notice This error is thrown when attempting to close and the factory is already closed
  error AlreadyClosed();

  /// @notice Whether the contract is open for depositing and claiming
  bool private s_isOpen = true;

  /// @notice Closes the factory. Irreversible.
  /// Only callable by the default admin
  function _close() internal whenOpen {
    s_isOpen = false;
    emit Closed();
  }

  /// @notice Returns whether the contract is open or closed
  /// @return True if the contract is open
  function isOpen() external view returns (bool) {
    return s_isOpen;
  }

  /// @notice Modifier to check if the contract is open
  /// @dev Throws AlreadyClosed if the contract is closed
  modifier whenOpen() {
    if (!s_isOpen) revert AlreadyClosed();
    _;
  }
}
