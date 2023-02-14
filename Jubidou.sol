// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "hardhat/console.sol";
 /**
 * @title Jubidou.com
 * @author csurbier
 * @dev 
 */
contract JubidouNFT is ERC721Royalty,Ownable, ReentrancyGuard  {
    using Strings for uint256;
    using Counters for Counters.Counter;
    Counters.Counter public totalSupply;
    mapping(address => bool) public whitelist;
     string private baseURI;
    string public uriSuffix = ".json";
    string public hiddenMetadataUri;

    uint256 private cost = 10 ether ;
    uint256 public nbInWhiteList = 0 ;
    uint256 private nbMintForTeam =0 ;
    bool public paused = true ;
    bool public revealed = false ;
    uint256 public maxSupply = 5661 ; //5661  
    uint16[5662] public ids; // should equal maxSupply+1 tokens en tout et pour tout
    uint16 private index;

    struct NftItem {
        uint256 tokenId;
        address payable owner;
    }
    mapping(uint256 => NftItem) private babyNFTS;

    event NewSell(address buyer, uint256 tokenId);
 
 
    constructor( string memory _hiddenMetadataUri ) ERC721("Jubidou NFT collection", "JUBIDOUNFT") {
        _setDefaultRoyalty(address(this),500); //5% of royalties (https://www.gemini.com/blog/exploring-the-nft-royalty-standard-eip-2981)
          setHiddenMetadataUri(_hiddenMetadataUri);
    }
    function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
            hiddenMetadataUri = _hiddenMetadataUri;
    }

    modifier mintCompliance(uint256 _mintAmount) {
            require(
                totalSupply.current() + _mintAmount <= maxSupply,
                "Max supply exceeded!"
            );
        _;
    }

    modifier mintPriceCompliance(uint256 _mintAmount) {
        if (whitelist[msg.sender]){
            cost = 5 ether;
        }
        else{
            cost = 10 ether;
        }

        require(msg.value >= (cost * _mintAmount), "Not paid enough !");
        _;
    }

    function addWhitelist(address _newEntry) public {
        require(nbInWhiteList<1000,"Whitelist is now closed");
        require(paused, "The contract is now opened");
      
        whitelist[_newEntry] = true;
        nbInWhiteList+=1;
    }

    function isInWhitelist(address _owner) public view returns (bool) {
        return whitelist[_owner];
    }
 

    function _pickRandomUniqueId(uint256 random) private returns (uint256 id) {
        uint256 len = ids.length - index;
        require(len > 0, "no ids left");
        uint256 randomIndex = random % len;
        id = ids[randomIndex] != 0 ? ids[randomIndex] : randomIndex;
        ids[randomIndex] = uint16(ids[len - 1] == 0 ? len - 1 : ids[len - 1]);
        ids[len - 1] = 0;
    }

    function mintRandom(address _to, uint256 _mintAmount) internal{
   
        for (uint256 i = 0; i < _mintAmount; i++) {
            uint256 _random = uint256(
                keccak256(
                    abi.encodePacked(
                        index++,
                        msg.sender,
                        block.timestamp,
                        blockhash(block.number - 1)
                    )
                )
            );
          
            uint256 tokenId = _pickRandomUniqueId(_random);
            _safeMint(_to, tokenId);
            totalSupply.increment();
           
            babyNFTS[totalSupply.current()] = NftItem(
                tokenId,
                payable(msg.sender)
            );
            emit NewSell(msg.sender, tokenId);
            //Check if bitcoin winner 
            checkWinner(tokenId);
        }
    }

    

    function checkWinner(uint256 _tokenId) internal {
      
        if (_tokenId==195 || _tokenId==537 || _tokenId==698 || _tokenId==779 || _tokenId==1615 || _tokenId==1849 || _tokenId==1923 || _tokenId==2456 || _tokenId==3156 || _tokenId==3266 || _tokenId==3658 || _tokenId==3735 || _tokenId==3744 || _tokenId==4201 || _tokenId==4291 || _tokenId==4703 || _tokenId==4837 || _tokenId==5209){
                mintRandom(_msgSender(), 1);
        }
    }
    function mint(uint256 _mintAmount)
        public
        payable
        mintCompliance(_mintAmount)
        mintPriceCompliance(_mintAmount)
    {
        require(!paused, "The contract is paused!");
        
      
          mintRandom(_msgSender(), _mintAmount);
       
    }
 
    function mintForTeam(uint256 _mintAmount) public onlyOwner   mintCompliance(_mintAmount) {
        require((nbMintForTeam+_mintAmount)<100,"Minted amount for team exceeded");
       mintRandom(_msgSender(), _mintAmount);
       nbMintForTeam+=_mintAmount;
    }
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
   

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

         if (revealed == false) {
            return hiddenMetadataUri;
        }

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        _tokenId.toString(),
                        uriSuffix
                    )
                )
                : "";
    }

    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }
 
    
    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

  

    function fetchTokenForOwner(address owner)
        public
        view
        returns (NftItem[] memory)
    {
        uint256 totalItemCount = totalSupply.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 1; i <= totalItemCount; i++) {
         
            if (babyNFTS[i].owner == owner) {
                itemCount += 1;
            }
        }

        NftItem[] memory items = new NftItem[](itemCount);
        for (uint256 i = 1; i <= totalItemCount; i++) {
            if (babyNFTS[i].owner == owner) {
                uint256 currentId = i;
                NftItem storage currentItem = babyNFTS[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

   

    function withdraw() public onlyOwner nonReentrant {
         (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

     function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
 


    function setBaseURI(string memory _baseUri) public onlyOwner {
        baseURI = _baseUri;
    }
     
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        //call the original function that you wanted.
        super.safeTransferFrom(from, to, tokenId, data);

        //update
        uint256 totalItemCount = totalSupply.current();

        for (uint256 i = 1; i <= totalItemCount; i++) {
            if (babyNFTS[i].tokenId == tokenId) {
                NftItem storage currentItem = babyNFTS[i];
                currentItem.owner = payable(to);

                break;
            }
        }
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //call the original function that you wanted.
        super.safeTransferFrom(from, to, tokenId);

        //update
        uint256 totalItemCount = totalSupply.current();

        for (uint256 i = 1; i <= totalItemCount; i++) {
            if (babyNFTS[i].tokenId == tokenId) {
                NftItem storage currentItem = babyNFTS[i];
                currentItem.owner = payable(to);

                break;
            }
        }
    }

      function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //call the original function that you wanted.
        super.transferFrom(from, to, tokenId);

        //update
        uint256 totalItemCount = totalSupply.current();

        for (uint256 i = 1; i <= totalItemCount; i++) {
            if (babyNFTS[i].tokenId == tokenId) {
                NftItem storage currentItem = babyNFTS[i];
                currentItem.owner = payable(to);

                break;
            }
        }
    }
   
}
