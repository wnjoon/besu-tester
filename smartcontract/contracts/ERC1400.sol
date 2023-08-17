// SPDX-License-Identifier: Apache-2.0
/*
 * This code has not been reviewed.
 * Do not use or deploy this code before reviewing it personally first.
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./tools/ERC1820Client.sol";
import "./interface/ERC1820Implementer.sol";

import "./roles/MinterRole.sol";

import "./interface/IERC1400.sol";

// Extensions
import "./extensions/tokenExtensions/IERC1400TokensValidator.sol";
import "./extensions/tokenExtensions/IERC1400TokensChecker.sol";
import "./extensions/userExtensions/IERC1400TokensSender.sol";
import "./extensions/userExtensions/IERC1400TokensRecipient.sol";
import "./tools/DomainAware.sol";

contract ERC1400 is IERC1400 {
    /************************************* Token description ****************************************/
    string private _name;
    string private _symbol;
    uint256 private _totalSupply;
    /************************************************************************************************/

    /**************************************** Token behaviours **************************************/
    bool internal _isIssuable;
    /************************************************************************************************/

    /********************************** ERC20 Token mappings ****************************************/
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) internal _allowed;
    /************************************************************************************************/

    /**************************************** Documents *********************************************/
    struct Doc {
        string docURI;
        bytes32 docHash;
        uint256 timestamp;
    }

    mapping(bytes32 => Doc) private _documents;
    mapping(bytes32 => uint256) private _indexOfDocHashes;
    bytes32[] private _docHashes;
    /************************************************************************************************/

    /*********************************** Partitions  mappings ***************************************/
    bytes32[] private _totalPartitions;
    mapping(bytes32 => uint256) private _indexOfTotalPartitions;
    mapping(bytes32 => uint256) private _totalSupplyByPartition;
    mapping(address => bytes32[]) private _partitionsOf;
    mapping(address => mapping(bytes32 => uint256))
        private _indexOfPartitionsOf;
    mapping(address => mapping(bytes32 => uint256))
        private _balanceOfByPartition;
    bytes32 internal constant DEFAULT_PARTITION = "DEFAULT_PARTITION";
    /************************************************************************************************/

    /********************************* Global operators mappings ************************************/
    mapping(address => mapping(address => bool)) private _authorizedOperator;
    address[] private _controllers;
    mapping(address => bool) private _isController;
    /************************************************************************************************/

    /******************************** Partition operators mappings **********************************/
    mapping(address => mapping(bytes32 => mapping(address => bool)))
        private _authorizedOperatorByPartition;

    /************************************************************************************************/

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _isIssuable = true;

        // controllable token is default and add deployer to controller
        _controllers.push(msg.sender);
        _isController[msg.sender] = true;
    }

    /************************************************************************************************/
    /****************************** Public Functions (ERC20 INTERFACE) ****************************/
    /************************************************************************************************/

    // sum of supply of partitions
    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    // sum of balance of partitions
    function balanceOf(
        address tokenHolder
    ) public view virtual returns (uint256) {
        return _balances[tokenHolder];
    }

    function transfer(address to, uint256 value) public virtual returns (bool) {
        _transferByPartition(
            DEFAULT_PARTITION,
            msg.sender,
            msg.sender,
            to,
            value,
            "",
            ""
        );

        return true;
    }

    function allowance(
        address owner,
        address spender
    ) public view virtual returns (uint256) {
        return _allowed[owner][spender];
    }

    function approve(
        address spender,
        uint256 value
    ) public virtual returns (bool) {
        require(spender != address(0), "56"); // 0x56	invalid sender

        _allowed[msg.sender][spender] = value;

        emit Approval(msg.sender, spender, value);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public virtual returns (bool) {
        require(value <= _allowed[from][msg.sender], "53"); // 0x53	insufficient allowance

        _allowed[from][msg.sender] -= value;
        _transferByPartition(
            DEFAULT_PARTITION,
            msg.sender,
            from,
            to,
            value,
            "",
            ""
        );

        return true;
    }

    /************************************************************************************************/
    /****************************** EXTERNAL FUNCTIONS (ERC1400 INTERFACE) **************************/
    /************************************************************************************************/

    /************************************* Document Management **************************************/
    function getDocument(
        bytes32 name_
    ) public view virtual returns (string memory, bytes32, uint256) {
        return (
            _documents[name_].docURI,
            _documents[name_].docHash,
            _documents[name_].timestamp
        );
    }

    function setDocument(
        bytes32 name_,
        string calldata uri,
        bytes32 documentHash
    ) public virtual {
        require(_isController[msg.sender], "58");

        _documents[name_] = Doc({
            docURI: uri,
            docHash: documentHash,
            timestamp: block.timestamp
        });

        if (_indexOfDocHashes[documentHash] == 0) {
            _docHashes.push(documentHash);
            _indexOfDocHashes[documentHash] = _docHashes.length;
        }

        emit DocumentUpdated(name_, uri, documentHash);
    }

    function removeDocument(bytes32 name_) public virtual {
        require(_isController[msg.sender], "58");

        if (bytes(_documents[name_].docURI).length > 0) {
            Doc memory data = _documents[name_];

            uint256 index1 = _indexOfDocHashes[data.docHash];

            // move the last item into the index being vacated
            bytes32 lastValue = _docHashes[_docHashes.length - 1];
            _docHashes[index1 - 1] = lastValue; // adjust for 1-based indexing
            _indexOfDocHashes[lastValue] = index1;

            _docHashes.pop();
            _indexOfDocHashes[data.docHash] = 0;

            delete _documents[name_];

            emit DocumentRemoved(name_, data.docURI, data.docHash);
        }
    }

    function getAllDocuments() public view virtual returns (bytes32[] memory) {
        return _docHashes;
    }

    /************************************************************************************************/

    /************************************ Token controllers *****************************************/
    function controllers() public view virtual returns (address[] memory) {
        return _controllers;
    }

    function setControllers(address[] calldata operators) public virtual {
        for (uint i = 0; i < _controllers.length; i++) {
            _isController[_controllers[i]] = false;
        }

        for (uint j = 0; j < operators.length; j++) {
            _isController[operators[j]] = true;
        }

        _controllers = operators;
    }

    /************************************************************************************************/

    /************************************* Operator Management **************************************/
    function authorizeOperator(address operator) public virtual {
        require(operator != msg.sender);

        _authorizedOperator[operator][msg.sender] = true;

        emit AuthorizedOperator(operator, msg.sender);
    }

    function revokeOperator(address operator) public virtual {
        require(operator != msg.sender);

        _authorizedOperator[operator][msg.sender] = false;

        emit RevokedOperator(operator, msg.sender);
    }

    function authorizeOperatorByPartition(
        bytes32 partition,
        address operator
    ) public virtual {
        _authorizedOperatorByPartition[msg.sender][partition][operator] = true;

        emit AuthorizedOperatorByPartition(partition, operator, msg.sender);
    }

    function revokeOperatorByPartition(
        bytes32 partition,
        address operator
    ) public virtual {
        _authorizedOperatorByPartition[msg.sender][partition][operator] = false;

        emit RevokedOperatorByPartition(partition, operator, msg.sender);
    }

    /************************************************************************************************/

    /************************************* Operator Information *************************************/
    function isOperator(
        address operator,
        address tokenHolder
    ) external view virtual returns (bool) {
        return _isOperator(operator, tokenHolder);
    }

    function isOperatorForPartition(
        bytes32 partition,
        address operator,
        address tokenHolder
    ) external view virtual returns (bool) {
        return _isOperatorForPartition(partition, operator, tokenHolder);
    }

    function _isOperator(
        address operator,
        address tokenHolder
    ) internal view returns (bool) {
        return (operator == tokenHolder ||
            _authorizedOperator[operator][tokenHolder] ||
            _isController[operator]);
    }

    function _isOperatorForPartition(
        bytes32 partition,
        address operator,
        address tokenHolder
    ) internal view returns (bool) {
        return (_isOperator(operator, tokenHolder) ||
            _authorizedOperatorByPartition[tokenHolder][partition][operator]);
    }

    /************************************************************************************************/

    /************************************** Token Information ***************************************/
    function balanceOfByPartition(
        bytes32 partition,
        address tokenHolder
    ) public view virtual returns (uint256) {
        return _balanceOfByPartition[tokenHolder][partition];
    }

    function partitionsOf(
        address tokenHolder
    ) public view virtual returns (bytes32[] memory) {
        return _partitionsOf[tokenHolder];
    }

    /************************************************************************************************/

    /******************************** Partition Token Allowances ************************************/
    function allowanceByPartition(
        bytes32 partition,
        address owner,
        address spender
    ) external view override returns (uint256) {
        return _allowed[owner][spender];
    }

    /************************************************************************************************/

    /****************************************** Transfers *******************************************/
    function transferWithData(
        address to,
        uint256 value,
        bytes calldata data
    ) public virtual {
        _transferByPartition(
            DEFAULT_PARTITION,
            msg.sender,
            msg.sender,
            to,
            value,
            data,
            ""
        );
    }

    function transferFromWithData(
        address from,
        address to,
        uint256 value,
        bytes calldata data
    ) public virtual {
        require(_allowed[from][msg.sender] >= value, "53"); // 0x53	insufficient allowance

        _allowed[from][msg.sender] -= value;
        _transferByPartition(
            DEFAULT_PARTITION,
            msg.sender,
            from,
            to,
            value,
            data,
            ""
        );
    }

    /************************************************************************************************/

    /********************************** Partition Token Transfers ***********************************/
    function transferByPartition(
        bytes32 partition,
        address to,
        uint256 value,
        bytes calldata data
    ) public virtual returns (bytes32) {
        return
            _transferByPartition(
                partition,
                msg.sender,
                msg.sender,
                to,
                value,
                data,
                ""
            );
    }

    function operatorTransferByPartition(
        bytes32 partition,
        address from,
        address to,
        uint256 value,
        bytes calldata data,
        bytes calldata operatorData
    ) public virtual returns (bytes32) {
        require(_isOperatorForPartition(partition, msg.sender, from), "58"); // 0x58	invalid operator (transfer agent)

        if (_isController[msg.sender]) {
            emit ControllerTransfer(
                msg.sender,
                from,
                to,
                value,
                data,
                operatorData
            );
        }

        return
            _transferByPartition(
                partition,
                msg.sender,
                from,
                to,
                value,
                data,
                operatorData
            );
    }

    /************************************************************************************************/

    /**************************************** Token Issuance ****************************************/
    function isIssuable() public view virtual returns (bool) {
        return _isIssuable;
    }

    function issue(
        address tokenHolder,
        uint256 value,
        bytes calldata data
    ) public virtual {
        _issueByPartition(
            DEFAULT_PARTITION,
            msg.sender,
            tokenHolder,
            value,
            data
        );
    }

    function issueByPartition(
        bytes32 partition,
        address tokenHolder,
        uint256 value,
        bytes calldata data
    ) public virtual {
        _issueByPartition(partition, msg.sender, tokenHolder, value, data);
    }

    /************************************************************************************************/

    /*************************************** Token Redemption ***************************************/
    function redeem(uint256 value, bytes calldata data) public virtual {
        _redeemByPartition(
            DEFAULT_PARTITION,
            msg.sender,
            msg.sender,
            value,
            data,
            ""
        );
    }

    function redeemFrom(
        address from,
        uint256 value,
        bytes calldata data
    ) public virtual {
        require(_allowed[from][msg.sender] >= value, "53"); // 0x53	insufficient allowance

        _allowed[from][msg.sender] -= value;
        _redeemByPartition(
            DEFAULT_PARTITION,
            msg.sender,
            from,
            value,
            data,
            ""
        );
    }

    function redeemByPartition(
        bytes32 partition,
        uint256 value,
        bytes calldata data
    ) public virtual {
        _redeemByPartition(partition, msg.sender, msg.sender, value, data, "");
    }

    function operatorRedeemByPartition(
        bytes32 partition,
        address tokenHolder,
        uint256 value,
        bytes calldata operatorData
    ) public virtual {
        require(
            _isOperatorForPartition(partition, msg.sender, tokenHolder),
            "58"
        ); // 0x58	invalid operator (transfer agent)

        if (_isController[msg.sender]) {
            emit ControllerRedemption(
                msg.sender,
                tokenHolder,
                value,
                "",
                operatorData
            );
        }

        _redeemByPartition(
            partition,
            msg.sender,
            tokenHolder,
            value,
            "",
            operatorData
        );
    }

    /************************************************************************************************/

    /************************************* Controller Operation *************************************/
    function isControllable() public view virtual returns (bool) {
        return true;
        // return _isController[msg.sender];
    }

    function controllerTransfer(
        address from,
        address to,
        uint256 value,
        bytes calldata data,
        bytes calldata operatorData
    ) public virtual {
        require(_isController[msg.sender], "58");

        _transferByPartition(
            DEFAULT_PARTITION,
            msg.sender,
            from,
            to,
            value,
            data,
            operatorData
        );

        emit ControllerTransfer(
            msg.sender,
            from,
            to,
            value,
            data,
            operatorData
        );
    }

    function controllerRedeem(
        address tokenHolder,
        uint256 value,
        bytes calldata data,
        bytes calldata operatorData
    ) public virtual {
        require(_isController[msg.sender], "58");

        _redeemByPartition(
            DEFAULT_PARTITION,
            msg.sender,
            tokenHolder,
            value,
            data,
            operatorData
        );

        emit ControllerRedemption(
            msg.sender,
            tokenHolder,
            value,
            data,
            operatorData
        );
    }

    /************************************************************************************************/

    /************************************************************************************************/
    /************************ Public Functions (ADDITIONAL - NOT MANDATORY) ***********************/
    /************************************************************************************************/

    /************************************ Token description *****************************************/
    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return 18;
    }

    function granularity() public pure returns (uint256) {
        return 1;
    }

    function totalPartitions() public view returns (bytes32[] memory) {
        return _totalPartitions;
    }

    function totalSupplyByPartition(
        bytes32 partition
    ) public view returns (uint256) {
        return _totalSupplyByPartition[partition];
    }

    /************************************************************************************************/

    /************************************************************************************************/
    /************************************* INTERNAL FUNCTIONS ***************************************/
    /************************************************************************************************/

    /**************************************** Token Transfers ***************************************/
    function _transferByPartition(
        bytes32 fromPartition,
        address operator,
        address from,
        address to,
        uint256 value,
        bytes memory data,
        bytes memory operatorData
    ) internal virtual returns (bytes32) {
        require(_balanceOfByPartition[from][fromPartition] >= value, "52"); // 0x52	insufficient balance
        require(to != address(0), "57"); // 0x57	invalid receiver

        bytes32 toPartition = fromPartition;

        if (operatorData.length != 0 && data.length >= 64) {
            toPartition = _getDestinationPartition(fromPartition, data);
        }

        _removeTokenFromPartition(from, fromPartition, value);
        _addTokenToPartition(to, toPartition, value);

        _balances[from] -= value;
        _balances[to] += value;

        emit Transfer(from, to, value); // ERC20 retrocompatibility
        emit TransferByPartition(
            fromPartition,
            operator,
            from,
            to,
            value,
            data,
            operatorData
        );

        if (toPartition != fromPartition) {
            emit ChangedPartition(fromPartition, toPartition, value);
        }

        return toPartition;
    }

    /**
     * @dev Retrieve the destination partition from the 'data' field.
     * By convention, a partition change is requested ONLY when 'data' starts
     * with the flag: 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
     * When the flag is detected, the destination tranche is extracted from the
     * 32 bytes following the flag.
     * @param fromPartition Partition of the tokens to transfer.
     * @param data Information attached to the transfer. [CAN CONTAIN THE DESTINATION PARTITION]
     * @return toPartition Destination partition.
     */
    function _getDestinationPartition(
        bytes32 fromPartition,
        bytes memory data
    ) internal pure returns (bytes32 toPartition) {
        bytes32 changePartitionFlag = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
        bytes32 flag;
        assembly {
            flag := mload(add(data, 32))
        }
        if (flag == changePartitionFlag) {
            assembly {
                toPartition := mload(add(data, 64))
            }
        } else {
            toPartition = fromPartition;
        }
    }

    function _removeTokenFromPartition(
        address from,
        bytes32 partition,
        uint256 value
    ) internal virtual {
        _balanceOfByPartition[from][partition] -= value;
        _totalSupplyByPartition[partition] -= value;

        // If the balance of the TokenHolder's partition is zero, finds and deletes the partition.
        if (_balanceOfByPartition[from][partition] == 0) {
            uint256 index2 = _indexOfPartitionsOf[from][partition];
            require(index2 > 0, "50"); // 0x50	transfer failure

            // move the last item into the index being vacated
            bytes32 lastValue = _partitionsOf[from][
                _partitionsOf[from].length - 1
            ];
            _partitionsOf[from][index2 - 1] = lastValue; // adjust for 1-based indexing
            _indexOfPartitionsOf[from][lastValue] = index2;

            _partitionsOf[from].pop();
            _indexOfPartitionsOf[from][partition] = 0;
        }
    }

    function _addTokenToPartition(
        address to,
        bytes32 partition,
        uint256 value
    ) internal {
        if (value != 0) {
            if (_indexOfPartitionsOf[to][partition] == 0) {
                _partitionsOf[to].push(partition);
                _indexOfPartitionsOf[to][partition] = _partitionsOf[to].length;
            }
            _balanceOfByPartition[to][partition] += value;

            if (_indexOfTotalPartitions[partition] == 0) {
                _totalPartitions.push(partition);
                _indexOfTotalPartitions[partition] = _totalPartitions.length;
            }
            _totalSupplyByPartition[partition] += value;
        }
    }

    /************************************************************************************************/

    /**************************************** Token Issuance ****************************************/
    function _issueByPartition(
        bytes32 toPartition,
        address operator,
        address to,
        uint256 value,
        bytes memory data
    ) internal virtual {
        require(_isIssuable, "50");
        require(to != address(0), "57"); // 0x57	invalid receiver

        _totalSupply += value;
        _balances[to] += value;

        _addTokenToPartition(to, toPartition, value);

        emit Issued(operator, to, value, data);
        emit Transfer(address(0), to, value); // ERC20 retrocompatibility
        emit IssuedByPartition(toPartition, operator, to, value, data, "");
    }

    /************************************************************************************************/

    /*************************************** Token Redemption ***************************************/
    function _redeemByPartition(
        bytes32 fromPartition,
        address operator,
        address from,
        uint256 value,
        bytes memory data,
        bytes memory operatorData
    ) internal virtual {
        require(_balanceOfByPartition[from][fromPartition] >= value, "52"); // 0x52	insufficient balance
        require(from != address(0), "56"); // 0x56	invalid sender

        _removeTokenFromPartition(from, fromPartition, value);

        _balances[from] -= value;
        _totalSupply -= value;

        emit Redeemed(operator, from, value, data);
        emit Transfer(from, address(0), value); // ERC20 retrocompatibility
        emit RedeemedByPartition(
            fromPartition,
            operator,
            from,
            value,
            operatorData
        );
    }
    /************************************************************************************************/
    function canTransfer(
        address to,
        uint256 value,
        bytes calldata data
    ) external view override returns (bytes1, bytes32) {}

    function canTransferFrom(
        address from,
        address to,
        uint256 value,
        bytes calldata data
    ) external view override returns (bytes1, bytes32) {}

    function canTransferByPartition(
        address from,
        address to,
        bytes32 partition,
        uint256 value,
        bytes calldata data
    ) external view override returns (bytes1, bytes32, bytes32) {}
}