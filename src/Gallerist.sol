// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";


contract Gallerist is Context, IERC20, Ownable{
    
    string _name = "Gallerist";
    string _symbol = "GAL";

    uint _totalSupply = 1_000_000_000e18;
    uint taxFee = 8;

    address public saleContract;
    address public marketingAddress;
    address public teamAddress;
    address public partnerAdvisorAddress;
    address public bonusReferralAddress;

    error AlreadyExcluded();

    error AlreadyIncluded();

    mapping(address => bool) isExcludedFromFees;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;


    constructor (
        address _saleContract,
        address _marketingAddress,
        address _teamAddress,
        address _partnerAdvisorAddress,
        address _bonusReferralAddress
    ) {
        saleContract = _saleContract;
        marketingAddress = _marketingAddress;
        teamAddress = _teamAddress;
        partnerAdvisorAddress = _partnerAdvisorAddress;
        bonusReferralAddress = _bonusReferralAddress;

        _balances[saleContract] = 500_000_000e18;
        _balances[marketingAddress] = 150_000_000e18;
        _balances[teamAddress] = 180_000_000e18;
        _balances[partnerAdvisorAddress] = 90_000_000e18;
        _balances[bonusReferralAddress] = 80_000_000e18;

        isExcludedFromFees[address(this)] = true;
        isExcludedFromFees[owner()] = true;
        isExcludedFromFees[saleContract] = true;
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256){
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256){
        return _balances[account];
    }

    function allowance(address _owner, address spender) public view virtual override returns (uint256) {
        return _allowances[_owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address _owner = _msgSender();
        _approve(_owner, spender, amount);
        return true;
    }

    function excludeFromFees(address account) public onlyOwner {
        if(isExcludedFromFees[account] == true) revert AlreadyExcluded();
        isExcludedFromFees[account] = true;
    }

    function includeInFees(address account) public onlyOwner {
        if(isExcludedFromFees[account] == false) revert AlreadyIncluded();
        isExcludedFromFees[account] = false;
    }

    function setTaxFee(uint _taxFee) public onlyOwner returns(bool){
        taxFee = _taxFee;
        return true;
    }

    function transfer(
        address to,
        uint amount
        ) public virtual override returns(bool){
        _transfer(_msgSender(), to, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint amount
        ) public virtual override returns(bool){
        _transfer(from, to, amount);
        return true;
    }

    function calculateTaxFee(uint _amount) private view returns(uint){
        uint amount = _amount*(taxFee*10**18/100);
        return amount;
    }

    function takeFee(uint _amount) private returns(uint){
       uint feeAmount = calculateTaxFee(_amount)/10**18;
       uint currentBalance = _balances[address(this)];
       _balances[address(this)] = currentBalance + feeAmount;
       return feeAmount;
    }


    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }

        if(!isExcludedFromFees[from]){
            uint amountReceived = amount - takeFee(amount);
            _balances[to] += amountReceived;

            emit Transfer(from, to, amountReceived);
        }

        if(isExcludedFromFees[from]){
            _balances[to] += amount;

            emit Transfer(from, to, amount);
        }
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }


    function withdrawTokenBalance(address recipient) public onlyOwner returns(bool){
        uint currentBalance = _balances[address(this)];
        transferFrom(address(this), recipient, currentBalance);
        return true;
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

}
