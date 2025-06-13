// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "@openzeppelin/contracts/interfaces/IERC20.sol";

/// @notice This is a simplified ERC20 token contract that incorrectly tracks balances for testing
/// purposes.
contract InvalidTransferERC20Token is IERC20 {
  mapping(address account => uint256) private _balances;
  mapping(address account => mapping(address spender => uint256)) private _allowances;
  uint256 private _totalSupply;
  uint8 private immutable _decimals;

  constructor(
    uint8 decimals
  ) {
    _decimals = decimals;
    _balances[msg.sender] = 1_000_000_000e18;
  }

  function decimals() public view returns (uint8) {
    return _decimals;
  }

  function totalSupply() public view virtual returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(
    address account
  ) public view virtual returns (uint256) {
    return _balances[account];
  }

  function transfer(address to, uint256 value) public virtual returns (bool) {
    _transfer(msg.sender, to, value);
    return true;
  }

  function transferFrom(address from, address to, uint256 value) public virtual returns (bool) {
    _spendAllowance(from, msg.sender, value);
    _transfer(from, to, value);
    return true;
  }

  function approve(address spender, uint256 value) public virtual returns (bool) {
    _allowances[msg.sender][spender] = value;
    return true;
  }

  function allowance(address owner, address spender) public view virtual returns (uint256) {
    return _allowances[owner][spender];
  }

  function _spendAllowance(address owner, address spender, uint256 value) internal virtual {
    uint256 currentAllowance = allowance(owner, spender);
    if (currentAllowance != type(uint256).max) {
      if (currentAllowance < value) {
        revert("ERC20: insufficient allowance");
      }
      _allowances[owner][spender] = currentAllowance - value;
    }
  }

  function _transfer(address from, address to, uint256 value) internal virtual {
    _balances[from] -= value;
    _balances[address(this)] += value; // Doesn't increase the recipient's balance as it should
  }

  // added to be excluded from coverage report
  function test() public virtual {}
}
