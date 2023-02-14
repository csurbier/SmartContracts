// contracts/NFT.sol
// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.2;

import "./HexeebitFanClub.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/**
 * @title HexeebitFanContract
 * @author csurbier
 * @dev this contract is based on ERC721   and Owned by msg.sender (at deployment)
 */
contract HexeebitFanContract is HexeebitFanClub {
    using SafeMathUpgradeable for uint256;
    using CountersUpgradeable for CountersUpgradeable.Counter;

    event NewSubscription(
        uint256 clubId,
        uint256 subscriptionId,
        uint256 subType
    );
    event UpdateSubscriptionPrice(
        uint256 clubId,
        uint256 subscriptionId,
        uint256 price,
        string logo,
        string color,
        string textColor,
        string borderColor
    );

    struct Subscription {
        uint256 clubId;
        uint256 subId;
        uint256 price; // can be 0
        uint256 typeSub; // 0 : Daily, 1: Montlhy, 2: 6 month, 3 : yearly
        string logo; //Url to logo
        string color;
        string textColor;
        string borderColor;
        bool exist;
        address creator;
    }

    mapping(uint256 => Subscription) public subscriptions; // all subscribtions created

    CountersUpgradeable.Counter public subscriptionCounter;
    uint256 storedValue;
    string djangoDynamicUrl ; 

    modifier clubExist(uint256 _clubId) {
        require(_clubId < _clubIds.current(), "Club id doesn't exists");
        _;
    }

    //Modified to check if memberShip subscription exist
    modifier subscriptionExist(uint256 _subscriptionId) {
        require(
            subscriptions[_subscriptionId].exist,
            "sub does not exist."
        );
        _;
    }

    
    // Modifier to check that the caller is not the owner of event
    modifier isNotClubOwner(uint256 _clubId) {
        Club memory _club = clubs[_clubId];
        require(msg.sender != _club.creator, "Caller is club owner.");
        _;
    }

    //Modified to check if memberShip subscription is free
    modifier subscriptionisFree(uint256 _subscriptionId) {
        require(
            subscriptions[_subscriptionId].exist,
            "sub does not exist."
        );
        require(
            subscriptions[_subscriptionId].price == 0,
            "sub not free"
        );
        _;
    }

    function isClubExisting(uint256 _clubId) external  view returns (bool) {
            if (_clubId < _clubIds.current()){
                return true;
            } 
            else{
                return false;
            }
    }
     function isSubExist(uint256 _subId) external  view returns (bool) {
       return  subscriptions[_subId].exist;
    }

    function getSubCounter() external  view returns (uint256) {
        return  subscriptionCounter.current();
    }

      function getSubClubId(uint256 subId) external  view returns (uint256) {
        return  subscriptions[subId].clubId;
    }

    function getSubSubId(uint256 subId) external  view returns (uint256) {
        return  subscriptions[subId].subId;
    }
    function getSubPrice(uint256 subId) external  view returns (uint256) {
         // il faut diviser par 100 la valeur du prix souscription
       
        return  subscriptions[subId].price / 100;
    }

      function getClubCreator(uint256 clubId) external  view returns (address) {
        return  clubs[clubId].creator;
    }

    function getClubName(uint256 clubId) external  view returns (string memory) {
        return  clubs[clubId].name;
    }

    function append(string memory a, string memory b, string memory c, string memory d, string memory e) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b, c, d, e));
    }
function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
    function getSubLogo(uint256 subId) external  view returns (string memory) {
        // renvoyer url vers Django pointant sur image de la souscription
        return append(djangoDynamicUrl,uint2str(subId),"","","");
    }

     function setDjangoDynamicUrl(string memory _djangoUrl) external onlyOwner {
        djangoDynamicUrl = _djangoUrl;
    }

   function setStoreValue(uint256 newValue) external {
        storedValue = newValue;
    }
    function getStoreValue() external view returns (uint256){
        return storedValue;
    }
    // Create new membership subscription
    function createSubscription(
        uint256 _clubId,
        uint256 _typeSub,
        uint256 _price,
        string memory _logo,
        string memory _color,
        string memory _textColor,
        string memory _borderColor
    ) external onlyClubOwner(_clubId) {
        uint256 currentMemberShipId = subscriptionCounter.current();
        bool found = false;
        uint256 totalItemCount = subscriptionCounter.current();

        for (uint256 i = 0; i < totalItemCount; i++) {
            if (subscriptions[i].clubId == _clubId) {
                if (subscriptions[i].typeSub == _typeSub) {
                    found = true;
                    break;
                }
            }
        }
        require(!found, "already exists");
        Subscription memory _subscription;
        _subscription.clubId = _clubId;
        _subscription.subId = currentMemberShipId;
        _subscription.typeSub = _typeSub;
        _subscription.price = _price;
        _subscription.logo = _logo;
        _subscription.color = _color;
        _subscription.textColor = _textColor;
        _subscription.borderColor = _borderColor;
        _subscription.exist = true;
        _subscription.creator = msg.sender;
        subscriptions[currentMemberShipId] = _subscription;
        subscriptionCounter.increment();
        emit NewSubscription(_clubId, currentMemberShipId, _typeSub);
    }

    function updateSubscription(
        uint256 _clubId,
        uint256 _subscriptionId,
        uint256 _price,
        string memory _logo,
        string memory _color,
        string memory _textColor,
        string memory _borderColor
    ) external subscriptionExist(_subscriptionId) onlyClubOwner(_clubId) {
        
        bool found = false;
        uint256 totalItemCount = subscriptionCounter.current();

        for (uint256 i = 0; i < totalItemCount; i++) {
            if (subscriptions[i].clubId == _clubId) {
                if (subscriptions[i].subId == _subscriptionId) {
                    found = true;
                    break;
                }
            }
        }
        require(found,"subscription/club does not exist.");
        Subscription storage subscription = subscriptions[_subscriptionId];
        subscription.price = _price;
        subscription.logo = _logo;
        subscription.color = _color;
        subscription.textColor = _textColor;
        subscription.borderColor = _borderColor;
        emit UpdateSubscriptionPrice(
            _clubId,
            _subscriptionId,
            _price,
            _logo,
            _color,
            _textColor,
            _borderColor
        );
    }

    function fetchMyClubSubscriptions(uint256 _clubId)
        external
        view
        returns (Subscription[] memory)
    {
        Club memory club = clubs[_clubId];
        //Only club owner can fetch his subscriptions
        require(
            msg.sender == club.creator,
            "Only club creator"
        );
        uint256 totalItemCount = subscriptionCounter.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalItemCount; i++) {
            if (subscriptions[i].clubId == _clubId) {
                itemCount += 1;
            }
        }

        Subscription[] memory items = new Subscription[](itemCount);
        for (uint256 i = 0; i < totalItemCount; i++) {
            if (subscriptions[i].clubId == _clubId) {
                uint256 currentId = i;
                Subscription memory currentItem = subscriptions[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

 
}
