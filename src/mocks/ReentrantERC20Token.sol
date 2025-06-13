// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {ERC20Token} from "./ERC20Token.sol";

contract ReentrantERC20Token is ERC20Token {
  address private _reenterTarget;
  bytes private _reenterData;
  bool _reentered;

  constructor(
    string memory name,
    string memory symbol,
    uint8 decimals
  ) ERC20Token(name, symbol, decimals) {
    disableReentrancy();
  }

  function disableReentrancy() public {
    _reentered = true;
  }

  function enableRentrancy(address target, bytes calldata data) external {
    _reenterTarget = target;
    _reenterData = data;
    _reentered = false;
  }

  function transferFrom(address from, address to, uint256 value) public override returns (bool) {
    _reenter();
    return super.transferFrom(from, to, value);
  }

  function transfer(address to, uint256 value) public override returns (bool) {
    _reenter();
    return super.transfer(to, value);
  }

  function _reenter() internal {
    if (!_reentered) {
      _reentered = true;
      Address.functionCall(_reenterTarget, _reenterData);
    }
  }

  // added to be excluded from coverage report
  function test() public override {}
}
