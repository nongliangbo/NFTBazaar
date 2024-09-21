//ERC721.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;
import "./interface/IERC721.sol";
import "./interface/IERC721Metadata.sol";
import "./interface/IERC721Receiver.sol";
import "./interface/IERC165.sol";

contract ERC721 is IERC721, IERC721Metadata {
    string constant TOKEN_HAS_MINT = "EX003003";
    string constant IS_ZERO_ADDR = "EX003004";
    string constant NOT_VALID_NFT = "EX003005";
    string constant NOT_EMPTY = "EX003006";
    string constant NOT_OWNER = "EX003007";
    string constant TOKEN_NO_EXIST = "EX003008";
    string constant IS_OWNER = "EX003009";

    // 错误 无效的接收者
    error ERC721InvalidReceiver(address receiver);

    // Token名称
    string public _name;
    // Token代号
    string public _symbol;

    // tokenId 到 owner address 的持有人映射
    mapping(uint256 => address) private _owners;

    // address 到 持仓数量 的持仓量映射
    mapping(address => uint256) private _balances;

    // tokenID 到 授权地址 的授权映射
    mapping(uint256 => address) private _tokenApprovals;

    //  owner地址。到operator地址 的批量授权映射
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    modifier CHECK_ONWER(address addr, uint256 tokenId) {
        require(addr == _owners[tokenId], NOT_OWNER);
        _;
    }

    modifier CHECK_TO(address to) {
        require(to != address(0), NOT_EMPTY);
        _;
    }

    modifier CEHCK_TOKEN(uint256 _tokenId) {
        require(_owners[_tokenId] != address(0), NOT_VALID_NFT);
        _;
    }

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /* 支持的类型 */
    function supportsInterface(
        bytes4 interfaceId
    ) external view override returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId;
    }

    /* 查余额 */
    function balanceOf(
        address owner
    ) external view override returns (uint256 balance) {
        require(owner != address(0), NOT_OWNER);
        return _balances[owner];
    }

    //利用_owners变量查询tokenId的owner。
    function ownerOf(
        uint256 tokenId
    ) public view override returns (address owner) {
        owner = _owners[tokenId];
        require(owner != address(0), TOKEN_NO_EXIST);
    }

    /*
     * 判断当前调用是否是授权者或者所有者
     */
    function _isApprovedOrOwner(
        address owner,
        address applyer,
        uint256 tokenId
    ) internal view returns (bool) {
        return (applyer == owner ||
            _tokenApprovals[tokenId] == applyer ||
            _operatorApprovals[owner][applyer]);
    }

    //转移资产， 通过onwer从to转移资产到from 资产ID是tokenId
    function _transfer(
        address owner,
        address from,
        address to,
        uint256 tokenId
    ) internal {
        //TODO 为什么要放这里
        //查询 spender地址是否可以使用tokenId（需要是owner或被授权地址）
        _isApprovedOrOwner(owner, msg.sender, tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    //安全的转移资产
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external override {
        //发送者是当前合约所有者，或者已授权的用户，
        //如果是to是0地址则抛出异常
        //如果tokenid 不存在则抛出异常
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    )
        external
        override
        CHECK_ONWER(from, tokenId)
        CHECK_TO(to)
        CEHCK_TOKEN(tokenId)
    {
        //不能自己给自己转
        require(to != _owners[tokenId], IS_OWNER);

        _transfer(_owners[tokenId], from, to, tokenId);
        //校验收方是有能力接收NFT的合约
        _checkOnERC721Received(from, to, tokenId, "");
    }

    // _checkOnERC721Received：函数，用于在 to 为合约的时候调用IERC721Receiver-onERC721Received, 以防 tokenId 被不小心转入黑洞。
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private {
        if (to.code.length > 0) {
            try
                IERC721Receiver(to).onERC721Received(
                    msg.sender,
                    from,
                    tokenId,
                    data
                )
            returns (bytes4 retval) {
                if (retval != IERC721Receiver.onERC721Received.selector) {
                    revert ERC721InvalidReceiver(to);
                }
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert ERC721InvalidReceiver(to);
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        }
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external override {}

    //授权，当有其他人授权的时候，会替换掉当前的用户
    function approve(address to, uint256 tokenId) external override {
        //通过tokenId 找到拥有人
        address owner = _owners[tokenId];
        //只用onwer和全局代理者允许调用授权方法
        require(
            msg.sender == owner || _operatorApprovals[owner][msg.sender],
            IS_OWNER
        );
        //授权。把tokenId的授权地址设为to
        _tokenApprovals[tokenId] = to;

        emit Approval(owner, to, tokenId);
    }

    //全局授权，允许操作员转移所有者的任何代币
    function setApprovalForAll(
        address operator,
        bool _approved
    ) external override {
        //按用户地址映射，把onwer对应的操作者置为true
        _operatorApprovals[msg.sender][operator] = _approved;
    }

    // 查询授权，只允许onwer
    function getApproved(
        uint256 tokenId
    ) external view override returns (address operator) {
        require(_owners[tokenId] != address(0), TOKEN_NO_EXIST);
        operator = _tokenApprovals[tokenId];
    }

    //判断是否全部授权给了operator
    function isApprovedForAll(
        address owner,
        address operator
    ) external view override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function name() external view override returns (string memory) {
        return _name;
    }

    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    function tokenURI(
        uint256 _tokenId
    ) external view override returns (string memory) {
        string memory baseURI = _baseURI();
        return baseURI;
    }

    //允许子合约重写
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    //铸造
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), IS_ZERO_ADDR);
        require(_owners[tokenId] == address(0), TOKEN_HAS_MINT);

        _owners[tokenId] = to;
        _balances[to] += 1;
        emit Transfer(address(0), to, tokenId);
    }

    //销毁
    function _burn(uint256 tokenId) internal virtual {
        //校验是否是onwer
        address owner = ownerOf(tokenId);
        require(owner == msg.sender, NOT_OWNER);

        //设置映射为空
        _tokenApprovals[tokenId] = address(0);
        //语义等同delete _owners[tokenId]; 与下述代码不同的是会删除占用的空间
        _owners[tokenId] = address(0);

        _balances[owner] -= 1;
        emit Transfer(owner, address(0), tokenId);

    }
}
