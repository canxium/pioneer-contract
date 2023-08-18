// contracts/DecentralisedNFT.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ThePioneers is ERC721, ERC721URIStorage, Ownable {
    mapping(uint256 => bool) private _burned;

    // Base URI required to interact with IPFS
    string private _baseURIExtended;
    // will be manual increased every month
    uint256 private _tier1Refund = 1000 ether;
    uint256 private _tier2Refund = 500 ether;
    uint256 private _tier3Refund = 10 ether;

    constructor() ERC721("ThePioneers", "") {
        _setBaseURI("ipfs://");
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // Sets the base URI for the collection
    function _setBaseURI(string memory baseURI) private {
        _baseURIExtended = baseURI;
    }

    // Overrides the default function to enable ERC721URIStorage to get the updated baseURI
    function _baseURI() internal view override returns (string memory) {
        return _baseURIExtended;
    }

    // No transfer allowed
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        pure
        override(ERC721)
    {
        require(from == address(0) || to == address(0), "Token not transferable");
    }


    // burn and refund cau
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        require(ownerOf(tokenId) == msg.sender, "Only the owner of the token can burn it");
        require(_burned[tokenId] == false, "Token id already burned");
        
        uint256 refund = 0;
        if (tokenId == 0) {
            refund = _tier1Refund;
        } else if (tokenId > 0 && tokenId <= 34) {
            refund = _tier2Refund;
        } else if (tokenId <= 1034) {
            refund = _tier3Refund;
        }
        
        require(address(this).balance >= refund, "Contract out of balance");

        super._burn(tokenId);
        address payable to = payable(msg.sender);
        to.transfer(refund);
        _burned[tokenId] = true;
    }

    ///////// ONWER ONLY /////////

    // prevent renounce
    function renounceOwnership() public override(Ownable) onlyOwner() {
        // do nothing
    }
    
    // Allows minting of a new NFT 
    function mint(address collector, uint256 tokenId, string memory metadataURI) external onlyOwner() {
        require(tokenId <= 1034, "Reach Maximum Pioneers");
        require(_burned[tokenId] == false, "Token id already burned");

        _safeMint(collector, tokenId);
        _setTokenURI(tokenId, metadataURI);
    }

    // Allows contract owner burn un-minted NFT, won't be create again
    function incinerate(uint256 tokenId) external onlyOwner() {
        require(ownerOf(tokenId) == address(0), "Token already mined");
        require(_burned[tokenId] == false, "Token already burned");
        _burned[tokenId] = true;
    }

    // Increase burn reward
    function increaseT1Reward(uint256 reward) external onlyOwner() {
        _tier1Refund = _tier1Refund + reward;
    }

    function increaseT2Reward(uint256 reward) external onlyOwner() {
        _tier2Refund = _tier2Refund + reward;
    }

    function increaseT3Reward(uint256 reward) external onlyOwner() {
        _tier3Refund = _tier3Refund + reward;
    }

    ///////// Public /////////

    // Allows owner burn un-minted NFT, won't be create again
    function isBurned(uint256 tokenId) external view returns (bool) {
        return _burned[tokenId];
    }

    // allow token owner burn the nft
    function burn(uint256 tokenId) external {
        _burn(tokenId);
    }

    // return number of CAU recieve back if burn the token
    function burnReward(uint256 tokenId) external view returns (uint256) {
        uint256 refund = 0;
        if (tokenId == 0) {
            refund = _tier1Refund;
        } else if (tokenId > 0 && tokenId <= 34) {
            refund = _tier2Refund;
        } else if (tokenId <= 1034) {
            refund = _tier3Refund;
        }

        return refund;
    }

    // get the token uri
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }
}