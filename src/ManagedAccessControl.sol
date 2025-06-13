// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Closable} from "./Closable.sol";

import {AccessControlDefaultAdminRules} from
  "@openzeppelin/contracts/access/extensions/AccessControlDefaultAdminRules.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";

/// @notice Base contract that adds pausing, closing, and access control functionality.
abstract contract ManagedAccessControl is Pausable, Closable, AccessControlDefaultAdminRules {
  /// @notice This is the ID for the pauser role, which is given to the addresses that can pause and
  /// unpause the contract.
  /// @dev Hash: 65d7a28e3265b37a6474929f336521b332c1681b933f6cb9f3376673440d862a
  bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

  constructor(
    uint48 adminRoleTransferDelay,
    address admin
  ) AccessControlDefaultAdminRules(adminRoleTransferDelay, admin) {}

  /// @notice This function pauses the contract
  /// @dev Sets the pause flag to true
  function emergencyPause() external onlyRole(PAUSER_ROLE) {
    _pause();
  }

  /// @notice This function unpauses the contract
  /// @dev Sets the pause flag to false
  function emergencyUnpause() external onlyRole(PAUSER_ROLE) {
    _unpause();
  }

  /// @notice Closes the contract
  /// @dev This is an irreversible operation
  /// @dev Only callable by the default admin
  /// @dev Only callable when the contract is open
  function close() external onlyRole(DEFAULT_ADMIN_ROLE) {
    _close();
  }
}
