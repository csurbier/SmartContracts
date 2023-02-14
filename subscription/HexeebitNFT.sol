// contracts/NFT.sol
// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

/**
    Owner du contrat peut créer un token et fixer son prix
    Autre peut miner un NFT 
 */

contract HexeebitNFT is ERC721URIStorage , Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _createdTokenIds ;
    uint256 public cost = 6 ether;
    bool locked = false;
    string private baseURI;
    string public baseExtension = ".json";
    mapping (uint256 => uint256) public tokenPrices;
    
    struct NftItem {
        uint256 tokenId;
        address payable owner;
        uint256 price;
        bool sold;
    }

    mapping(uint256 => NftItem) private existingMemberClubNft;
    event NewSell(address buyer, uint256 tokenId);
    event NewTokenCreated(address creator, uint256 tokenId);   
    constructor() ERC721 ("Hexeebit Membership NFT", "HexeebitNFT") {

    }

    function setNewMinimumCost(uint256 _minimumCost) public onlyOwner  {
         uint256 minimum = _minimumCost * 10 ** uint256(18);  
         cost = minimum;
    }

      function setTokenPrice(uint256 _tokenId,uint256 _price) public onlyOwner {
          tokenPrices[_tokenId] = _price;
    }

     function getTokenPrice(uint256 _tokenId) public view returns(uint256) {
         if (tokenPrices[_tokenId] >0){
             return  tokenPrices[_tokenId];
         }
         else{
             return 0;
         }
    }
 
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
 
    

    function setBaseURI(string memory _baseUri) public onlyOwner {
        baseURI = _baseUri;
    }
    function append(string memory a, string memory b, string memory c, string memory d, string memory e) internal pure returns ( string memory) {

    return string(abi.encodePacked(a, b, c, d, e));

}
    function createToken(uint256 tokenId) public onlyOwner returns (uint) {
        require(_exists(tokenId)==false,"Token already mint");
     
        _mint(msg.sender, tokenId);
         string memory url = append(Strings.toString(tokenId),baseExtension,"","","");
        _setTokenURI(tokenId, url);
       
       
        _createdTokenIds.increment();
        
        uint256 newItemId = _createdTokenIds.current();
        
        existingMemberClubNft[newItemId] = NftItem(
            tokenId,
            payable(owner()),
            cost,
            false
        );
        emit NewTokenCreated(msg.sender,tokenId);
       return newItemId;
    }

     function mintNFT(uint256 tokenId) public payable returns (uint){
       
        require(_exists(tokenId)==false,"Token already mint");

        uint256 paidPrice = 0 ;
        
        if (msg.sender != owner()) {
       
            paidPrice = cost;
            require(msg.value >= cost,"Need to pay minimum price");
            if (tokenPrices[tokenId] >0){
                require(msg.value >= tokenPrices[tokenId],"Not enought paid");
                paidPrice = tokenPrices[tokenId];
            }
        }
      
        _mint(msg.sender, tokenId);
        string memory url = append(Strings.toString(tokenId),baseExtension,"","","");
        _setTokenURI(tokenId, url);
      
         _createdTokenIds.increment();
        
        uint256 newItemId = _createdTokenIds.current();
        
        existingMemberClubNft[newItemId] = NftItem(
            tokenId,
            payable(msg.sender),
            msg.value,
            true
        );
        emit NewSell(msg.sender,tokenId);
        return newItemId;
    }

      function fetchTokenForOwner(address owner) public view returns (NftItem[] memory) {
          uint totalItemCount = _createdTokenIds.current();
        uint itemCount = 0;
        uint currentIndex = 0;

        for (uint i = 1; i <= totalItemCount; i++) {
            if (existingMemberClubNft[i].owner == owner) {
                itemCount += 1;
            }
        }
        
        NftItem[] memory items = new NftItem[](itemCount);
        for (uint i = 1; i <= totalItemCount; i++) {
        if (existingMemberClubNft[i].owner==owner) {
            uint currentId =  i;
            NftItem storage currentItem = existingMemberClubNft[currentId];
            items[currentIndex] = currentItem;
            currentIndex += 1;
        }
        }
        return items;
    }
    function fetchSoldItems() public view returns (NftItem[] memory) {
         uint itemCount = 0;
        uint currentIndex = 0;
           uint totalItemCount = _createdTokenIds.current();
     
        for (uint i = 1; i <= totalItemCount; i++) {
            if (existingMemberClubNft[i].sold ==true) {
                itemCount += 1;
            }
        }
        NftItem[] memory items = new NftItem[](itemCount);
        for (uint i = 1; i <= totalItemCount; i++) {
            if (existingMemberClubNft[i].sold == true) {
                uint currentId =  i;
               
                NftItem storage currentItem = existingMemberClubNft[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

   

    /* Returns onlyl items that a user has purchased */
    function fetchMyNFTs() public view returns (NftItem[] memory) {
        uint totalItemCount = _createdTokenIds.current();
        uint itemCount = 0;
        uint currentIndex = 0;

        for (uint i = 1; i <= totalItemCount; i++) {
            if (existingMemberClubNft[i].owner == msg.sender && existingMemberClubNft[i].sold==true) {
                itemCount += 1;
            }
        }

        NftItem[] memory items = new NftItem[](itemCount);
        for (uint i = 1; i <= totalItemCount; i++) {
        if (existingMemberClubNft[i].owner == msg.sender && existingMemberClubNft[i].sold==true) {
            uint currentId =  i;
            NftItem storage currentItem = existingMemberClubNft[currentId];
            items[currentIndex] = currentItem;
            currentIndex += 1;
        }
        }
        return items;
    }
 
    function getBalance() public view returns (uint256){
        return address(this).balance;
   }

    function withdraw(uint256 amount) public onlyOwner{
        // Just transfer the balance to the foundes
        uint256 minimumWidthdraw = amount * 10 ** uint256(18);  
        require(!locked, "Reentrant call detected!");
        require (address(this).balance>= minimumWidthdraw);
        locked = true;
        //admin.transfer(amount);
        // (bool hs, ) = payable(founders).call{value: minimumWidthdraw * 5 / 100}("");
        // require(hs);
        (bool os, ) = payable(owner()).call{value: minimumWidthdraw}("");
        require(os);
        locked = false;
    } 

    function burn(uint256 tokenId) public{
         require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);
    }


}