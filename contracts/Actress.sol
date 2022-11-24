//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "contracts/lib/Admin.sol";

contract Actress is ERC721Upgradeable, OwnableUpgradeable, Admin {
    string private uri;

    struct ConfigReq {
        uint64 price;
        uint64 saleStartTime;
        uint64 saleEndTime;
    }

    struct Config {
        uint64 price;
        uint64 saleStartTime;
        uint64 saleEndTime;
        uint64 totalSupply;
    }
    Config public cfg;
    mapping(uint256 => bool) usedSalt;

    event Bought(
        address indexed user,
        uint256 indexed tokenId,
        uint256 indexed salt
    );

    function initialize(
        string memory _name,
        string memory _symbol,
        string memory _uri,
        ConfigReq memory _cfg
    ) public initializer {
        __ERC721_init(_name, _symbol);
        __Ownable_init();
        setURI(_uri);
        setConfig(_cfg);
    }

    /// @notice Set the prefix of URL for NFT
    /// @dev The url of nft is spliced ​​by _uri + tokenId
    /// @param _uri The prefix of URL of nft
    function setURI(string memory _uri) public onlyAdmin {
        uri = _uri;
    }

    /// @notice Set the config
    /// @dev price: 1 = 0.001 ether, 1000 = 1 ether
    /// @param _cfg Just set price 、saleStartTime and saleEndTime in config
    function setConfig(ConfigReq memory _cfg) public onlyAdmin {
        cfg.price = _cfg.price;
        cfg.saleStartTime = _cfg.saleStartTime;
        cfg.saleEndTime = _cfg.saleEndTime;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uri;
    }

    /// @notice This method can buy nft
    /// @dev nft can only be purchased if block.timestamp is between saleStartTime and saleEndTime
    /// @param _salt Used to bind tokenId, need to confirm metadata information through _salt
    function buy(uint256 _salt) external payable {
        address sender = _msgSender();
        require(block.timestamp >= cfg.saleStartTime, "Not Started");
        require(block.timestamp <= cfg.saleEndTime, "End of sale");
        require(msg.value == cfg.price * 1e15, "Invalid amount");
        require(tx.origin == sender, "Invalid sender");
        require(!usedSalt[_salt], "Salt has been used");

        _mint(_msgSender(), cfg.totalSupply);
        emit Bought(_msgSender(), cfg.totalSupply, _salt);
        cfg.totalSupply++;
        usedSalt[_salt] = true;
    }

    /// @notice Withdraw the balance of the contract
    /// @param _to Withdraw the balance of the contract to `_to`
    function withdraw(address _to) external onlyOwner {
        payable(_to).transfer(address(this).balance);
    }
}
