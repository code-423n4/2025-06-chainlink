// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "@openzeppelin/contracts/mocks/token/ERC20DecimalsMock.sol";

contract ERC20Token is ERC20DecimalsMock {
  constructor(
    string memory name,
    string memory symbol,
    uint8 decimals
  ) ERC20(name, symbol) ERC20DecimalsMock(decimals) {
    _mint(msg.sender, 1_000_000_000e18);
  }

  // added to be excluded from coverage report
  function test() public virtual {}
}
