// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import {ERC1155} from "openzeppelin-contracts/token/ERC1155/ERC1155.sol";
import {AccessControl} from "openzeppelin-contracts/access/AccessControl.sol";
import {Pausable} from "openzeppelin-contracts/security/Pausable.sol";
import "openzeppelin-contracts/utils/Strings.sol";

contract Token is ERC1155, AccessControl, Pausable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    mapping(uint256 => bool) private _lockedTokens;
    string private _contractURI;
    string private _tokenURI;

    event TokenURISet(string tokenURI);
    event ContractURISet(string contractURI);

    constructor(string memory metadataContractURI, string memory metadataTokenURI) ERC1155(metadataTokenURI) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        _contractURI = metadataContractURI;
        _tokenURI = metadataTokenURI;

        emit TokenURISet(metadataTokenURI);
        emit ContractURISet(metadataTokenURI);
    }

    function mint(address to, uint256 id, uint256 quantity) external whenNotPaused onlyRole(MINTER_ROLE) {
        _mint(to, id, quantity, "");
    }

    function burn(uint256 id, uint256 amount) external whenNotPaused {
        _lockedTokens[id] = false;

        _burn(msg.sender, id, amount);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public override whenNotPaused {
        _lockedTokens[id] = true;

        super.safeTransferFrom(from, to, id, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public override whenNotPaused {
        for(uint256 i = 0; i < ids.length; i++) {
            _lockedTokens[ids[i]] = true;
        }

        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    function isTokenLocked(uint256 id) external view returns(bool) {
        return _lockedTokens[id];
    }

    function uri(uint256 id) public view override returns (string memory) {
        // TODO: exist token

        return string.concat(
            _tokenURI,
            Strings.toString(id),
            ".json"
        );
    }

    // function contractURI() public view returns (string memory) {
    //     return _contractURI;
    // } // TODO: убрать

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // region - Service functions -

    /**
     * @notice pause contract
     *
     */
    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    /**
     * @notice unpause contract
     */
    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    /**
     * @notice set new token URI
     * @param newTokenURI new token URI
     */
    function setTokenURI(string memory newTokenURI) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _tokenURI = newTokenURI;
        _setURI(newTokenURI);

        emit TokenURISet(newTokenURI);
    }

    /**
     * @notice set new contract URI
     * @param newContractURI new contract URI
     */
    function setContractURI(string memory newContractURI) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setURI(newContractURI);

        emit TokenURISet(newContractURI);
    }

    // endregion
}
