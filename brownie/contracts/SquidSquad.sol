// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";  
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol"; 
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

contract TheSquidSquad is Ownable, ERC721URIStorage, VRFConsumerBase, KeeperCompatibleInterface, ReentrancyGuard {

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    uint public maxSupply = 888;    // total number of mints in the original series.
    mapping (address => uint) public usersMintCount;    // tracks users mints so they can be enetered automatically into the draw.
    address payable[] public c_drawEnteries;
    bytes32 public c_keyHash;
    uint256 public c_chainlinkFee;
    uint256 public c_ticketFee;
    uint256 public c_lastTimeStamp;
    uint256 public c_interval;
    address public c_theWinner;
    drawState public c_drawState;

    enum drawState {
        OPEN,
        Drawing_Winner, 
        CLOSED
    }

    event squidClaimed(address indexed player);
    event enteredDraw(address indexed player);
    event requestedDrawWinner(bytes32 indexed requestId);
    event winnerChosen(address indexed player);

    constructor(
        address _vrfCoordinator,
        address _linkToken,
        bytes32 _keyHash,
        uint256 _chainlinkFee,
        uint256 _ticketFee
    ) ERC721("The Squid Squad", "SQD") VRFConsumerBase(_vrfCoordinator, _linkToken) {
        c_lastTimeStamp = block.timestamp;
        c_keyHash = _keyHash;
        c_chainlinkFee = _chainlinkFee;
        c_ticketFee = _ticketFee;
        c_theWinner = 0x0000000000000000000000000000000000000000;
        c_drawState = drawState.OPEN;
    }

    function mint(string memory _uri) internal {      
        require (_tokenIds.current() < maxSupply);

        _tokenIds.increment();
        uint256 tknId = _tokenIds.current();

        _mint(msg.sender, tknId);
        _setTokenURI(tknId, _uri);
    }

    function claim(string memory _uri) external payable {
        require(msg.value == 0.08 ether, "claiming a Squid costs 0.08 ETH");
        mint(_uri);
        payable(owner()).transfer(0.08 ether); // funds are sent directly to the contract owner to save tx fees.
        emit squidClaimed(msg.sender);

        require(drawState.OPEN == c_drawState, "draws closed");
        usersMintCount[msg.sender] = usersMintCount[msg.sender] + 1;
        if(usersMintCount[msg.sender] % 3 == 0){
        c_drawEnteries.push(payable(msg.sender));
        emit enteredDraw(msg.sender);
        }
    }

    // gift mint. User pays but receiver is a supplied address.


    // enter draw. If you want a chance to win a nft for a fraction of the cost or simply want to support
    // the project in a fun way this is a great option. purchase limit of one per address.
    // requires ticket fee

    // check upkeep (monitor draw) every 111th mint so 110 will trigger 111, 221 triggers 222, 332 -> 333, etc.
    function checkUpkeep(bytes memory /*checkData*/)
        public
        view
        override
        returns (bool upKeepNeeded, bytes memory performData)
    {
        //bool hasLink = LINK.balanceOf(address(this)) >= c_chainlinkFee;
        bool isOpen = drawState.OPEN == c_drawState;
        uint currentToken = _tokenIds.current();
            upKeepNeeded = ((currentToken == 4 || currentToken == 7 || currentToken == 10 || currentToken == 440 ||
            currentToken == 550 || currentToken == 660 || currentToken == 770 || currentToken == 880)  && isOpen);
            //(block.timestamp - lastTimeStamp) > interval && 
            
        performData = bytes("");
    }

    // perform upkeep 
    function performUpkeep(bytes calldata /*performData*/) external override {
        // require(
        //     LINK.balanceOf(address(this)) >= c_chainlinkFee,
        //     "Not enough Link"
        // );
        //require(address(this).balance >= 0, "Not enough ETH");
        (bool upKeepNeeded, ) = checkUpkeep("");
        require(upKeepNeeded, "No upkeep needed");
        c_drawState = drawState.Drawing_Winner;
        bytes32 requestId = requestRandomness(c_keyHash, c_chainlinkFee);
        emit requestedDrawWinner(requestId);
    }

    // fulfillRandomness.. select/reward winner. 
    function fulfillRandomness(
        bytes32, /*requestId*/
        uint256 randomness
    ) internal override {
        uint256 index = randomness % c_drawEnteries.length-1;
        address payable theWinner = c_drawEnteries[index];
        c_theWinner = theWinner;
        c_drawEnteries = new address payable[](0);
        (bool success, ) = theWinner.call{value: address(this).balance}("");
        require(success, "transfer failed");
        c_drawState = drawState.OPEN;
        emit winnerChosen(theWinner);
    }

    // rental market logic

    function ownerOf(uint256 tokenId) public view virtual override returns(address) {
        require(_exists(tokenId));
        return ownerOf(tokenId);
    }

    function getNFT(uint256 tokenId) external view returns (string memory name) {
        require(_exists(tokenId), "token not minted");
        return tokenURI(tokenId);
    }

    // redundant/failsafe as funds should not be held on conrtract. With the exception of Link or similar utility.
    function withdraw() public onlyOwner nonReentrant {
        uint256 amount = address(this).balance;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Transfer failed");
    }

    // withdraw link
    function withdrawLink() public onlyOwner nonReentrant {
        LinkTokenInterface linkToken = LinkTokenInterface(LINK);
        require(
            linkToken.transfer(msg.sender, linkToken.balanceOf(address(this))),
            "Unable to transfer"
        );
    }
}