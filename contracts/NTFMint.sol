pragma solidity ^0.8.24;

import "./ERC721.sol";

contract NTFMint is ERC721 {
    uint256 private _tokenId;
    uint public MAX_APES = 10000; // 总量

    constructor(string memory name, string memory symbol) ERC721(name, symbol) {
        _tokenId = 0;
    }

    //铸造bi给to
    function mintNFT(address to) public returns (uint256) {
        require(_tokenId < MAX_APES, "All NFTs have been minted");
        _tokenId++;
        _mint(to, _tokenId);

        return _tokenId;
    }
}
