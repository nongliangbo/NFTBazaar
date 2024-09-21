// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import "./interface/IERC721Receiver.sol";
import "./interface/IERC721.sol";

contract NFTSWAP is IERC721Receiver {
    event List(
        address indexed seller,
        address indexed nftAddr,
        uint256 indexed tokenId,
        uint256 price
    );

    event Buy(
        address indexed buyer,
        address indexed nftAddr,
        uint256 indexed tokenId,
        uint256 price
    );

    event Cancel(
        address indexed seller,
        address indexed nftAddr,
        uint256 indexed tokenId
    );

    event Log(string);

    //交易所mark订单的onwer以及发布的价格
    struct Order {
        address onwer;
        uint price;
    }

    //合约地址 to onwer to Order
    mapping(address => mapping(uint => Order)) public nftList;

    constructor() {}

    receive() external payable {}

    function onERC721Received(
        address operator,
        address from,
        uint tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    //挂单，调用方为卖家，可以理解成token的拥有者
    function list(address nftAddr, uint tokenId, uint price) public {
        //代币所属的合约
        IERC721 _nft = IERC721(nftAddr);
        //判断market合约是否已经授权
        require(_nft.getApproved(tokenId) == address(this), "Not approved");
        require(price > 0, "Price must be greater than 0");

        Order memory order = Order(msg.sender, price);
        emit  Log("111111");

        nftList[nftAddr][tokenId] = order;
        emit  Log("222222");


        //从nft合约地址转移到当前交易所合约地址
        _nft.safeTransferFrom(msg.sender, address(this), tokenId);

        emit List(msg.sender, nftAddr, tokenId, price);
    }

    //购买
    //买家通过nftAddr购买tokenId 调用方为买家
    function buy(address nftAddr, uint tokenId) public payable {
        Order memory order = nftList[nftAddr][tokenId];

        //将nft从交易所转移到买家地址
        IERC721(nftAddr).safeTransferFrom(address(this), msg.sender, tokenId);

        //将钱从买家地址转移到卖家地址
        (bool success, ) = payable(order.onwer).call{value: order.price}("");
        //多余的钱退回给买家
        (bool _success, ) = msg.sender.call{value: msg.value - order.price}("");

        require(success, "Transfer failed1");
        require(_success, "Transfer failed2");
        delete nftList[nftAddr][tokenId];
    }

    //取消挂单
    function cancel(address nftAddr, uint tokenId) public {
        //必须由卖家取消
        require(nftList[nftAddr][tokenId].onwer == msg.sender, "Not owner");

        //市场合约必须拥有合约
        require(
            IERC721(nftAddr).ownerOf(tokenId) == address(this),
            "NFTSWAP not have this nft"
        );

        //把合约权限转交给卖家
        IERC721(nftAddr).approve(msg.sender, tokenId);

        //删除关联关系
        delete nftList[nftAddr][tokenId];

        //事件
        emit Cancel(msg.sender, nftAddr, tokenId);
    }

    //调整价格
}
