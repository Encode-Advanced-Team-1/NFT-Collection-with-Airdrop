// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.17;

import {ERC721Enumerable, ERC721} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {Counters} from "@openzeppelin/contracts/utils/Counters.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

contract NFT is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private s_tokenIds;

    string private s_baseExtension = ".json";
    uint256 private s_cost;
    uint256 private s_maxSupply;
    uint256 private s_maxMintAmount;
    string private s_baseURI;
    uint256 private s_totalSupply;

    mapping(uint256 => string) private s_tokenURIs;

    event Mint(uint256 amount, address indexed minter, uint256 indexed tokenId);
    event Withdraw(uint256 amount, address indexed withdrawer);

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _cost,
        uint256 _maxSupply,
        uint256 _maxMintAmount,
        string memory _baseURI
    ) ERC721(_name, _symbol) {
        s_cost = _cost;
        s_maxSupply = _maxSupply;
        s_maxMintAmount = _maxMintAmount;
        s_baseURI = _baseURI;
        s_totalSupply = 0;
    }

    // Mint function
    function mint(uint256 _mintAmount) public {
        assembly {
            // Check if mint amount exceeds max amount
            if gt(_mintAmount, sload(s_maxMintAmount.slot)) {
                // Revert with error message
                revert(0, 0)
            }
            // Check if mint amount is greater than 0
            if iszero(_mintAmount) {
                // Revert with error message
                revert(0, 0)
            }

            // Calculate total cost
            let totalCost := mul(_mintAmount, sload(s_cost.slot))

            // Check if ether value sent is correct for mint amount
            if lt(callvalue(), totalCost) {
                // Revert with error message
                revert(0, 0)
            }

            // Load supply
            let supply := sload(s_tokenIds.slot)

            // batch mint loop. must be less than mint amount
            for { let i := 0 } lt(i, _mintAmount) { i := add(i, 1) } {
                // Calculate tokenId
                let tokenId := add(supply, i)

                // Check if token exists
                for { let j := 0 } lt(j, 1) { j := add(j, 1) } {
                    // Check if token exists
                    if iszero(extcodesize(tokenId)) { break }

                    // Increment tokenId
                    tokenId := add(tokenId, 1)
                }

                // Mint token
                sstore(s_tokenIds.slot, add(supply, _mintAmount))
                sstore(s_totalSupply.slot, add(sload(s_totalSupply.slot), 1))
            }
        }
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        assembly {
            //    Calculate the length of the baseURI
            let baseURILength := mload(sload(s_baseURI.slot))

            // Calculate the length of the baseExtension
            let baseExtensionLength := mload(sload(s_baseExtension.slot))

            // Calculate the length of the tokenId string
            let tokenIdLength := mload(add(_tokenId, 0x20))

            // Calcualte the total length of the URI string
            let length := add(baseURILength, add(tokenIdLength, baseExtensionLength))

            // Allocate memory for the result
            let result := mload(0x40)

            // Set the length of the result string
            mstore(result, length)

            // Copy the baseURI to the result
            let dest := add(result, 0x20)
            let src := add(sload(s_baseURI.slot), 0x20)
            let i := 0
            for {} lt(i, baseURILength) { i := add(i, 1) } {
                mstore(dest, mload(src))
                dest := add(dest, 0x20)
                src := add(src, 0x20)
            }

            // Copy the tokenId string into the result
            src := _tokenId
            dest := add(result, baseURILength)
            for {} lt(src, add(_tokenId, tokenIdLength)) { src := add(src, 1) } {
                mstore(dest, mload(src))
                dest := add(dest, 0x20)
            }

            // Copy the baseExtension to the result
            src := s_baseExtension.slot
            dest := add(result, add(baseURILength, tokenIdLength))
            for {} lt(i, baseExtensionLength) { i := add(i, 1) } {
                mstore(dest, mload(src))
                dest := add(dest, 0x20)
                src := add(src, 0x20)
            }

            // Return the result
            return(result, length)
        }
    }

    function setMaxMintAmount(uint256 _amount) external onlyOwner {
        s_maxMintAmount = _amount;
    }

    function setCost(uint256 _newCost) external onlyOwner {
        s_cost = _newCost;
    }

    function getMaxMintAmount() external view returns (uint256) {
        return s_maxMintAmount;
    }

    function getCost() external view returns (uint256) {
        return s_cost;
    }

    function getTotalSupply() external view returns (uint256) {
        return s_totalSupply;
    }

    function getMaxSupply() external view returns (uint256) {
        return s_maxSupply;
    }

    function getBaseURI() external view returns (string memory) {
        return s_baseURI;
    }

    // Withdraw function
    function withdraw() public {
        address payable _owner = payable(owner());
        assembly {
            // Load balance
            let i_balance := balance(address())
            // Transfer balance to owner
            let success := call(gas(), _owner, i_balance, 0, 0, 0, 0)

            // Check if transfer was successful
            if iszero(success) {
                // Revert with error message
                revert(0, 0)
            }
        }
    }
}
