// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";

contract WiseBuddhiClub is ERC1155, Ownable, ERC1155Supply, ReentrancyGuard {
    using Strings for uint256;

    string private _name;
    string private _symbol;
    uint256 private _totalNFTs;

    uint256 private constant WBC_OG = 10001;
    uint256 private constant WBC_WL = 10002;
    mapping(address => uint256) private totalBalances;

    string private uriSuffix = ".json";
    string private uriPrefix;
    string private hiddenMetadataUri;
    string private identifierPrefix;

    uint256 public OGPrice = 0.001 ether;
    uint256 public WhitelistPrice = 0.001 ether;
    uint256 public publicPrice = 0.001 ether;

    uint256 public maxSupply = 10000;

    uint256 public OGSupply = 1000;
    uint256 public WhitelistSupply = 5000;

    uint256 private totalOGSupplyMinted;
    uint256 private totalWLSupplyMinted;

    uint256 public maxMintAmountPerTx = 3;
    uint256 public maxMintAmountPerAddress = 10;
    mapping(address => uint256) private mintedAmount;

    bool public revealed = false;
    bool public paused = false;
    uint8 private round = 0; // 1 ~ OG mint, 2 ~ WL mint, 3 ~ public mint

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        string memory _hiddenMetadataUri,
        string memory _identifierPrefix
    ) ERC1155("") Ownable(_msgSender()) {
        _name = _tokenName;
        _symbol = _tokenSymbol;
        setHiddenMetadataUri(_hiddenMetadataUri);
        setIdentifierPrefix(_identifierPrefix);

        _mint(owner(), WBC_OG, OGSupply, "");
        _mint(owner(), WBC_WL, WhitelistSupply, "");
    }

    /** Modifiers **/
    modifier mintCompliance(uint256 _mintAmount, address user) {
        require(!paused || _msgSender() == owner(), "Contract Is Paused");
        require(
            _mintAmount > 0 && _mintAmount <= maxMintAmountPerTx,
            "Invalid mint amount!"
        );
        require(
            mintedAmount[user] + _mintAmount <= maxMintAmountPerAddress,
            "Exceeds max mint amount"
        );
        require(
            totalSupply() + _mintAmount <= maxSupply,
            "Max supply exceeded!"
        );
        _;
    }

    modifier publicCompliance(uint256 _mintAmount) {
        require(round == 3, "Public mint has not started");
        require(msg.value >= publicPrice * _mintAmount, "Insufficient funds!");
        _;
    }

    modifier OGCompliance(uint256 _mintAmount) {
        require(totalOGSupplyMinted + _mintAmount <= OGSupply, "OG supply exceeded!");
        require(round == 1, "The OG Mint has not started!");
        require(msg.value >= OGPrice * _mintAmount, "Insufficient funds!");
        _;
    }

    modifier WLCompliance(uint256 _mintAmount) {
        require(
            totalWLSupplyMinted + _mintAmount <= WhitelistSupply,
            "WL supply exceeded!"
        );
        require(round == 2, "The WL Mint has not started!");
        require(
            msg.value >= WhitelistPrice * _mintAmount,
            "Insufficient funds!"
        );
        _;
    }

    /** Public Functions**/
    function whitelistMint(uint256 _mintAmount)
        public
        payable
        WLCompliance(_mintAmount)
        mintCompliance(_mintAmount, _msgSender())
    {
        mintedAmount[_msgSender()] += _mintAmount;
        totalWLSupplyMinted += _mintAmount;

        _mintNFT(_msgSender(), _mintAmount);
    }

    function OGMint(uint256 _mintAmount)
        public
        payable
        OGCompliance(_mintAmount)
        mintCompliance(_mintAmount, _msgSender())
    {
        mintedAmount[_msgSender()] += _mintAmount;
        totalOGSupplyMinted += _mintAmount;

        _mintNFT(_msgSender(), _mintAmount);
    }

    function mint(uint256 _mintAmount)
        public
        payable
        publicCompliance(_mintAmount)
        mintCompliance(_mintAmount, _msgSender())
    {
        mintedAmount[_msgSender()] += _mintAmount;

        _mintNFT(_msgSender(), _mintAmount);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public {
        super.safeTransferFrom(from, to, id, 1, "");
    }

    /** Public View Functions **/
    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    //returns total NFT supply
    function totalSupply() public view virtual override returns (uint256) {
        return _totalNFTs;
    }

    //returns totalSupply of all tokens including NFT's and FT
    function totalTokenSupply() public view virtual returns (uint256) {
        return super.totalSupply();
    }
    
    function balanceOf(address account) public view virtual returns (uint256) {
        return totalBalances[account];
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
        
        if(_tokenId == WBC_OG){
            return string(
                    abi.encodePacked(
                        identifierPrefix,
                        "og",
                        uriSuffix
                    )
                );
        }
        
        if(_tokenId == WBC_WL){
            return string(
                    abi.encodePacked(
                        identifierPrefix,
                        "whitelist",
                        uriSuffix
                    )
                );
        }

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

    function uri(uint256 _tokenId) public view virtual override returns (string memory) {
        return tokenURI(_tokenId);
    }

    function isUserOG(address user) public view returns (bool) {
        uint256 balance = getOGBalance(user);

        if (balance > 0) {
            return true;
        }
        return false;
    }

    function isUserWhitelist(address user) public view returns (bool) {
        uint256 balance = getWLBalance(user);

        if (balance > 0) {
            return true;
        }
        return false;
    }

    /** Only Owner Functions **/
    function mintOGIdentifier(uint256 amount) public onlyOwner {
        _mint(_msgSender(), WBC_OG, amount, "");
    }

    function mintWLIdentifier(uint256 amount) public onlyOwner {
        _mint(_msgSender(), WBC_WL, amount, "");
    }

    function distributeOGIdentifier(address[] calldata recipients)
        external
        onlyOwner
    {
        uint256 numRecipients = recipients.length;

        for (uint256 i = 0; i < numRecipients; i++) {
            _safeTransferFrom(_msgSender(), recipients[i], WBC_OG, 1, "");
        }
    }

    function distributeWLIdentifier(address[] calldata recipients)
        external
        onlyOwner
    {
        uint256 numRecipients = recipients.length;

        for (uint256 i = 0; i < numRecipients; i++) {
            safeTransferFrom(_msgSender(), recipients[i], WBC_WL, 1, "");
        }
    }

    function airdropNFT(uint256 _mintAmount, address _receiver)
        public
        mintCompliance(_mintAmount, _receiver)
        onlyOwner
    {
        _mintNFT(_receiver, _mintAmount);
    }

    function setRevealed() public onlyOwner {
        revealed = !revealed;
    }

    /**
     * ranges from 0-3
     * where 0 ~ paused,  1 ~ OG, 2 ~ WL, 3 ~ public.
     **/
    function moveRound() public onlyOwner {
        require(round < 3, "In the last Round");
        round++;
    }

    function setPaused() public onlyOwner {
        paused = !paused;
    }

    function setPublicPrice(uint256 price) public onlyOwner {
        publicPrice = price;
    }

    function setOGPrice(uint256 price) public onlyOwner {
        OGPrice = price;
    }

    function setWhitelistPrice(uint256 price) public onlyOwner {
        WhitelistPrice = price;
    }

    function setWhitelistSupply(uint256 amount) public onlyOwner {
        WhitelistSupply = amount;
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

    function setIdentifierPrefix(string memory _identifierPrefix)
        public
        onlyOwner
    {
        identifierPrefix = _identifierPrefix;
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

    function startFrom() internal view virtual returns (uint256) {
        return 1;
    }

    function _mintNFT(address to, uint256 amount) internal {
        uint256[] memory ids = new uint256[](amount);
        uint256[] memory amounts = new uint256[](amount);

        for (uint256 i = 0; i < amount; i++) {
            ids[i] = _totalNFTs + startFrom();
            amounts[i] = 1;
            _totalNFTs++;
        }

        _mintBatch(to, ids, amounts, "");
    }

    function _getTransferAmount(uint256[] memory ids, uint256[] memory values)
        internal
        pure
        virtual
        returns (uint256)
    {
        uint256 amount = 0;

        for (uint256 i = 0; i < ids.length; i++) {
            // Exclude selected identifier IDs from total
            if (ids[i] != WBC_OG && ids[i] != WBC_WL) {
                amount += values[i];
            }
        }

        return amount;
    }

    function _update(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values
    ) internal override(ERC1155, ERC1155Supply) {
        if (from == address(0)) {
            uint256 amount = _getTransferAmount(ids, values);
            totalBalances[to] += amount;
        } else {
            uint256 amountTransfered = _getTransferAmount(ids, values);

            totalBalances[from] -= amountTransfered;
            if (to != address(0)) {
                totalBalances[to] += amountTransfered;
            } else {
                _totalNFTs -= amountTransfered;
            }
        }

        super._update(from, to, ids, values);
    }

    receive() external payable {}
}
