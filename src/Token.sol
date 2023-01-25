// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import {ERC1155} from "openzeppelin-contracts/token/ERC1155/ERC1155.sol";
import {AccessControl} from "openzeppelin-contracts/access/AccessControl.sol";
import {Pausable} from "openzeppelin-contracts/security/Pausable.sol";
import "openzeppelin-contracts/utils/Strings.sol";

contract Token is ERC1155, AccessControl, Pausable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    mapping(uint256 => bool) private _lockedTokens;

    event URISet(string URI);

    constructor(string memory _URI) ERC1155(_URI) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        emit URISet(_URI);
    }

    function mint(address _to, uint256 _id, uint256 _quantity) external whenNotPaused onlyRole(MINTER_ROLE) {
        _mint(_to, _id, _quantity, "");
    }

    function burn(uint256 _id, uint256 _amount) external whenNotPaused {
        _lockedTokens[_id] = false;

        _burn(msg.sender, _id, _amount);
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _amount,
        bytes memory _data
    ) public override whenNotPaused {
        _lockedTokens[_id] = true;

        super.safeTransferFrom(_from, _to, _id, _amount, _data);
    }

    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] memory _ids,
        uint256[] memory _amounts,
        bytes memory _data
    ) public override whenNotPaused {
        for(uint256 i = 0; i < _ids.length; i++) {
            _lockedTokens[_ids[i]] = true;
        }

        super.safeBatchTransferFrom(_from, _to, _ids, _amounts, _data);
    }

    function isTokenLocked(uint256 _id) external view returns(bool) {
        return _lockedTokens[_id];
    }

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
     * @notice set new URI
     * @param _URI new URI
     */
    function setURI(string memory _URI) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setURI(_URI);

        emit URISet(_URI);
    }

    // endregion
}
