// SPDX-License-Identifier: MIT
// imported from https://etherscan.io/token/0xE6Bfd33F52d82Ccb5b37E16D3dD81f9FFDAbB195
// NOTE: Deployed SpaceAndTime uses solc 0.8.28;
// pragma solidity 0.8.28;
pragma solidity 0.8.26;

import {AccessControl} from "@openzeppelin@5.2.0/contracts/access/AccessControl.sol";
import {ERC20} from "@openzeppelin@5.2.0/contracts/token/ERC20/ERC20.sol";
import {ERC20Pausable} from "@openzeppelin@5.2.0/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import {ERC20Permit} from "@openzeppelin@5.2.0/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {ERC20Votes} from "@openzeppelin@5.2.0/contracts/token/ERC20/extensions/ERC20Votes.sol";
import {Nonces} from "@openzeppelin@5.2.0/contracts/utils/Nonces.sol";

contract SpaceAndTime is ERC20, ERC20Pausable, AccessControl, ERC20Permit, ERC20Votes {
  bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

  constructor(
    address defaultAdmin,
    address pauser,
    address recipient
  ) ERC20("Space and Time", "SXT") ERC20Permit("Space and Time") {
    _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
    _grantRole(PAUSER_ROLE, pauser);
    _mint(recipient, 5_000_000_000 * 10 ** decimals());
  }

  function pause() public onlyRole(PAUSER_ROLE) {
    _pause();
  }

  function unpause() public onlyRole(PAUSER_ROLE) {
    _unpause();
  }

  function _update(
    address from,
    address to,
    uint256 value
  ) internal override(ERC20, ERC20Pausable, ERC20Votes) {
    super._update(from, to, value);
  }

  function nonces(
    address owner
  ) public view override(ERC20Permit, Nonces) returns (uint256) {
    return super.nonces(owner);
  }
}
