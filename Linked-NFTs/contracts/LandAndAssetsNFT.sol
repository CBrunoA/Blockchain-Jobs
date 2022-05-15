// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LandAndAssetsNFT is ERC721, Ownable {

    string public baseURI;
    mapping(uint256 => string) public hashesIPFS;   
    string[] assetHashes;              //Here we store the nfts assets IPFS hashes
    string private landHashIPFS;    //Here we store the land IPFS hash.
    uint256 id;

    constructor(string memory _name, string memory _symbol) payable ERC721(_name, _symbol)
    {
        baseURI = "https://ipfs.io/ipfs/";
    }

    //minting to owner address
    function mint() public payable onlyOwner{
        string[] memory _hashes = assetHashes;

        _safeMint(msg.sender, 1);                //We mint the first one
        id = 1;                                 //Once one is minted
        hashesIPFS[id] = landHashIPFS;          //First one will be the Land

        //Mint all the assets
        for(uint256 i=0; i<_hashes.length;i++){     
            id = id+1;
            _safeMint(msg.sender, id);
            hashesIPFS[id] = _hashes[i];
        }
        
    }

    //set the ipfs hashes for land and assets
    function genhashes(string[] memory _hashes) internal pure returns(string[] memory){
        return _hashes;
    }
    function setHashes(string memory _landHash, string[] memory _hashes) public onlyOwner{
        assetHashes = genhashes(_hashes);
        landHashIPFS = _landHash;
    }

    //Check the metadata link for each nft. for example, for nft with id = 1 -> ipfs.io/ipfs/AdnjVdjmdv... Implementation in front-end.
    function tokenURI(uint256 _tokenId) public view virtual override returns(string memory){
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexisten token");
        string memory currentBaseURI = _baseURI();
        require(bytes(currentBaseURI).length >0 && bytes(hashesIPFS[_tokenId]).length > 0, "");
        return string(abi.encodePacked(currentBaseURI, hashesIPFS[_tokenId]));
    }

    //Set the ipfs.io/ipfs/ URI
    function _baseURI() internal view virtual override returns(string memory){
        return baseURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner{
        baseURI = _newBaseURI; 
    }
}

