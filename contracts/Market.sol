// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "hardhat/console.sol";

contract Market is
    ERC721,
    ERC721Enumerable,
    ERC721URIStorage,
    AccessControl,
    ReentrancyGuard
{
    using Counters for Counters.Counter;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    Counters.Counter private _tokenIdCounter;

    uint256 listingFee = 0.00025 ether;

    struct Entity {
        address payable owner;
        uint256 price;
        bool sale;
    }

    mapping(uint256 => Entity) public tokenIdToEntity;

    modifier onlyOwner(uint256 _tokenId) {
        require(msg.sender == ownerOf(_tokenId));
        _;
    }

    constructor() ERC721("Market", "MRKT") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://nft.xyz/ipfs/";
    }

    function safeMint(string memory uri, uint256 _price)
        public
        onlyRole(MINTER_ROLE)
    {
        uint256 _tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        _safeMint(msg.sender, _tokenId);
        _setTokenURI(_tokenId, uri);
        list(_price, _tokenId);

        approve(address(this), _tokenId);
    }

    function list(uint256 _price, uint256 _tokenId) public onlyOwner(_tokenId) {
        Entity memory entity = tokenIdToEntity[_tokenId];

        entity = Entity({
            price: _price,
            owner: payable(msg.sender),
            sale: true
        });

        tokenIdToEntity[_tokenId] = entity;

        approve(address(this), _tokenId);
    }

    function buy(uint256 _tokenId) public payable nonReentrant {
        Entity memory entity = tokenIdToEntity[_tokenId];

        require(msg.value == entity.price, "Must send price of entity");

        IERC721(address(this)).safeTransferFrom(
            entity.owner,
            msg.sender,
            _tokenId
        );

        entity = Entity({
            price: entity.price,
            owner: payable(msg.sender),
            sale: false
        });

        tokenIdToEntity[_tokenId] = entity;
    }

    function entitiesAll() public view returns (Entity[] memory) {
        Entity[] memory entities = new Entity[](_tokenIdCounter.current());

        for (uint256 i = 0; i < _tokenIdCounter.current(); i++) {
            entities[i].owner = tokenIdToEntity[i].owner;
            entities[i].price = tokenIdToEntity[i].price;
            entities[i].sale = tokenIdToEntity[i].sale;
        }

        return entities;
    }

    function entitiesForSale() public view returns (Entity[] memory) {
        Entity[] memory entities = new Entity[](_tokenIdCounter.current());

        for (uint256 i = 0; i < _tokenIdCounter.current(); i++) {
            entities[i].owner = tokenIdToEntity[i].owner;
            entities[i].price = tokenIdToEntity[i].price;
            entities[i].sale = tokenIdToEntity[i].sale;
        }

        return entities;
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
