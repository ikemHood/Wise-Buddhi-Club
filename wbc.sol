// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";

contract WiseBuddhiClub is
    ERC1155,
    Ownable,
    ERC1155Supply,
    ReentrancyGuard
{
    using Strings for uint256;

    string private _name;
    string private _symbol;
    uint256 private _totalSupply;
    
    uint256 private constant WBC_OG = 10001;
    uint256 private constant WBC_WL = 10002;

    string private uriSuffix = ".json";
    string private uriPrefix;
    string private hiddenMetadataUri;

    uint256 public OGPrice = 0.001 ether;
    uint256 public WLPrice = 0.001 ether;
    uint256 public publicPrice = 0.001 ether;

    uint256 public maxSupply = 10000;

    uint256 private OGSupply = 1000;
    uint256 private WLSupply = 5000;

    uint256 private totalOGMinted;
    uint256 private totalWLMinted;

    uint256 public maxMintAmountPerTx = 3;
    uint256 public maxMintAmountPerAddress = 10;
    mapping(address => uint256) private mintedAmount;

    bool public revealed = false;
    bool public pause = false;
    uint8 private round; // 1 ~ OG mint, 2 ~ WL mint, 3 ~ public mint

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        string memory _hiddenMetadataUri
    ) ERC1155("") {
        _name = _tokenName;
        _symbol = _tokenSymbol;
        setHiddenMetadataUri(_hiddenMetadataUri);

        _mint(msg.sender, WBC_OG, OGSupply, "");
        _mint(msg.sender, WBC_WL, WLSupply, "");
    }

    /** Modifiers **/
    modifier mintCompliance(uint256 _mintAmount) {
        require(!pause, "Contract Is Paused");
        require( _mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, "Invalid mint amount!" );
        require( mintedAmount[msg.sender] + _mintAmount <= maxMintAmountPerAddress, "Exceeds max mint amount" );
        require( totalSupply() + _mintAmount <= maxSupply, "Max supply exceeded!" );
        _;
    }

    modifier publicCompliance(uint256 _mintAmount) {
        require(round == 3, "Public mint has not started");
        require(msg.value >= publicPrice * _mintAmount, "Insufficient funds!");
        _;
    }

    modifier OGCompliance(uint256 _mintAmount) {
        require( totalOGMinted + _mintAmount <= OGSupply, "OG supply exceeded!" );
        require(round == 1, "The OG Mint has not started!");
        require(msg.value >= OGPrice * _mintAmount, "Insufficient funds!");
        _;
    }

    modifier WLCompliance(uint256 _mintAmount) {
        require( totalWLMinted + _mintAmount <= WLSupply, "WL supply exceeded!" );
        require(round == 2, "The WL Mint has not started!");
        require(msg.value >= WLPrice * _mintAmount, "Insufficient funds!");
        _;
    }

    /** Public Functions**/
    function whitelistMint(uint256 _mintAmount)
        public
        payable
        mintCompliance(_mintAmount)
        WLCompliance(_mintAmount)
    {
        mintedAmount[_msgSender()] += _mintAmount;
        totalWLMinted += _mintAmount;

        _mintNFT(msg.sender, _mintAmount);
    }

    function OGMint(uint256 _mintAmount)
        public
        payable
        mintCompliance(_mintAmount)
        OGCompliance(_mintAmount)
    {
        mintedAmount[_msgSender()] += _mintAmount;
        totalOGMinted += _mintAmount;

        _mintNFT(msg.sender, _mintAmount);
    }

    
    function mint(uint256 _mintAmount)
        public
        payable
        mintCompliance(_mintAmount)
        publicCompliance(_mintAmount)
    {
        mintedAmount[_msgSender()] += _mintAmount;

        _mintNFT(msg.sender, _mintAmount);
    }

    function transferFrom(address from, address to, uint256 id) public {
        super.safeTransferFrom(from, to, id, 1, "");
    }

    /** Public View Functions **/
    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    function getRoundStatus() public view returns (uint8) {
        return round;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        returns (string memory)
    {

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

    function isUserOG(address user) public view returns (bool) {
        uint256 balance = getOGBalance(user);

        if (balance > 0) {
            return true;
        }
        return false;
    }

    function isUserWL(address user) public view returns (bool) {
        uint256 balance = getWLBalance(user);

        if (balance > 0) {
            return true;
        }
        return false;
    }

    /** Only Owner Functions **/
    function mintOGIdentifier(uint256 amount) public onlyOwner {
        _mint(msg.sender, WBC_OG, amount, "");
    }

    function mintWLIdentifier(uint256 amount) public onlyOwner {
        _mint(msg.sender, WBC_WL, amount, "");
    }

    function distributeOGIdentifier(address[] calldata recipients)
        external
        onlyOwner
    {
        uint256 numRecipients = recipients.length;

        for (uint256 i = 0; i < numRecipients; i++) {
            _safeTransferFrom(msg.sender, recipients[i], WBC_OG, 1, "");
        }
    }

    function distributeWLIdentifier(address[] calldata recipients)
        external
        onlyOwner
    {
        uint256 numRecipients = recipients.length;

        for (uint256 i = 0; i < numRecipients; i++) {
            safeTransferFrom(msg.sender, recipients[i], WBC_WL, 1, "");
        }
    }

    function airdropNFT(uint256 _mintAmount, address _receiver)
        public
        mintCompliance(_mintAmount)
        onlyOwner
    {
        _mintNFT(_receiver, _mintAmount);
    }

    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }

    /**
     * ranges from 0-3
     * where 0 ~ paused,  1 ~ OG, 2 ~ WL, 3 ~ public.
     **/
    function moveRound() public onlyOwner {
        require(round < 3, "In the last Round");
        round++;
    }

    function setPaused(bool _pause) public onlyOwner {
        pause = _pause;
    }
    
    function setPublicPrice(uint256 price) public onlyOwner {
        publicPrice = price;
    }

    function setOGPrice(uint256 price) public onlyOwner {
        OGPrice = price;
    }

    function setWLPrice(uint256 price) public onlyOwner {
        WLPrice = price;
    }

    function setWLSupply(uint256 amount) public onlyOwner {
        WLSupply = amount;
    }

    function setOGSupply(uint256 amount) public onlyOwner {
        OGSupply = amount;
    }

    function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx)
        public
        onlyOwner
    {
        maxMintAmountPerTx = _maxMintAmountPerTx;
    }

    function setMaxMintAmountPerAddress(uint256 _maxMintAmountPerAddress)
        public
        onlyOwner
    {
        maxMintAmountPerAddress = _maxMintAmountPerAddress;
    }

    function setHiddenMetadataUri(string memory _hiddenMetadataUri)
        public
        onlyOwner
    {
        hiddenMetadataUri = _hiddenMetadataUri;
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix;
    }

    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }

    function withdraw() public onlyOwner nonReentrant {
        // This will pay the developer 5% of the initial sale as a bonus.
        // =============================================================================
        (bool hs, ) = payable(0xb7804B2D70be8B599E871430d62Fb3BFeee3622D).call{
            value: (address(this).balance * 5) / 100
        }("");
        require(hs);
        // =============================================================================

        // This will transfer the remaining contract balance to the owner.
        // Do not remove this otherwise you will not be able to withdraw the funds.
        // =============================================================================
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
        // =============================================================================
    }

    /** Internal**/
    function getOGBalance(address user) internal view returns (uint256) {
        return balanceOf(user, WBC_OG);
    }

    function getWLBalance(address user) internal view returns (uint256) {
        return balanceOf(user, WBC_WL);
    }

    function _baseURI() internal view virtual returns (string memory) {
        return uriPrefix;
    }

    function startFrom() internal  view virtual  returns (uint256) {
        return 1;
    }

    function _mintNFT(address to, uint256 amount) internal {
        uint256[] memory ids = new uint256[](amount);
        uint256[] memory amounts = new uint256[](amount);

        for (uint256 i = 0; i < amount; i++) {
            ids[i] = _totalSupply + i + startFrom();
            amounts[i] = 1;
            _totalSupply++;
        }

        _mintBatch(to, ids, amounts, "");
    }

    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}
