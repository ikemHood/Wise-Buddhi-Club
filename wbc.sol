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

    bool public revealed;
    bool public paused;
    uint8 private round; // 1 ~ OG mint, 2 ~ WL mint, 3 ~ public mint

    /**
     * @dev Initializes the contract with the given parameters.
     * @param _tokenName Name of the token.
     * @param _tokenSymbol Symbol of the token.
     * @param _hiddenMetadataUri URI for hidden metadata.
     * @param _identifierPrefix Prefix for the identifier.
     */
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

    /**
     * @dev Ensures minting complies with set rules.
     * @param _mintAmount Amount to mint.
     * @param user Address of the user minting.
     */
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

    /**
     * @dev Ensures compliance for public minting.
     * @param _mintAmount Amount to mint.
     */
    modifier publicCompliance(uint256 _mintAmount) {
        require(round == 3, "Public mint has not started");
        require(msg.value >= publicPrice * _mintAmount, "Insufficient funds!");
        _;
    }

    /**
     * @dev Ensures compliance for OG minting.
     * @param _mintAmount Amount to mint.
     */
    modifier OGCompliance(uint256 _mintAmount) {
        require(
            totalOGSupplyMinted + _mintAmount <= OGSupply,
            "OG supply exceeded!"
        );
        require(round == 1, "The OG Mint has not started!");
        require(msg.value >= OGPrice * _mintAmount, "Insufficient funds!");
        _;
    }

    /**
     * @dev Ensures compliance for whitelist minting.
     * @param _mintAmount Amount to mint.
     */
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

    /**
     * @dev Allows whitelisted users to mint tokens.
     * @param _mintAmount The number of tokens to mint.
     */
    function whitelistMint(
        uint256 _mintAmount
    )
        public
        payable
        WLCompliance(_mintAmount)
        mintCompliance(_mintAmount, _msgSender())
    {
        mintedAmount[_msgSender()] += _mintAmount;
        totalWLSupplyMinted += _mintAmount;

        _mintNFT(_msgSender(), _mintAmount);
    }

    /**
     * @dev Allows OG users to mint tokens.
     * @param _mintAmount The number of tokens to mint.
     */
    function OGMint(
        uint256 _mintAmount
    )
        public
        payable
        OGCompliance(_mintAmount)
        mintCompliance(_mintAmount, _msgSender())
    {
        mintedAmount[_msgSender()] += _mintAmount;
        totalOGSupplyMinted += _mintAmount;

        _mintNFT(_msgSender(), _mintAmount);
    }

    /**
     * @dev Allows any user to mint tokens during the public sale.
     * @param _mintAmount The number of tokens to mint.
     */
    function mint(
        uint256 _mintAmount
    )
        public
        payable
        publicCompliance(_mintAmount)
        mintCompliance(_mintAmount, _msgSender())
    {
        mintedAmount[_msgSender()] += _mintAmount;

        _mintNFT(_msgSender(), _mintAmount);
    }

    /**
     * @dev Transfers a single token of a given ID from one address to another.
     * @param from Address to transfer from.
     * @param to Address to transfer to.
     * @param id Token ID to transfer.
     */
    function transferFrom(address from, address to, uint256 id) public {
        super.safeTransferFrom(from, to, id, 1, "");
    }

    /** Public View Functions **/

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the total supply of NFTs only.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalNFTs;
    }

    /**
     * @dev Returns the total supply of all tokens, including NFTs and fungible tokens.
     */
    function totalTokenSupply() public view virtual returns (uint256) {
        return super.totalSupply();
    }

    /**
     * @dev Returns the NFT balance of a specific address.
     * @param account Address to check the balance of.
     */
    function balanceOf(address account) public view virtual returns (uint256) {
        return totalBalances[account];
    }

    /**
     * @dev Returns the current minting round status.
     */
    function getRoundStatus() public view returns (uint8) {
        return round;
    }

    /**
     * @dev Returns the URI for a given token ID.
     * @param _tokenId ID of the token to retrieve its URI.
     */
    function tokenURI(
        uint256 _tokenId
    ) public view virtual returns (string memory) {
        if (_tokenId == WBC_OG) {
            return string(abi.encodePacked(identifierPrefix, "og", uriSuffix));
        }

        if (_tokenId == WBC_WL) {
            return
                string(
                    abi.encodePacked(identifierPrefix, "whitelist", uriSuffix)
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

    /**
     * @dev Returns the URI for a given token ID.
     * @param _tokenId ID of the token to retrieve its URI.
     */
    function uri(
        uint256 _tokenId
    ) public view virtual override returns (string memory) {
        return tokenURI(_tokenId);
    }

    /**
     * @dev Checks if a user is an OG user.
     * @param user Address of the user to check.
     * @return bool True if the user is an OG user, false otherwise.
     */
    function isUserOG(address user) public view returns (bool) {
        return getOGBalance(user) > 0;
    }

    /**
     * @dev Checks if a user is a whitelisted user.
     * @param user Address of the user to check.
     * @return bool True if the user is a whitelisted user, false otherwise.
     */
    function isUserWhitelist(address user) public view returns (bool) {
        return getWLBalance(user) > 0;
    }

    /** Only Owner Functions **/

    /**
     * @dev Allows the owner to mint OG identifiers.
     * @param amount Amount of OG identifiers to mint.
     */
    function mintOGIdentifier(uint256 amount) public onlyOwner {
        _mint(_msgSender(), WBC_OG, amount, "");
    }

    /**
     * @dev Allows the owner to mint whitelist identifiers.
     * @param amount Amount of whitelist identifiers to mint.
     */
    function mintWLIdentifier(uint256 amount) public onlyOwner {
        _mint(_msgSender(), WBC_WL, amount, "");
    }

    /**
     * @dev Allows the owner to distribute OG identifiers to a list of recipients.
     * @param recipients List of addresses to receive the OG identifiers.
     */
    function distributeOGIdentifier(
        address[] calldata recipients
    ) external onlyOwner {
        uint256 numRecipients = recipients.length;

        for (uint256 i = 0; i < numRecipients; i++) {
            _safeTransferFrom(_msgSender(), recipients[i], WBC_OG, 1, "");
        }
    }

    /**
     * @dev Allows the owner to distribute whitelist identifiers to a list of recipients.
     * @param recipients List of addresses to receive the whitelist identifiers.
     */
    function distributeWLIdentifier(
        address[] calldata recipients
    ) external onlyOwner {
        uint256 numRecipients = recipients.length;

        for (uint256 i = 0; i < numRecipients; i++) {
            safeTransferFrom(_msgSender(), recipients[i], WBC_WL, 1, "");
        }
    }

    /**
     * @dev Allows the owner to airdrop NFTs to a specific address.
     * @param _mintAmount Amount of NFTs to airdrop.
     * @param _receiver Address to receive the airdropped NFTs.
     */
    function airdropNFT(
        uint256 _mintAmount,
        address _receiver
    ) public mintCompliance(_mintAmount, _receiver) onlyOwner {
        _mintNFT(_receiver, _mintAmount);
    }

    /**
     * @dev Allows the owner to reveal the metadata.
     */
    function setRevealed() public onlyOwner {
        revealed = !revealed;
    }

    /**
     * @dev Allows the owner to move to the next minting round.
     * ranges from 1-3
     */
    function moveRound() public onlyOwner {
        require(round < 3, "In the last Round");
        round++;
    }

    /**
     * @dev Allows the owner to pause or unpause the contract.
     */
    function setPaused() public onlyOwner {
        paused = !paused;
    }

    /**
     * @dev Allows the owner to set the price for public minting.
     * @param price New price for public minting.
     */
    function setPublicPrice(uint256 price) public onlyOwner {
        publicPrice = price;
    }

    /**
     * @dev Allows the owner to set the price for OG minting.
     * @param price New price for OG minting.
     */
    function setOGPrice(uint256 price) public onlyOwner {
        OGPrice = price;
    }

    /**
     * @dev Allows the owner to set the price for whitelist minting.
     * @param price New price for whitelist minting.
     */
    function setWhitelistPrice(uint256 price) public onlyOwner {
        WhitelistPrice = price;
    }

    /**
     * @dev Allows the owner to set the supply for whitelist minting.
     * @param amount New supply for whitelist minting.
     */
    function setWhitelistSupply(uint256 amount) public onlyOwner {
        WhitelistSupply = amount;
    }

    /**
     * @dev Allows the owner to set the supply for OG minting.
     * @param amount New supply for OG minting.
     */
    function setOGSupply(uint256 amount) public onlyOwner {
        OGSupply = amount;
    }

    /**
     * @dev Allows the owner to set the maximum mint amount per transaction.
     * @param _maxMintAmountPerTx New maximum mint amount per transaction.
     */
    function setMaxMintAmountPerTx(
        uint256 _maxMintAmountPerTx
    ) public onlyOwner {
        maxMintAmountPerTx = _maxMintAmountPerTx;
    }

    /**
     * @dev Allows the owner to set the maximum mint amount per address.
     * @param _maxMintAmountPerAddress New maximum mint amount per address.
     */
    function setMaxMintAmountPerAddress(
        uint256 _maxMintAmountPerAddress
    ) public onlyOwner {
        maxMintAmountPerAddress = _maxMintAmountPerAddress;
    }

    /**
     * @dev Allows the owner to set the hidden metadata URI.
     * @param _hiddenMetadataUri New hidden metadata URI.
     */
    function setHiddenMetadataUri(
        string memory _hiddenMetadataUri
    ) public onlyOwner {
        hiddenMetadataUri = _hiddenMetadataUri;
    }

    /**
     * @dev Allows the owner to set the identifier prefix.
     * @param _identifierPrefix New identifier prefix.
     */
    function setIdentifierPrefix(
        string memory _identifierPrefix
    ) public onlyOwner {
        identifierPrefix = _identifierPrefix;
    }

    /**
     * @dev Allows the owner to set the URI prefix.
     * @param _uriPrefix New URI prefix.
     */
    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix;
    }

    /**
     * @dev Allows the owner to set the URI Surfix.
     * @param _uriSuffix New URI Surfix.
     */
    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }

    /**
     * @dev Allows the owner to withdraw the contract balance.
     */
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

    /** Internal Functions **/

    /**
     * @dev Returns the balance of OG identifiers for a specific address.
     * @param user Address to check the balance of OG identifiers.
     */
    function getOGBalance(address user) internal view returns (uint256) {
        return balanceOf(user, WBC_OG);
    }

    /**
     * @dev Returns the balance of whitelist identifiers for a specific address.
     * @param user Address to check the balance of whitelist identifiers.
     */
    function getWLBalance(address user) internal view returns (uint256) {
        return balanceOf(user, WBC_WL);
    }

    /**
     * @dev Returns the base URI.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return uriPrefix;
    }

    /**
     * @dev Returns token ID start from.
     */
    function startFrom() internal view virtual returns (uint256) {
        return 1;
    }

    /**
     * @dev Mints NFTs to a specific address.
     * @param to Address to receive the minted NFTs.
     * @param amount Amount of NFTs to mint.
     */
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
    
    /**
    * @dev Internal function that calculates the total transfer amount for NFTs.
    * This function ensures that the fungible token supplies (like WBC_OG and WBC_WL) are excluded 
    * from the total NFT transfer amount, providing a clear distinction between fungible and non-fungible tokens.
    * 
    * @param ids Array of token IDs involved in the transfer.
    * @param values Array of amounts for each token ID being transferred.
    * @return amount Total transfer amount for NFTs after excluding fungible tokens.
    */
    function _getTransferAmount(
        uint256[] memory ids,
        uint256[] memory values
    ) internal pure virtual returns (uint256) {
        uint256 amount = 0;

        for (uint256 i = 0; i < ids.length; i++) {
            // Exclude selected identifier IDs from total
            if (ids[i] != WBC_OG && ids[i] != WBC_WL) {
                amount += values[i];
            }
        }

        return amount;
    }

    /**
     * @dev Internal function that updates the balances of the sender and receiver during a transfer operation.
     * This function is overridden from the ERC1155 and ERC1155Supply contracts.
     * It ensures that the total balances are correctly updated based on the token IDs and their respective values.
     * If the 'from' address is the zero address, it means tokens are being minted.
     * If the 'to' address is the zero address, it means tokens are being burned.
     *
     * @param from Address of the sender.
     * @param to Address of the receiver.
     * @param ids Array of token IDs being transferred.
     * @param values Array of amounts for each token ID being transferred.
     */
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
