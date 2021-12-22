//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "hardhat/console.sol";

contract Reseller {

    using SafeMath for uint256;

    address public owner;
    uint256 public numberOfSellers;
    uint256 public numberOfSales;

    mapping(uint256 => Seller) sellers;
    mapping(uint256 => Sale) sales;    

    struct Seller {
        address walletAddress;
        uint256 allowance;
        uint256 totalSale;
        bool status;
    }

    struct Sale {
        address buyerAddress;
        uint256 sellerID;
        uint256 saleAmount;        
    }

    event SellerCreated(
        address indexed _walletAddress
    );

    event SellerNewAllowance(
        uint256 indexed _sellerID,
        uint256 _oldAllowance,
        uint256 _newAllowance
    );  

    event SellerToggled(
        uint256 indexed _sellerID,
        bool status
    );        

    event SaleCreated(
        address indexed _buyerAddress,
        uint256 indexed _sellerID,
        uint256 _saleAmount,
        uint256 _sellerAllowance,
        uint256 _contractBalance
    );    

    event CoinDeposited(
        uint256 _amount
    );

    event CoinWithdrawn(
        uint256 _amount
    );    

    modifier onlyOwner {
      require(msg.sender == owner);
      _;
    }

    constructor() {
        owner = msg.sender;
        numberOfSellers = 0;
        numberOfSales = 0;
        console.log("Owner of the contract: ", owner);
    }

    function registerSeller(address _sellerAddress) public onlyOwner {
        uint256 sellerID = numberOfSellers++;
        Seller storage seller = sellers[sellerID];
        seller.walletAddress = _sellerAddress;
        seller.allowance = 0;
        seller.totalSale = 0;
        seller.status = true;

        console.log("Seller created with address: ", _sellerAddress);
        emit SellerCreated(_sellerAddress);
    }

    function toggleSeller(uint256 _sellerID) public onlyOwner returns (bool newStatus) {
        Seller storage seller = sellers[_sellerID];
        bool oldStatus = seller.status;
        newStatus = !seller.status;
        seller.status = newStatus;

        console.log("Seller with ID '%s', original status: '%s' turned to '%s'.", _sellerID, oldStatus, newStatus);
        emit SellerToggled(_sellerID, newStatus);
    }

    function increaseSellerAllowance(uint256 _sellerID, uint256 _allowanceIncrement) public onlyOwner returns (uint256 newAllowance) {
        Seller storage seller = sellers[_sellerID];
        uint256 oldAllowance = seller.allowance;
        newAllowance = oldAllowance.add(_allowanceIncrement);
        seller.allowance = newAllowance;
        
        console.log("Seller with ID '%s', original allowance: '%s'. Increased allowance: '%s'.", _sellerID, oldAllowance, newAllowance);        
        emit SellerNewAllowance(_sellerID, oldAllowance, newAllowance);
    }

    function createSale(uint256 _sellerID, address payable _buyerAddress, uint256 _saleAmount) public {
        uint256 oldContractBalance = address(this).balance;

        Seller storage seller = sellers[_sellerID];
        address sellerAddress = seller.walletAddress;

        require(msg.sender == sellerAddress, "Seller is not registered.");
        require(_saleAmount < seller.allowance, "Sale amount exceeds allowance");
        require(_saleAmount < oldContractBalance, "Sale amount exceeds contract balance");

        uint256 saleID = numberOfSales++;        
        Sale storage sale = sales[saleID];
        sale.buyerAddress = _buyerAddress;
        sale.sellerID = _sellerID;
        sale.saleAmount = _saleAmount;

        _buyerAddress.transfer(_saleAmount);

        uint256 newContractBalance = address(this).balance;
        uint256 newSellerAllowance = seller.allowance;
        newSellerAllowance.sub(_saleAmount);
        seller.allowance = newSellerAllowance;

        console.log("Sale created to '%s' by Seller ID '%s' for '%s'.", _buyerAddress, _sellerID, _saleAmount);
        emit SaleCreated(_buyerAddress, _sellerID, _saleAmount, newSellerAllowance, newContractBalance);
    }

    function latestContractBalance() public view returns (uint256 latestBalance) {
        latestBalance = address(this).balance;
        console.log("Contract balance is '%s'.", latestBalance);
    }

    function depositIntoContract() public payable onlyOwner {
        console.log("Coin deposited: '%s'.", msg.value);
        emit CoinDeposited(msg.value);
    }

    function withdrawFromContract(uint256 _withdrawalAmount) public onlyOwner {
        address payable ownerAddress = payable(owner);
        ownerAddress.transfer(_withdrawalAmount);
        console.log("Coin withdrawn: '%s'.", _withdrawalAmount);
        emit CoinWithdrawn(_withdrawalAmount);
    }

    function getSeller(uint256 _sellerID) public view returns (
        address walletAddress, 
        uint256 allowance, 
        uint256 totalSale, 
        bool status) {
        Seller storage seller = sellers[_sellerID];
        walletAddress = seller.walletAddress;
        allowance = seller.allowance;
        totalSale = seller.totalSale;
        status = seller.status;        
    }

    function getSale(uint256 _saleID) public view returns (
        address buyerAddress,
        uint256 sellerID,
        uint256 saleAmount) {
        Sale storage sale = sales[_saleID];
        buyerAddress = sale.buyerAddress;
        sellerID = sale.sellerID;
        saleAmount = sale.saleAmount;         
    }    

}
