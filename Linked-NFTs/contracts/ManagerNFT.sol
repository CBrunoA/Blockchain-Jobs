// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./LandAndAssetsNFT.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract ManagerNFT is LandAndAssetsNFT {

    //IMPORTANT: Prices should be set manualy in the frontend, or here, this are random prices I wrote.
    //IMPORTANT: Haven't added events apart from the standards of ERC721, add the events you consider.
    uint256 amountLandPrice = 1 ether;     //This prices are a reference, you can set them, or just set 1 price and multiply it, or whatever you want. 
    uint256 amountAssetPrice = 2 ether;
    uint256 amountAllPrice = 3 ether;
    uint256 amountAllAssetsPrice = 4 ether;     //As an idea , could be amountAllAssetsPrice = amountAssetPrice * id - discount 
    address private _owner;

    constructor(string memory _name, string memory _symbol) LandAndAssetsNFT(_name, _symbol){
        _owner = payable(msg.sender);
    }

    function buyAll() public payable checkAllAssetsAreAvaiable(id){
        require(ownerOf(1) == _owner, "Land was already bought");
        require(msg.value == amountAllPrice, "Not enough funds to buy all");
        for(uint i = 1; i<id; i++){
            _transfer(_owner, msg.sender, i);
        }
    }

    function buyAllAssets() public payable checkAllAssetsAreAvaiable(id){
        require(msg.value == amountAllAssetsPrice, "Not enough funds to buy all assets");
        for(uint i = 2; i<id; i++){
            _transfer(_owner, msg.sender, i);
        }
    }


    function buyLandOrMix(bool _buyLand, uint[] memory _assetID) public payable {     //If _assetID is empty [], only buys the land.
        if(_buyLand == true){
            require(ownerOf(1) == _owner, "Land was already bought");
            require(msg.value == amountLandPrice, "Not enough funds to buy the land");     //Verify they have paid.
            _transfer(_owner, msg.sender, 1);
        }
        
        require(_assetID.length > 0);       //Only executes if we added any asset id
        require(msg.value == amountAssetPrice*_assetID.length, "Not enough funds to buy this asset/s");     //Check payment
        for(uint i = 0; i <= _assetID.length; i++){              
            for(uint j = 2; j < id ; j++){           
                if(j == _assetID[i+1]){                       
                    _transfer(_owner, msg.sender, j); 
                    break;  
                }
            }
        }
    }


    //Check if all assets are still un-bought.
    modifier checkAllAssetsAreAvaiable(uint _assetID){
        for(uint i = 2; i < _assetID; i++){
            require(ownerOf(i) == _owner, "Some assets are not avaiable");
            _;
        }
    }

    //Check if the assets to buy are un-bought
    modifier checkAssetsAreAvaiable(uint[] memory _assetID){
        for(uint i = 0; i < _assetID.length; i++){
            require(ownerOf(_assetID[i]) == _owner, "Some assets are not avaiable");
            _;
        }
    }

    //Buyers have paid to the contract, not your wallet, so for you to be able to get the money, you can execute this function
    function FundsFromContractToOwner() public onlyOwner returns(bool){
        (bool success,) = _owner.call{value: address(this).balance}("");              //With this we get the money from the contract address to the owners wallet (you).
        require(success, "The payment failed");                                       //To continue, the transaction must have succeded.
        return true;
    }
}