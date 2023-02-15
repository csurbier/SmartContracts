//SPDX-License-Identifier: MIT

/**
 * @file QueezTokenSale.sol
 * @author Christophe Surbier <csurbier@idevotion.fr>
 * @date created October. 2021
 */

 
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./QueezmeToken.sol"; 
import "hardhat/console.sol";

contract QueezmeSale   {
    address payable public admin;
    address payable founderOne;
    address payable founderTwo;
    
    QueezmeToken tokenContract;
    uint256 public tokensSold;
    uint256 public tokenToSoldNumber;
    address tokenAddress;
    int256 divider = 4; 

    mapping(address => uint256) public buyers;
    event Sell(address _buyer, uint256 _amount);
    modifier onlyAdmin() {
		require(msg.sender == admin);
		_;
	}

    // refactoring pour passer le contrat du QueezToken 

    constructor (address _tokenAddress,uint256 _numberOfTokens,address  _founderOne, address  _founderTwo)  {
        admin = payable(msg.sender);
        // Create token to sell
        tokenContract = QueezmeToken(_tokenAddress);
        tokenAddress = _tokenAddress;       
        tokenToSoldNumber = _numberOfTokens;
        founderOne = payable(_founderOne);
        founderTwo = payable(_founderTwo);
        console.log("admin address ",admin);
      
    }
 

    function multiply(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    function setDivider(int256 _newDivider) public onlyAdmin{
        divider = _newDivider; 
    }  

    function buyTokens(uint256 _numberOfTokens) public payable {
        //Calculate token price 
        
        int256 maticPrice = 1 ether ;   
   
        uint256 tokenPrice = uint256(maticPrice/divider) ;  
 
        uint256 amountTobuy = multiply(_numberOfTokens, tokenPrice);
        console.log("Value ",msg.value);
        console.log("et doit paer ",amountTobuy);
        require(msg.value == amountTobuy,"No paid enough");
        //uint256 toTransfert = _numberOfTokens * 10 ** uint256(18);
        uint256 initialSupply = _numberOfTokens * 10 ** uint256(18);  // 10000000 * 10 ** uint256(18); 
       
        require(tokenContract.balanceOf(address(this)) >= initialSupply,"No enought token to sold");
        require(tokenContract.transfer(msg.sender, initialSupply),"Error while transfering tokens");

        tokensSold += _numberOfTokens;
        tokenToSoldNumber -= _numberOfTokens;
        uint256 _existingContribution = buyers[msg.sender];
		uint256 _newContribution = SafeMath.add(_existingContribution,msg.value);
		buyers[msg.sender] = _newContribution;
        emit Sell(msg.sender, _numberOfTokens);
    }

   function getTokenBalance() public view returns (uint256){
       return tokenContract.balanceOf(address(this));
   }

   function getBalance() public view returns (uint256){
    //    console.log("Address %s",address(this));
    //    console.log("Balance %d",address(this).balance);
        return address(this).balance;
   }

    function setFounderOne(address payable _founder) public onlyAdmin{
        founderOne = _founder;
    }

     function setFounderTwo(address payable _founder) public onlyAdmin {
        founderTwo = _founder;
    }

    function withdraw(uint256 amount) public onlyAdmin{
        // Just transfer the balance to the foundes
        require (address(this).balance>= amount);
        uint256 splitAmount = amount / 2;
        
        founderOne.transfer(splitAmount);
        founderTwo.transfer(splitAmount);
        
    }
}
