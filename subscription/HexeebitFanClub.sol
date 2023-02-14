// contracts/NFT.sol
// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.2;


import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "hardhat/console.sol";
/**
 * @title Hexxebit
 * @author csurbier
 * @dev 
 */

contract HexeebitFanClub is OwnableUpgradeable {

  using SafeMathUpgradeable for uint256;
   
  
  event NewClub(uint clubId, string name, address creator);
  event ClubUpdated(uint clubId);
 

  using CountersUpgradeable for CountersUpgradeable.Counter;
  CountersUpgradeable.Counter public _clubIds;
  struct Club {
    uint clubId;
    string name;  
    string domain;    
    string description;
    string logo; //Url to logo
    string cover; // Url to cover 
    uint256 createdDate;
    address creator; 
  }

  struct ClubNames{
      string domain;
      bool exists;
  }

  Club[] public clubs;

  mapping (uint => address) public clubToOwner;
  mapping (address => uint) ownerClubCount;
  mapping (string => ClubNames) clubNames;
  
  

  modifier onlyClubOwner(uint _clubId) {
     require(_clubId < _clubIds.current(),"Club id doesn't exists");
     Club memory club = clubs[_clubId];
     //Only owner can modify his club 
     require(msg.sender == club.creator,"Only club creator can modify his club");
     _;
  }
 
  function createClub(string memory _name,string memory _domain,string memory _description,string memory _logo,string memory _cover,uint _createdDate) public {
    
    require(isClubDomainFree(_domain),"Club domain already existing");

    uint id = _clubIds.current();
    clubs.push(Club(id,_name,_domain,_description,_logo,_cover,_createdDate,msg.sender));
    clubNames[_domain]=ClubNames(_domain,true);
    clubToOwner[id] = msg.sender;
    ownerClubCount[msg.sender] = ownerClubCount[msg.sender].add(1);
    emit NewClub(id, _domain, msg.sender);
    _clubIds.increment();
  }

  function isClubDomainFree(string memory _domain) public view returns(bool) {
      if (clubNames[_domain].exists){
          return false;
      }
      else{
          return true;
      }
  }

  function updateClubInfo(uint _clubId,string memory _name,string memory _description,string memory _logo,string memory _cover) public onlyClubOwner(_clubId) {
     Club storage club = clubs[_clubId];
     club.name = _name;
     club.description = _description;
     club.logo = _logo;
     club.cover = _cover;
     emit ClubUpdated(_clubId);
  }

   function fetchMyClubs() external view returns (Club[] memory) {
        uint totalItemCount = _clubIds.current();
        uint itemCount = 0;
        uint currentIndex = 0;

        for (uint i = 0; i < totalItemCount; i++) {
            if (clubs[i].creator == msg.sender) {
                itemCount += 1;
            }
        }

        Club[] memory items = new Club[](itemCount);
        for (uint i = 0; i < totalItemCount; i++) {
            if (clubs[i].creator == msg.sender) {
                uint currentId =  i;
                Club memory currentItem = clubs[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

}
