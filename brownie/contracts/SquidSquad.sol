// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";  
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol"; 
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract SquidSquad is Ownable, ERC721URIStorage, ReentrancyGuard {

    event squid_claimed(address indexed owner);

    using Counters for Counters.Counter;
    Counters.Counter private x_tokenIds; 
    string private _currentBaseURI;
    uint public maxSupply = 10000;
   
    constructor() ERC721("Squid Squad", "SQD") {
        //setBaseURI("https://OurNodeServer/token/");
    }


    function setBaseURI(string memory baseURI) public onlyOwner {
        _currentBaseURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _currentBaseURI;
    }

    function mint(string memory _uri) internal {      
        require (x_tokenIds.current() < maxSupply);
        x_tokenIds.increment();
        uint256 tknId = x_tokenIds.current();
       // id_to_nft[tknId] = Metadata(name, species); //this should be the meta data we generate on out front end
        _mint(msg.sender, tknId);
        _setTokenURI(tknId, _uri);
    }

    function claim(string memory _uri) external payable {
        require(msg.value == 0.02 ether, "claiming a Squid costs 0.02 ETH");
        mint(_uri);
        payable(owner()).transfer(0.02 ether);
        emit squid_claimed(msg.sender);
    }

    function ownerOf(uint256 tokenId) public view virtual override returns(address) {
        require(_exists(tokenId));
        return ownerOf(tokenId);
    }

    // function getNFT(uint256 tokenId) external view returns (string memory name) {
    //     require(_exists(tokenId), "token not minted");
    //     return id_to_nft[tokenId].name;
    // }

    // Random names will be assinged, a user could change the name for the price of gas.
    // function changeName(uint256 tokenId, string memory name) public {
    //     require(_exists(tokenId), "token not minted");
    //     require(ownerOf(tokenId) == msg.sender, "only the owner of this Squid can change its name");
    //     id_to_nft[tokenId].name = name;
    // }

    function pseudoRNG(string memory name, string memory species) internal view returns (uint256) {
        return uint256(keccak256(abi.encode(block.timestamp, block.difficulty, name, species)));
    }

    function withdraw() public onlyOwner nonReentrant {
        uint256 amount = address(this).balance;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Transfer failed");
    }
}