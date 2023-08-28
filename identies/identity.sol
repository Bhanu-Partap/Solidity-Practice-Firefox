// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;
import "@onchain-id/solidity/contracts/Identity.sol";

contract identities is Identity {
    constructor(address initialManagementKey)
        Identity(initialManagementKey, false)
    {}

    function bytekey(address _address) external pure returns (bytes32) {
        return keccak256(abi.encode(_address));
    }

    function datahash(
        address identityHolder_address,
        uint256 _topic,
        bytes calldata data
    ) public pure returns (bytes32) {
        return keccak256(abi.encode(identityHolder_address, _topic, data));
    }

    function bytesdata(string memory data) public pure returns (bytes memory) {
        return abi.encode(data);
    }
}
