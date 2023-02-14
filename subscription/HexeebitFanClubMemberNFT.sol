// contracts/NFT.sol
// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.2;
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "./HexeebitFanContract.sol";
import "./Base64.sol";  
/**
 * @title ExhibFanClubMemberNFT
 * @author csurbier
 * @dev this contract is based on ERC721   and Owned by msg.sender (at deployment)
 */
contract HexeebitFanClubMemberNFT is ERC721URIStorageUpgradeable,OwnableUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _tokenIds;
    using SafeMathUpgradeable for uint256;

    bool locked ;
    address hexeebitFounder ;
    HexeebitFanContract contractHeexhibit;

    struct Card {
        uint256 clubId;
        uint256 subId;
        uint256 crDte;
        uint256 expDte;
        uint256 paid;
        string urlLogo;
        address owner; 
        bool valid;
    }
    mapping(uint256 => Card) public members;
   
    event NewCard(address owner, uint256 memberShipCardId,uint256 clubId,uint256 subId);
    event CardBurned(uint tokenId);
 
     
    function initialize(address _hexeebitFounder,address _contractAddress) external initializer {
         hexeebitFounder = _hexeebitFounder;
         contractHeexhibit = HexeebitFanContract(_contractAddress);
         locked=false;
        __Ownable_init();
         __ERC721_init("Hexeebit", "HEXEEBITCLUB");
         
    }
 
     
    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        // require token id exists
        require(_exists(tokenId),"Token not exists");
         Card memory currentItem = members[tokenId];
        string memory clubName = contractHeexhibit.getClubName(currentItem.clubId);
        string memory subLogo = contractHeexhibit.getSubLogo(currentItem.subId);
        string memory json = Base64.encode(
            bytes(string(
                abi.encodePacked(
                    '{"name": "Member ',tokenId,' of ', clubName, '",',
                    '"image_data": "', subLogo, '",',
                    '"attributes": []}'
                )
            ))
        );
        return string(abi.encodePacked('data:application/json;base64,', json));
    }    
     function createNewCard(
            uint256 _clubId,
            uint256 _subscriptionId,
            uint256 _createdDate,
            uint256 _expireDate
    ) external payable returns(uint256) {

        require(contractHeexhibit.isClubExisting(_clubId),"Club id doesn't exists");
        require(contractHeexhibit.isSubExist(_subscriptionId),"sub does not exist.");
        bool found = false;
        uint256 totalItemCount = contractHeexhibit.getSubCounter();

        for (uint256 i = 0; i < totalItemCount; i++) {
            if (contractHeexhibit.getSubClubId(i) == _clubId) {
                if (contractHeexhibit.getSubSubId(i) == _subscriptionId) {
                    found = true;
                    break;
                }
            }
        }
        require(found,"Member sub for that club does not exist.");
        
        require(msg.value == contractHeexhibit.getSubPrice(_subscriptionId),"Not paid enought");
            uint256 id = _tokenIds.current();
            Card memory _card;
            _card.clubId = _clubId;
            _card.subId = _subscriptionId;
            _card.crDte = _createdDate;
            _card.expDte = _expireDate;
            _card.paid = msg.value;
            _card.owner = msg.sender;
            _card.valid = true;
            members[id] = _card;
            _mint(msg.sender, id);
           
            uint256 fees = msg.value * 10 / 100;
            uint256 amountCreator = msg.value - fees;
            (bool hs, ) = payable(hexeebitFounder).call{value: fees}("");
            require(hs);
            (bool os, ) = payable(contractHeexhibit.getClubCreator(_clubId)).call{value: amountCreator}("");
            require(os);
             
             emit NewCard(msg.sender, id,_clubId,_subscriptionId);
            _tokenIds.increment(); 
            return id;       
    }

     
    
    /* Returns onlyl items that a user has purchased */
    function fetchMyCards() external view returns (Card[] memory) {
        uint totalItemCount = _tokenIds.current();
        uint itemCount = 0;
        uint currentIndex = 0;

        for (uint i = 0; i < totalItemCount; i++) {
            if (members[i].owner == msg.sender && members[i].valid==true) {
                itemCount += 1;
            }
        }

        Card[] memory items = new Card[](itemCount);
        for (uint i = 0; i < totalItemCount; i++) {
            if (members[i].owner == msg.sender && members[i].valid==true) {
                uint currentId =  i;
                Card memory currentItem = members[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    function getClubMembers(uint256 _clubId)  public  view  returns (Card[] memory) {
          require(msg.sender == contractHeexhibit.getClubCreator(_clubId),"Only club creator");
        uint totalItemCount = _tokenIds.current();
        uint itemCount = 0;
        uint currentIndex = 0;

        for (uint i = 0; i < totalItemCount; i++) {
            if (members[i].clubId == _clubId && members[i].valid) {
                itemCount += 1;
            }
        }

        Card[] memory items = new Card[](itemCount);
        for (uint i = 0; i < totalItemCount; i++) {
              if (members[i].clubId == _clubId && members[i].valid) {
                uint currentId =  i;
                Card memory currentItem = members[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }
    
 
 
  function getBalance() external view returns (uint256){
        return address(this).balance;
   }

    

    function burn(uint256 tokenId) external onlyOwner{
        _burn(tokenId);
        Card storage member = members[tokenId];
        member.valid=false;
        emit CardBurned(tokenId); 
    }
}