// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

import "./AbstractProxy.sol";

contract TokenProxy is AbstractProxy {
   
    constructor(
        address implementationAuthority,
        address _identityRegistry,
        address _compliance,
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        address _onchainID
    ) {
        require(
            implementationAuthority != address(0) &&
                _identityRegistry != address(0) &&
                _compliance != address(0),
            "invalid argument - zero address"
        );
        require(
            keccak256(abi.encode(_name)) != keccak256(abi.encode("")) &&
                keccak256(abi.encode(_symbol)) != keccak256(abi.encode("")),
            "invalid argument - empty string"
        );
        require(0 <= _decimals && _decimals <= 18, "decimals between 0 and 18");
        _storeImplementationAuthority(implementationAuthority);
        emit ImplementationAuthoritySet(implementationAuthority);

        address logic = Ifactory(getImplementationAuthority())
            .getTokenImplementation();

         

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = logic.delegatecall(
            abi.encodeWithSignature(
                "init(address,address,string,string,uint8,address)",
                _identityRegistry,
                _compliance,
                _name,
                _symbol,
                _decimals,
                _onchainID
            )
        );
        require(success, "Initialization failed.");
    }

    // solhint-disable-next-line no-complex-fallback
    fallback() external {
        address logic = Ifactory(getImplementationAuthority())
            .getTokenImplementation();

        // solhint-disable-next-line no-inline-assembly
        assembly {
            calldatacopy(0x0, 0x0, calldatasize())
            let success := delegatecall(
                sub(gas(), 10000),
                logic,
                0x0,
                calldatasize(),
                0,
                0
            )
            let retSz := returndatasize()
            returndatacopy(0, 0, retSz)
            switch success
            case 0 {
                revert(0, retSz)
            }
            default {
                return(0, retSz)
            }
        }
    }

    function get() public view returns(address){
        return Ifactory(getImplementationAuthority())
            .getTokenImplementation();
    }

}
