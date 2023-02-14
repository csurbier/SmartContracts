// contracts/NFT.sol
// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

contract ExhibFanMemberNFT is ERC721URIStorage , Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds ;
    address contractAddress;

    constructor()  ERC721 ("ExhibFans membership NFT", "EXHIBNFT") {
    }

    function createToken(string memory tokenURI) public onlyOwner returns (uint) {
        
         _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _mint(msg.sender, newItemId);
        _setTokenURI(newItemId, tokenURI);
     
       return newItemId;
    }

    
}