// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "./IERC20.sol";
import {IERC20Permit} from "./IERC20Permit.sol";
import {ECDSA} from "../lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
contract ERC20 is IERC20, IERC20Permit{
	string private _name;
	string private _symbol;
	uint256 private _totalSupply;
	uint8 private _decimals;
	uint256 private _version;
	mapping(address account => uint256) private nonce_list;
	mapping(address account => uint256) private _balances;
	mapping(address account => mapping(address spender => uint256)) private _allowances;
	address admin;
	bool isNotPause;
	modifier pauseChk{
		require(isNotPause, "pause!");
		_;
	}
	modifier chk{
		require(msg.sender == admin);
		_;
	}
	function version() public view returns(uint256){
		return _version;
	}
	function setVersion(uint256 ver)chk public{
		_version = ver;
	}
	constructor(string memory __name, string memory __symbol) {
		isNotPause = true;
		admin = tx.origin;
		_version = 1;
		_name = __name;
		_symbol = __symbol; 
		_totalSupply = 100000000000000000000; 
		_balances[msg.sender] = _totalSupply;
		_decimals = 18;
	}
	function decimals() public view virtual returns (uint8) {
		return 18;
	}
	function name() public view virtual returns (string memory) {
		return _name;
	}
	function symbol() public view virtual returns (string memory) {
		return _symbol;
	}
	function totalSupply() public view virtual returns (uint256) {
		return _totalSupply;
	}
	function balanceOf(address account) public view virtual returns (uint256) {
		return _balances[account];
	}
    function transfer(address to, uint256 value) public virtual returns (bool) {
		address owner = msg.sender;
		_transfer(owner, to, value);
		return true;
	}
	function _transfer(address from, address to, uint256 value) internal {
		if (from == address(0)) {
			revert("from address(0)");
		}
		if (to == address(0)) {
			revert("to address(0)");
		}
		_update(from, to, value);
	}
    function _update(address from, address to, uint256 value) pauseChk internal virtual {
        if (from == address(0)) {
            _totalSupply += value;
        } else {
            uint256 fromBalance = _balances[from];
            if (fromBalance < value) {
                revert("balance revert");
            }
            unchecked {
                _balances[from] = fromBalance - value;
            }
        }
        if (to == address(0)) {
            unchecked {
                _totalSupply -= value;
            }
        } else {
            unchecked {
                _balances[to] += value;
            }
        }
        emit Transfer(from, to, value);
    }
    function allowance(address owner, address spender) public view virtual returns (uint256) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint256 value) public virtual returns (bool) {
        address owner = msg.sender;
        _approve(owner, spender, value);
        return true;
    }
    function _approve(address owner, address spender, uint256 value) internal {
        _approve(owner, spender, value, true);
    }
    function _approve(address owner, address spender, uint256 value, bool emitEvent) internal virtual {
        if (owner == address(0)) {
            revert("address(0)");
        }
        if (spender == address(0)) {
            revert("address(0)");
        }
        _allowances[owner][spender] = value;
        if (emitEvent) {
            emit Approval(owner, spender, value);
        }
    }
    function _spendAllowance(address owner, address spender, uint256 value) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            if (currentAllowance < value) {
                revert("value revert");
            }
            unchecked {
                _approve(owner, spender, currentAllowance - value, false);
            }
        }
    }
    function transferFrom(address from, address to, uint256 value) public virtual returns (bool) {
        address spender = msg.sender;
        _spendAllowance(from, spender, value);
        _transfer(from, to, value);
		emit Transfer(from, to, value);
        return true;
    }
    function _mint(address to, uint256 amount) internal{
		_totalSupply += amount;
		_balances[to] += amount;
		emit Transfer(address(0), to, amount);
    }
	function mint(address to, uint256 amount) public{
		mint(to, amount);

	}

	function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public{
		require(block.timestamp < deadline, "expire sign");
		bytes32 permit_typehash = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
//		console.log(nonces(owner));
		bytes32 structHash = keccak256(abi.encode(permit_typehash, owner, spender, value, nonces(owner), deadline));
		bytes32 hash = _toTypedDataHash(structHash);
		address signer = ECDSA.recover(hash, v, r, s);
		require(signer==owner, "INVALID_SIGNER");
		_approve(owner, spender, value);
		addNonce(signer);
	}
	function burn(uint256 value) external {
		_burn(value);
	}
	function _burn(uint256 value) internal{
		address from = msg.sender;
		address to = address(0);
		_update(from, to, value);
	}
	function pause() external chk{
		
	}
	function DOMAIN_SEPARATOR() public view returns (bytes32){
		uint256 versions = version();
		bytes32 _DOMAIN_SEPARATOR = keccak256(abi.encode(keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),keccak256(bytes(name())), keccak256(bytes(abi.encodePacked(versions))), block.chainid, address(this)));
		return _DOMAIN_SEPARATOR;
	}
	function _toTypedDataHash(bytes32 hash) public view returns(bytes32){
		bytes32 separator = DOMAIN_SEPARATOR();
		bytes32 digest = keccak256(abi.encodePacked("\x19\x01", separator, hash));
		return digest;
	}
	function nonces(address owner) public view returns (uint256){
		return nonce_list[owner];
	}
	function addNonce(address owner) internal {
		nonce_list[owner] += 1;
	}
}
