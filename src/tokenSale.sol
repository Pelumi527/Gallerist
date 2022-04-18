pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

contract TokenSaleContract is Context, Ownable{
    
    IERC20 ERC20;

    error NotEnoughToken();
    error MinimumTokenToBuyNotReached();

    bool public isPrivateSale;

    uint public tokenSold;
    uint public privateSalePrice = 0.005 ether;
    uint public publicSalePrice = 0.01 ether;
    uint publicPercentFee = 50;
    uint marketingPercentFee = 15;
    uint teamPercentFee = 18;
    uint partnerAdvisorPercentFee = 9;
    uint bonusReferralPercentFee = 8;
    uint public minimumSellToken = 1000;

    address public marketingAddress;
    address public teamAddress;
    address public publicAddress;
    address public partnerAdvisorAddress;
    address public bonusReferralAddress;

    event TokenSold(address buyer, uint numberOfToken);

    constructor(
        address _teamAddress,
        address _marketingAddress,
        address _partnerAdvisorAddress,
        address _publicAddress,
        address _bonusReferralAddress
    ){
        publicAddress = _publicAddress;
        teamAddress = _teamAddress;
        marketingAddress = _marketingAddress;
        partnerAdvisorAddress = _partnerAdvisorAddress;
        bonusReferralAddress = _bonusReferralAddress;
    }

    function addTokenAddress( address _tokenAddress) public onlyOwner returns(bool){
        ERC20 = IERC20(_tokenAddress);
        return true;
    }

    function startPrivateSale() public onlyOwner returns(bool){
        isPrivateSale = true;
        return true;
    }

    function stopPrivateSale() public onlyOwner returns(bool){
        isPrivateSale = false;
        return true;
    }

    
    function buy(uint tokenAmount) public payable returns(bool){
        
        uint tokenToTransfer;
        if(isPrivateSale == true){
            tokenToTransfer = (privateSalePrice*1000)/msg.value;
            if(tokenToTransfer < minimumSellToken) revert MinimumTokenToBuyNotReached();
        }
        if(isPrivateSale == false){
            tokenToTransfer = (1000*publicSalePrice)/msg.value;
        }
        //if(msg.value != amount) revert InSufficientBalance();
        if(ERC20.balanceOf(address(this)) < tokenToTransfer) revert NotEnoughToken();
        ERC20.transferFrom(address(this), _msgSender(), tokenToTransfer*10**18);

        tokenSold += tokenToTransfer;
        emit TokenSold(msg.sender, tokenToTransfer);

        return true;
    }

    function setPrivateSalePrice(uint amount) public onlyOwner returns(bool){
        privateSalePrice = amount;
        return true;
    }

    function setPublicSalePrice(uint amount) public onlyOwner returns(bool){
        publicSalePrice= amount;
        return true;
    }


    function setPercentFee(
        uint _publicPercentFee,
        uint _marketingPercentFee,
        uint _teamPercentFee,
        uint _bonusReferralPercentFee,
        uint _partnerAdvisorAddress
    ) public onlyOwner returns(bool){
        publicPercentFee = _publicPercentFee;
        marketingPercentFee = _marketingPercentFee;
        teamPercentFee = _teamPercentFee;
        bonusReferralPercentFee = _bonusReferralPercentFee;
        partnerAdvisorPercentFee = _partnerAdvisorAddress;
        return true;
    } 

    function calculatePayment() private view returns(uint,uint,uint,uint,uint){
        uint currentBalance = address(this).balance;
        uint publicFee = currentBalance*(publicPercentFee/100);
        uint marketingFee = currentBalance*(marketingPercentFee/100);
        uint teamFee = currentBalance*(teamPercentFee/100);
        uint bonusReferralFee = currentBalance*(bonusReferralPercentFee/100);
        uint partnerAdvisorFee = currentBalance*(partnerAdvisorPercentFee/100);
        return(publicFee, marketingFee, teamFee, bonusReferralFee, partnerAdvisorFee);
    }


    function withdraw() public onlyOwner returns(bool){
        (uint publicFee,uint marketingFee, uint teamFee,uint bonusReferralFee,uint partnerAdvisorFee ) = calculatePayment();
        payable(publicAddress).transfer(publicFee);
        payable(marketingAddress).transfer(marketingFee);
        payable(teamAddress).transfer(teamFee);
        payable(bonusReferralAddress).transfer(bonusReferralFee);
        payable(partnerAdvisorAddress).transfer(partnerAdvisorFee);
        return true;
    }

    function setMinimumSaleToken(uint minimumToken) public onlyOwner returns(bool){
        minimumSellToken = minimumToken;
        return true;
    }

    function endSale() public onlyOwner returns(bool){
        uint currentTokenBalance = ERC20.balanceOf(address(this));
        ERC20.transferFrom(address(this), _msgSender(), currentTokenBalance);
        return true;
    }


}