// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../interfaces/IERC1400.sol";
import "./AOwnable.sol";

abstract contract AERC1400 is AOwnable, IERC1400 {
    /************************************* Token description ****************************************/
    string private _name;
    string private _symbol;
    uint256 private _totalSupply;
    uint256 internal _granularity;

    /**************************************** Token behaviours **************************************/
    bool internal _isControllable;
    bool internal _isIssuable;

    /********************************** ERC20 Token mappings ****************************************/
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) internal _allowed;

    /**************************************** Documents *********************************************/
    struct Doc {
        string docURI;
        bytes32 docHash;
        uint256 timestamp;
    }
    mapping(bytes32 => Doc) private _documents;
    mapping(bytes32 => uint256) private _indexOfDocHashes;
    bytes32[] private _docHashes;

    /*********************************** Partitions  mappings ***************************************/
    /*
     * @_totalPartitions : List of partitions
     * @_indexOfTotalPartitions : Mapping from partition to their index.
     * @_totalSupplyByPartition : Mapping from partition to global balance of corresponding partition.
     * @_partitionsOf : Mapping from tokenHolder to their partitions.
     * @_indexOfPartitionsOf : Mapping from (tokenHolder, partition) to their index.
     * @_balanceOfByPartition : Mapping from (tokenHolder, partition) to balance of corresponding partition.
     */
    bytes32[] private _totalPartitions;
    mapping(bytes32 => uint256) private _indexOfTotalPartitions;
    mapping(bytes32 => uint256) private _totalSupplyByPartition;
    mapping(address => bytes32[]) private _partitionsOf;
    mapping(address => mapping(bytes32 => uint256))
        private _indexOfPartitionsOf;
    mapping(address => mapping(bytes32 => uint256))
        private _balanceOfByPartition;

    bytes32 internal constant DEFAULT_PARTITION = "DEFAULT_PARTITION";

    /********************************* Global operators mappings ************************************/
    mapping(address => mapping(address => bool)) private _authorizedOperator;

    /**
     * @notice 변경
     * @dev 컨트롤러를 배열이 아닌 맵으로 관리, 컨트롤러에 대한 전체 목록은 확인하지 않음
     */
    mapping(address => bool) _controllers;
    // address[] private _controllers;
    // mapping(address => bool) private _isController;

    /******************************** Partition operators mappings **********************************/
    // Mapping from (partition, tokenHolder, spender) to allowed value.
    mapping(bytes32 => mapping(address => mapping(address => uint256)))
        internal _allowedByPartition;

    // Mapping from (tokenHolder, partition, operator) to 'approved for partition' status.
    mapping(address => mapping(bytes32 => mapping(address => bool)))
        private _authorizedOperatorByPartition;

    /**
     * @notice 삭제
     * @dev 컨트롤러는 전체 파티션에 대한 접근 권한 가지므로 필요 없음
     */
    // mapping(bytes32 => address[]) internal _controllersByPartition;
    // mapping(bytes32 => mapping(address => bool)) internal _isControllerByPartition;

    /***************************************** Modifiers ********************************************/
    /**
     * @notice 추가
     * @dev isControllable 및 controller 여부 확인을 위한 공통 modifier
     */
    modifier isTokenControllable(address controller) {
        if (!_isControllable || !_controllers[controller])
            revert InvalidController("already registered controller");
        _;
    }

    // modifier isIssuableToken() {}
    // modifier isNotMigratedToken() {}
    // modifier onlyMinter() override {}

    /**************************** Events (additional - not mandatory) *******************************/
    event ApprovalByPartition(
        bytes32 indexed partition,
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    /**
     * @notice 추가
     * @dev approve된 내역이 취소 또는 사용되었을 경우, 얼만큼이 사용되었는지 표현하기 위한 이벤트
     */
    event WithdrawalByPartition(
        bytes32 indexed partition,
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    /**************************************** Constructor *******************************************/
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 granularity_,
        bool isIssuable_
    ) AOwnable() {
        _name = name_;
        _symbol = symbol_;

        if (granularity_ < 1)
            revert InvalidParameter("granularity can not be lower than 1");
        _granularity = granularity_;

        _controllers[msg.sender] = true;
        _isIssuable = isIssuable_;
    }

    /****************************** EXTERNAL FUNCTIONS (ERC20 INTERFACE) ****************************/
    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

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
        if (spender == address(0))
            revert InvalidSender("spender assigned to zero address");
        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public virtual returns (bool) {
        if (_allowed[from][msg.sender] < value)
            revert InsufficientAllowance(
                "value assigned more than allowance",
                _allowed[from][msg.sender],
                value
            );

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

    /**
     * @notice 변경
     * @dev 컨트롤러 관리 형태 변경에 따른 소스 수정 (_isController -> _controllers)
     */
    function setDocument(
        bytes32 name_,
        string calldata uri,
        bytes32 documentHash
    ) public virtual isTokenControllable {
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

    /**
     * @notice 변경
     * @dev 컨트롤러 관리 형태 변경에 따른 소스 수정 (_isController -> _controllers)
     */
    function removeDocument(bytes32 name_) public virtual isTokenControllable {
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

    /**
     * Token Information
     */
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
        if (
            _isOperator(msg.sender, from) || _allowed[from][msg.sender] >= value
        ) {
            _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
            _transferByPartition(
                DEFAULT_PARTITION,
                msg.sender,
                from,
                to,
                value,
                data,
                ""
            );
        } else {
            if (!_isOperator(msg.sender, from))
                revert InvalidOperator(
                    "contract caller is not operator for sender"
                );
            if (_allowed[from][msg.sender] < value)
                revert InsufficientAllowance(
                    "value assigned more than allowance",
                    _allowed[from][msg.sender],
                    value
                );
        }
    }

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

    function operatorTransferFromByPartition(
        bytes32 partition,
        address from,
        address to,
        uint256 value,
        bytes calldata data,
        bytes calldata operatorData
    ) public virtual returns (bytes32) {
        if (!_isOperatorForPartition(partition, msg.sender, from))
            revert InvalidOperator(
                "contract caller is not operator for sender of requested partition"
            );

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

    /************************************* Controller Operation *************************************/
    function isControllable() public view virtual returns (bool) {
        return _isControllable;
    }

    /************************************* Operator Management **************************************/
    function authorizeOperator(address operator) public virtual {
        if (operator == msg.sender)
            revert InvalidOperator("contract caller cannot be operator");
        _authorizedOperator[operator][msg.sender] = true;
        emit AuthorizedOperator(operator, msg.sender);
    }

    function revokeOperator(address operator) public virtual {
        if (operator == msg.sender)
            revert InvalidOperator("contract caller cannot be operator");
        _authorizedOperator[operator][msg.sender] = false;
        emit RevokedOperator(operator, msg.sender);
    }

    function authorizeOperatorByPartition(
        bytes32 partition,
        address operator
    ) public virtual {
        if (operator == msg.sender)
            revert InvalidOperator("contract caller cannot be operator");
        _authorizedOperatorByPartition[msg.sender][partition][operator] = true;
        emit AuthorizedOperatorByPartition(partition, operator, msg.sender);
    }

    function revokeOperatorByPartition(
        bytes32 partition,
        address operator
    ) public virtual {
        if (operator == msg.sender)
            revert InvalidOperator("contract caller cannot be operator");
        _authorizedOperatorByPartition[msg.sender][partition][operator] = false;
        emit RevokedOperatorByPartition(partition, operator, msg.sender);
    }

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
        if (_allowed[from][msg.sender] < value)
            revert InsufficientAllowance(
                "value assigned more than allowance",
                _allowed[from][msg.sender],
                value
            );

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

    /**
     * @notice 변경
     * @dev UniversalToken 및 기존 방식
     *      - allowedByPartition과 상관없이 value만큼 redeem
     *      - 얼마가 allowed 되어있는지 상관없이 잔액(balance)보다 크지만 않으면 value를 무조건 redeem하는 방식
     *      - 그러면 잔액을 먼저 확인한 후 redeem이 완료되면 파티션 내 allowed된 값을 변경해야 할 것으로 생각
     *      - _redeemByPartition 호출 위치 변경 필요
     */
    function operatorRedeemByPartition(
        bytes32 partition,
        address tokenHolder,
        uint256 value,
        bytes calldata operatorData
    ) public virtual {
        if (!_isOperatorForPartition(partition, msg.sender, tokenHolder))
            revert InvalidOperator(
                "contract caller is not operator for this partition"
            );

        if (_allowedByPartition[partition][tokenHolder][msg.sender] >= value) {
            _allowedByPartition[partition][tokenHolder][msg.sender] -= value;
        } else {
            _allowedByPartition[partition][tokenHolder][msg.sender] = 0;
        }

        // 얼마가 allowed 되어있는지 상관없이 잔액(balance)보다 크지만 않으면 value를 무조건 redeem하는 방식
        _redeemByPartition(
            partition,
            msg.sender,
            tokenHolder,
            value,
            "",
            operatorData
        );
    }

    /************************ EXTERNAL FUNCTIONS (ADDITIONAL - NOT MANDATORY) ***********************/

    /************************************ Token description *****************************************/
    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return uint8(18); // changed 18 to uint8(18)
    }

    function granularity() public pure returns (uint256) {
        return _granularity; // changed 1 to _granularity
    }

    function totalPartitions() public view returns (bytes32[] memory) {
        return _totalPartitions;
    }

    function totalSupplyByPartition(
        bytes32 partition
    ) public view returns (uint256) {
        return _totalSupplyByPartition[partition];
    }

    /**************************************** Token behaviours **************************************/
    /**
     * @notice 삭제
     * @dev 컨트롤러는 고정적으로 사용
     */
    // function renounceControl() external onlyOwner {}

    /**
     * @notice 삭제
     * @dev 토큰의 발행은 무조건 최초 1번은 실행되며, 이후 추가발행 여부는 스마트 컨트랙프 배포 단계에서 설정
     *           만약 추가발행이 비활성화 되어있다면, 최초 발행 이후 스마트 컨트랙트 상에서 issuable 비활성화
     *           그러므로 스마트 컨트랙트 상에서 최초 설정 이후 발행 가능 여부를 설정하는 시나리오를 현재는 고려하지 않음
     */
    // function renounceIssuance() external onlyOwner {}

    /************************************ Token controllers *****************************************/
    /**
     * @notice 삭제
     * @dev 컨트롤러 목록을 배열에서 맵 형태로 변환함에 따라 해당 함수 불필요
     */
    // function controllers() external view returns (address[] memory) {}

    /**
     * @notice 삭제
     * @dev 컨트롤러는 모든 파티션에 대하여 권한을 갖기 때문에, 해당 함수 불필요
     */
    // function controllersByPartition(bytes32 partition) external view returns (address[] memory) {}

    /**
     * @notice 변경
     * @dev 토큰 컨트롤러 목록 저장
     *      UniversalToken과 다르게 본 시나리오에서는 스마트 컨트랙프 배포시 배포주소만 컨트롤러에 등록
     *      향후 추가 컨트롤러 저장을 원할 경우 무조건 배열 형태로 전달하도록 설정
     */
    function setControllers(
        address[] calldata operators
    ) public virtual onlyOwner {
        for (uint i = 0; i < operators.length; i++) {
            _controllers[operators[i]] = true;
        }
    }

    /**
     * @notice 추가
     * @dev 컨트롤러 삭제(false 처리)
     *      결을 맞추기 위해 목록으로 전달한 후 일괄 처리
     */
    function setControllers(
        address[] calldata operators
    ) public virtual onlyOwner {
        for (uint i = 0; i < operators.length; i++) {
            _controllers[operators[i]] = false;
        }
    }

    /**
     * @notice 삭제
     * @dev 컨트롤러는 모든 파티션에 대하여 권한을 갖기 때문에, 해당 함수 불필요
     */
    // function setPartitionControllers(bytes32 partition, address[] calldata operators) external onlyOwner {}

    /********************************* Token default partitions *************************************/

    /**
     * @notice 삭제
     * @dev Default Partition은 하나로 고정하며, 상수 값으로 전달 (DEFAULT_PARTITION)
     */
    // function getDefaultPartitions() external view returns (bytes32[] memory) {}

    /**
     * @notice 삭제
     * @dev Default Partition은 하나로 고정하며, 향후 변경되지 않음
     */
    // function setDefaultPartitions(bytes32[] calldata partitions) external onlyOwner {}

    /******************************** Partition Token Allowances ************************************/

    function allowanceByPartition(
        bytes32 partition,
        address owner,
        address spender
    ) external view returns (uint256) {
        return _allowedByPartition[partition][owner][spender];
    }

    function approveByPartition(
        bytes32 partition,
        address spender,
        uint256 value
    ) external returns (bool) {
        if (spender == address(0))
            revert InvalidSender("spender assigned to zero address");

        _allowedByPartition[partition][msg.sender][spender] = value;
        emit ApprovalByPartition(partition, msg.sender, spender, value);
        return true;
    }

    /**
     * @notice 추가
     * @dev approve된 내역이 취소된 경우 (이름을 cancelApproved로 변경할지 고민)
     */
    function withdrawByPartition(
        bytes32 partition,
        address spender,
        uint256 value
    ) external returns (bool) {
        if (spender == address(0))
            revert InvalidSender("spender assigned to zero address");

        if (_allowedByPartition[partition][msg.sender][spender] > value) {
            _allowedByPartition[partition][msg.sender][spender] -= value;
        } else {
            _allowedByPartition[partition][msg.sender][spender] = 0;
        }
        emit WithdrawalByPartition(partition, msg.sender, spender, value);
        return true;
    }

    /************************************** Token extension *****************************************/

    /**
     * @notice 삭제
     * @dev 현재 비지니스 요건상 불필요하며, 향후 필요시 개발
     */
    // function setTokenExtension(
    //     address extension,
    //     string calldata interfaceLabel,
    //     bool removeOldExtensionRoles,
    //     bool addMinterRoleForExtension,
    //     bool addControllerRoleForExtension
    // ) external onlyOwner {}

    /************************************* Token migration ******************************************/

    /**
     * @notice 삭제
     * @dev 현재 비지니스 요건상 불필요하며, 향후 필요시 개발
     */
    // function migrate(address newContractAddress, bool definitive) external onlyOwner {}

    /************************************* INTERNAL FUNCTIONS ***************************************/

    /**************************************** Token Transfers ***************************************/

    /**
     * @notice 삭제
     * @dev internal 함수로 굳이 분리할 필요 없음
     */
    // function _transferWithData(address from, address to, uint256 value) {}

    /**
     * @notice 변경
     * @dev _transferWithData 함수의 삭제로 인한 내부 로직 일부 변경
     */
    function _transferByPartition(
        bytes32 fromPartition,
        address operator,
        address from,
        address to,
        uint256 value,
        bytes memory data,
        bytes memory operatorData
    ) internal virtual returns (bytes32) {
        if (to == address(0))
            revert InvalidReceiver("to assigned to zero address");

        if (_balanceOfByPartition[from][fromPartition] < value)
            revert InsufficientBalance(
                "value assigned more than from balance",
                _balanceOfByPartition[from][fromPartition],
                value
            );

        bytes32 toPartition = fromPartition;

        if (operatorData.length != 0 && data.length >= 64) {
            toPartition = _getDestinationPartition(fromPartition, data);
        }

        // _callSenderExtension() 삭제
        // _callTokenExtension() 삭제

        _removeTokenFromPartition(from, fromPartition, value);
        // _transferWithData() 함수에 직접 구현
        _addTokenToPartition(to, toPartition, value);

        _balances[from] -= value;
        _balances[to] += value;

        emit Transfer(from, to, value); // 필요한 부분일까?
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
     * @notice 삭제
     * @dev Default Partition이 하나로 고정 -> _transferByPartition 함수로 처리 가능
     */
    // function _transferByDefaultPartitions(address operator, address from, address to, uint256 value, bytes memory data) {}

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

    /**
     * @notice 변경
     * @dev if (_totalSupplyByPartition[partition] == 0) => 파티션 삭제 내용 제거
     */
    function _removeTokenFromPartition(
        address from,
        bytes32 partition,
        uint256 value
    ) internal virtual {
        _balanceOfByPartition[from][partition] -= value;
        _totalSupplyByPartition[partition] -= value;

        /**
         * @dev UniversalToken에서는 특정 파티션 내 토큰이 0이면 (_totalSupplyByPartition[partition] == 0)
         *      해당 파티션을 삭제하도록 되어있으나, 파티션을 굳이 삭제해야 하는가에 대해서는 의문
         *      그래서 해당 내용은 toy-project와 동일하게 '포함하지 않으며' 향후 비지니스에 따라 추가
         */
        // If the total supply is zero, finds and deletes the partition.
        // if (_totalSupplyByPartition[partition] == 0) {...}

        // If the balance of the TokenHolder's partition is zero, finds and deletes the partition.
        if (_balanceOfByPartition[from][partition] == 0) {
            uint256 index = _indexOfPartitionsOf[from][partition];
            if (index <= 0)
                revert InvalidPartitionIndex("partition index unrecognized");

            // move the last item into the index being vacated
            bytes32 lastValue = _partitionsOf[from][
                _partitionsOf[from].length - 1
            ];
            _partitionsOf[from][index - 1] = lastValue; // adjust for 1-based indexing
            _indexOfPartitionsOf[from][lastValue] = index;

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

    /**
     * @notice 삭제
     * @dev 기본적으로 granularity를 1로 가져갈 것이므로, 해당 함수 사용이 없을 것으로 판단
     */
    // function _isMultiple(uint256 value) internal view returns (bool) {}

    /****************************************** Hooks ***********************************************/

    /**
     * @notice 삭제
     * @dev 현재 비지니스 요건상 불필요하며, 향후 필요시 개발
     */
    // function _callSenderExtension(
    //     bytes32 partition,
    //     address operator,
    //     address from,
    //     address to,
    //     uint256 value,
    //     bytes memory data,
    //     bytes memory operatorData
    // ) internal {}

    /**
     * @notice 삭제
     * @dev 현재 비지니스 요건상 불필요하며, 향후 필요시 개발
     */
    // function _callTokenExtension(
    //     bytes32 partition,
    //     address operator,
    //     address from,
    //     address to,
    //     uint256 value,
    //     bytes memory data,
    //     bytes memory operatorData
    // ) internal {}

    /**
     * @notice 삭제
     * @dev 현재 비지니스 요건상 불필요하며, 향후 필요시 개발
     */
    // function _callRecipientExtension(
    //     bytes32 partition,
    //     address operator,
    //     address from,
    //     address to,
    //     uint256 value,
    //     bytes memory data,
    //     bytes memory operatorData
    // ) internal virtual {}

    /************************************* Operator Information *************************************/

    /**
     * @notice 변경
     * @dev controller 확인 부분 변경(isController 사용 안함, _controllers에서 바로 조회)
     */
    function _isOperator(
        address operator,
        address tokenHolder
    ) internal view returns (bool) {
        return (operator == tokenHolder ||
            _authorizedOperator[operator][tokenHolder] ||
            (_isControllable && _controllers[operator]));
    }

    /**
     * @notice 변경
     * @dev controller 확인 부분 변경(isController 사용 안함, _controllers에서 바로 조회)
     */
    function _isOperatorForPartition(
        bytes32 partition,
        address operator,
        address tokenHolder
    ) internal view returns (bool) {
        return (_isOperator(operator, tokenHolder) ||
            _authorizedOperatorByPartition[tokenHolder][partition][operator] ||
            (_isControllable && _controllers[operator]));
    }

    /**************************************** Token Issuance ****************************************/

    /**
     * @notice 삭제
     * @dev _issueByPartition으로 대체 가능
     */
    // function _issue(address operator, address to, uint256 value, bytes memory data) {}

    /**
     * @notice 변경
     * @dev migrate 사용 안함 -> isNotMigratedToken 기능 사용 삭제
     *
     */
    function _issueByPartition(
        bytes32 toPartition,
        address operator,
        address to,
        uint256 value,
        bytes memory data
    ) internal {
        // _callTokenExtension() 삭제
        if (!_isIssuable) revert InvalidRequest("contract is unissuable");
        if (to == address(0))
            revert InvalidReceiver("to assigned to zero address");

        _totalSupply += value;
        _balances[to] += value;

        _addTokenToPartition(to, toPartition, value);

        emit Issued(operator, to, value, data); // 필요한 부분일까?
        emit Transfer(address(0), to, value);
        emit IssuedByPartition(toPartition, operator, to, value, data, "");
    }

    /*************************************** Token Redemption ***************************************/

    /**
     * @notice 삭제
     * @dev _redeemByPartition으로 대체 가능
     */
    // function _redeem(address operator, address from, uint256 value, bytes memory data) {}

    function _redeemByPartition(
        bytes32 fromPartition,
        address operator,
        address from,
        uint256 value,
        bytes memory data,
        bytes memory operatorData
    ) internal virtual {
        if (_balanceOfByPartition[from][fromPartition] < value)
            revert InsufficientBalance(
                "value assigned more than from balance",
                _balanceOfByPartition[from][fromPartition],
                value
            );

        // _callSenderExtension() 삭제
        // _callTokenExtension() 삭제

        if (from == address(0))
            revert InvalidSender("spender assigned to zero address");

        _removeTokenFromPartition(from, fromPartition, value);

        _balances[from] -= value;
        _totalSupply -= value;

        emit Redeemed(operator, from, value, data);
        emit Transfer(from, address(0), value);
        emit RedeemedByPartition(
            fromPartition,
            operator,
            from,
            value,
            operatorData
        );
    }

    /**
     * @notice 삭제
     * @dev _redeemByPartition으로 대체 가능
     */
    // function _redeemByDefaultPartitions(address operator, address from, uint256 value, bytes memory data) {}

    /************************************** Transfer Validity ***************************************/
    /**
     * @notice 삭제
     * @dev verifier 부분은 AERC1400Verifiable에서 처리
     */
    // function _canTransfer(
    //     bytes memory payload,
    //     bytes32 partition,
    //     address operator,
    //     address from,
    //     address to,
    //     uint256 value,
    //     bytes memory data,
    //     bytes memory operatorData
    // ) internal view returns (bytes1, bytes32, bytes32) {}

    /************************ INTERNAL FUNCTIONS (ADDITIONAL - NOT MANDATORY) ***********************/
    /************************************ Token controllers *****************************************/

    /**
     * @notice 삭제
     * @dev internal 함수로 굳이 분리할 필요 없음
     */
    // function _setControllers(address[] memory operators) internal {}

    /**
     * @notice 삭제
     * @dev 컨트롤러는 모든 파티션에 대하여 권한을 갖기 때문에, 해당 함수 불필요
     */
    // function _setPartitionControllers(bytes32 partition, address[] memory operators) internal {}

    /************************************** Token extension *****************************************/

    /**
     * @notice 삭제
     * @dev 현재 비지니스 요건상 불필요하며, 향후 필요시 개발
     */
    // function _setTokenExtension(
    //     address extension,
    //     string memory interfaceLabel,
    //     bool removeOldExtensionRoles,
    //     bool addMinterRoleForExtension,
    //     bool addControllerRoleForExtension
    // ) internal {}

    /************************************* Token migration ******************************************/
    /**
     * @notice 삭제
     * @dev 현재 비지니스 요건상 불필요하며, 향후 필요시 개발
     */
    // function _migrate(address newContractAddress, bool definitive) internal {}

    /************************************* Domain Aware ******************************************/
    /**
     * @notice 삭제
     * @dev 현재 비지니스 요건상 불필요하며, 향후 필요시 개발
     */
    // function domainName() public view override returns (string memory) {}

    /**
     * @notice 삭제
     * @dev 현재 비지니스 요건상 불필요하며, 향후 필요시 개발
     */
    // function domainVersion() public pure override returns (string memory) {}

    /*
     * Controller functions (newly added)
     */

    function controllerTransfer(
        address from,
        address to,
        uint256 value,
        bytes calldata data,
        bytes calldata operatorData
    ) public virtual {
        if (!_controllers[msg.sender])
            revert InvalidController("contract caller is not controller");

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
            DEFAULT_PARTITION,
            msg.sender,
            from,
            to,
            value,
            data,
            operatorData
        );
    }

    function controllerTransferByPartition(
        bytes32 partition,
        address from,
        address to,
        uint256 value,
        bytes calldata data,
        bytes calldata operatorData
    ) public virtual {
        if (!_controllers[msg.sender])
            revert InvalidController("contract caller is not controller");

        _transferByPartition(
            partition,
            msg.sender,
            from,
            to,
            value,
            data,
            operatorData
        );

        emit ControllerTransfer(
            partition,
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
        if (!_controllers[msg.sender])
            revert InvalidController("contract caller is not controller");

        _redeemByPartition(
            DEFAULT_PARTITION,
            msg.sender,
            tokenHolder,
            value,
            data,
            operatorData
        );

        emit ControllerRedemption(
            DEFAULT_PARTITION,
            msg.sender,
            tokenHolder,
            value,
            data,
            operatorData
        );
    }

    function controllerRedeemByPartition(
        bytes32 partition,
        address tokenHolder,
        uint256 value,
        bytes calldata data,
        bytes calldata operatorData
    ) public virtual {
        if (!_controllers[msg.sender])
            revert InvalidController("contract caller is not controller");

        _redeemByPartition(
            partition,
            msg.sender,
            tokenHolder,
            value,
            data,
            operatorData
        );

        emit ControllerRedemption(
            partition,
            msg.sender,
            tokenHolder,
            value,
            data,
            operatorData
        );
    }

    /************************************* INTERNAL FUNCTIONS ***************************************/

    /**************************************** Token Transfers ***************************************/

    /*
     * Token Issuance
     */
    function _issueByPartition(
        bytes32 toPartition,
        address operator,
        address to,
        uint256 value,
        bytes memory data
    ) internal virtual onlyOwner {
        if (!_isIssuable) revert InvalidRequest("contract is unissuable");
        if (to == address(0))
            revert InvalidReceiver("to assigned to zero address");

        _totalSupply += value;
        _balances[to] += value;

        _addTokenToPartition(to, toPartition, value);

        emit Issued(operator, to, value, data);
        emit Transfer(address(0), to, value); // ERC20 retrocompatibility
        emit IssuedByPartition(toPartition, operator, to, value, data, "");
    }

    /*
     * Token Redemption
     */
    function _redeemByPartition(
        bytes32 fromPartition,
        address operator,
        address from,
        uint256 value,
        bytes memory data,
        bytes memory operatorData
    ) internal virtual {
        if (_balanceOfByPartition[from][fromPartition] < value)
            revert InsufficientBalance(
                "value assigned more than from balance",
                _balanceOfByPartition[from][fromPartition],
                value
            );

        if (from == address(0))
            revert InvalidSender("spender assigned to zero address");

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

    // /*
    //  * Transfer Validity
    //  */
    // function canTransfer(
    //     address to,
    //     uint256 value,
    //     bytes calldata data
    // ) external view virtual returns (bytes1, bytes32);

    // function canTransferFrom(
    //     address from,
    //     address to,
    //     uint256 value,
    //     bytes calldata data
    // ) external view virtual returns (bytes1, bytes32);

    // function canTransferByPartition(
    //     address from,
    //     address to,
    //     bytes32 partition,
    //     uint256 value,
    //     bytes calldata data
    // ) external view virtual returns (bytes1, bytes32, bytes32);
    // /************************************************************************************************/

    /************************ INTERNAL FUNCTIONS (ADDITIONAL - NOT MANDATORY) ***********************/

    /**
     * @notice 컨트롤러의
     * @dev Set list of token controllers.
     */
    function _setControllers(address[] memory operators) internal {
        for (uint i = 0; i < _controllers.length; i++) {
            _isController[_controllers[i]] = false;
        }
        for (uint j = 0; j < operators.length; j++) {
            _isController[operators[j]] = true;
        }
        _controllers = operators;
    }
}

/*
 * Custom Errors
 */
error InvalidParameter(string errorMsg);
error InvalidController(string errorMsg);
error InvalidOperator(string errorMsg);
error InvalidPartition(string errorMsg);
// error InvalidOperator(string errorMsg);
// error InvalidPartitionIndex(string errorMsg);
error InvalidRequest(string errorMsg);

// error ErrorByController(string message);
// error ErrorByOperator(string message);
// error ErrorByParameter(string message);
