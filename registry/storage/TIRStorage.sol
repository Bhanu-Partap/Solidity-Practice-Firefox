// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

import "@onchain-id/solidity/contracts/interface/IClaimIssuer.sol";

contract TIRStorage {
    // Array containing all TrustedIssuers identity contract address.
    IClaimIssuer[] internal _trustedIssuers;

    // Mapping between a trusted issuer address and its corresponding claimTopics.
    mapping(address => uint256[]) internal _trustedIssuerClaimTopics;

    // Mapping between a claim topic and the allowed trusted issuers for it.
    mapping(uint256 => IClaimIssuer[]) internal _claimTopicsToTrustedIssuers;

    uint256[49] private __gap;
}
