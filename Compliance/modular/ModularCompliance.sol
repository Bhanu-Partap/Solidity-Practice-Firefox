// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../../token/Itoken.sol";
import "./IModularCompliance.sol";
import "./MCStorage.sol";
import "./Modules/IModule.sol";

contract ModularCompliance is
    IModularCompliance,
    OwnableUpgradeable,
    MCStorage
{
    // modifiers
    modifier onlyToken() {
        require(
            msg.sender == _tokenBound,
            "error : this address is not a token bound to the compliance contract"
        );
        _;
    }

    function init() external initializer {
        __Ownable_init();
    }

    function bindToken(address _token) external override {
        require(
            owner() == msg.sender ||
                (_tokenBound == address(0) && msg.sender == _token),
            "only owner or token can call"
        );
        require(_token != address(0), "invalid argument - zero address");
        _tokenBound = _token; //here the _tokenBound is a variable that stores the address of the token w.r.t identity
        emit TokenBound(_token);
    }

    function unbindToken(address _token) external override {
        require(
            owner() == msg.sender || msg.sender == _token,
            "only owner or token can call"
        );
        require(_token == _tokenBound, "This token is not bound");
        require(_token != address(0), "invalid argument - zero address");
        delete _tokenBound;
        emit TokenUnbound(_token);
    }

    function addModule(address _module) external override onlyOwner {
        require(_module != address(0), "invalid argument - zero address");
        require(!_moduleBound[_module], "module already bound");
        require(_modules.length <= 24, "cannot add more than 25 modules");
        IModule(_module).bindCompliance(address(this));
        _modules.push(_module);
        _moduleBound[_module] = true;
        emit ModuleAdded(_module);
    }

    function removeModule(address _module) external override onlyOwner {
        require(_module != address(0), "invalid argument - zero address");
        require(_moduleBound[_module], "module not bound");
        uint256 length = _modules.length;
        for (uint256 i = 0; i < length; i++) {
            if (_modules[i] == _module) {
                IModule(_module).unbindCompliance(address(this));
                _modules[i] = _modules[length - 1];
                _modules.pop();
                _moduleBound[_module] = false;
                emit ModuleRemoved(_module);
                break;
            }
        }
    }

    function transferred(
        address _from,
        address _to,
        uint256 _value
    ) external override onlyToken {
        require(
            _from != address(0) && _to != address(0),
            "invalid argument - zero address"
        );
        require(_value > 0, "invalid argument - no value transfer");
        uint256 length = _modules.length;
        for (uint256 i = 0; i < length; i++) {
            IModule(_modules[i]).moduleTransferAction(_from, _to, _value);
        }
    }

    function created(address _to, uint256 _value) external override onlyToken {
        require(_to != address(0), "invalid argument - zero address");
        require(_value > 0, "invalid argument - no value mint");
        uint256 length = _modules.length;
        for (uint256 i = 0; i < length; i++) {
            IModule(_modules[i]).moduleMintAction(_to, _value);
        }
    }

    function destroyed(address _from, uint256 _value)
        external
        override
        onlyToken
    {
        require(_from != address(0), "invalid argument - zero address");
        require(_value > 0, "invalid argument - no value burn");
        uint256 length = _modules.length;
        for (uint256 i = 0; i < length; i++) {
            IModule(_modules[i]).moduleBurnAction(_from, _value);
        }
    }

    function callModuleFunction(bytes calldata callData, address _module)
        external
        override
        onlyOwner
    {
        require(_moduleBound[_module], "call only on bound module");
        assembly {
            let freeMemoryPointer := mload(0x40)
            calldatacopy(freeMemoryPointer, callData.offset, callData.length)
            if iszero(
                call(
                    gas(),
                    _module,
                    0,
                    freeMemoryPointer,
                    callData.length,
                    0,
                    0
                )
            ) {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }

        emit ModuleInteraction(_module, _selector(callData));
    }

    function isModuleBound(address _module)
        external
        view
        override
        returns (bool)
    {
        return _moduleBound[_module];
    }

    function getModules() external view override returns (address[] memory) {
        return _modules;
    }

    function getTokenBound() external view override returns (address) {
        return _tokenBound;
    }

    function canTransfer(
        address _from,
        address _to,
        uint256 _value
    ) external view override returns (bool) {
        uint256 length = _modules.length;
        for (uint256 i = 0; i < length; i++) {
            if (
                !IModule(_modules[i]).moduleCheck(
                    _from,
                    _to,
                    _value,
                    address(this)
                )
            ) {
                return false;
            }
        }
        return true;
    }

    function _selector(bytes calldata callData)
        internal
        pure
        returns (bytes4 result)
    {
        if (callData.length >= 4) {
            assembly {
                result := calldataload(callData.offset)
            }
        }
    }
}
