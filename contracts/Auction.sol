// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Auction is ERC721Enumerable, Ownable {
    string private _actionBaseURI;

    struct Card {
        string nameOfCard;
        uint256 from; // ngay bat dau
        uint256 to; // ngay ket thuc
        uint256 highestBid; // gia cao nhat tai 1 thoi diem
        address addressOfHighestBid; // dia chi cua ng co gia cao nhat
        address owner; // dia chi cua nguoi so huu
        uint256 reserveBid; //gia khoi diem
        uint256 stepBid; //tong so tien trong phien dau gia
        bool endAuction; //tong so tien trong phien dau gia
        bool userConfirmed; //tong so tien trong phien dau gia
        bool ownerConfirmed; //tong so tien trong phien dau gia
    }

    mapping(uint256 => Card) public listCard;
    mapping(uint256 => bool) public ownerWithdraw;
    mapping(uint256 => mapping(address => uint256)) public balanceOfUserInBid;
    mapping(uint256 => mapping(address => uint256)) public withdrawOfUserInBid;
    uint256 public totalBalance;

    constructor(string memory baseURI) ERC721("Auction", "AUC") {
        _actionBaseURI = baseURI;
    }

    struct FrontendCard {
        string nameOfCard;
        uint256 from; // ngay bat dau
        uint256 to;
        uint256 reserveBid;
        uint256 stepBid;
    }

    modifier ownerOfBid(uint256 id) {
        require(
            listCard[id].owner == _msgSender(),
            "Auction: Only owner of this Auction can call this function"
        );
        _;
    }

    modifier auctionExist(uint256 id) {
        require(_exists(id), "Auction: This auction is not exists");
        _;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory baseURI = _baseURI();
        string memory token = Strings.toString(tokenId);
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, "/", token))
                : "";
    }

    function setNewCard(
        uint256 id,
        string calldata nameOfCard,
        uint256 from,
        uint256 to,
        uint256 reserveBid,
        uint256 stepBid
    ) internal {
        if (from != 0) {
            // require(
            //   from >= block.timestamp,
            //   "Auction: Start date must more than current day"
            // );
            listCard[id].from = from;
        } else {
            listCard[id].from = block.timestamp;
        }
        if (to != 0) {
            require(
                to >= listCard[id].from,
                "Auction: Start date must less than end date"
            );
            require(
                to >= block.timestamp,
                "Auction: End date must more than current day"
            );
            listCard[id].to = to;
        } else {
            listCard[id].to = 0;
        }
        listCard[id].nameOfCard = nameOfCard;
        listCard[id].to = to;
        listCard[id].owner = _msgSender();
        listCard[id].reserveBid = reserveBid;
        if (stepBid == 0) {
            listCard[id].stepBid = 1;
        } else {
            listCard[id].stepBid = stepBid;
        }
        // listCard[id].stepBid = stepBid;
    }

    function addNewCard(
        address to,
        uint256 id,
        FrontendCard calldata f
    ) external {
        _safeMint(to, id);
        setNewCard(id, f.nameOfCard, f.from, f.to, f.reserveBid, f.stepBid);
    }

    function getCard(uint256 id)
        external
        view
        auctionExist(id)
        returns (
            string memory,
            uint256,
            uint256,
            uint256,
            address,
            address,
            uint256
        )
    {
        Card memory card = listCard[id];

        return (
            card.nameOfCard,
            card.from,
            card.to,
            card.highestBid,
            card.addressOfHighestBid,
            card.owner,
            card.reserveBid
        );
    }

    function makeOffer(uint256 id) external payable auctionExist(id) {
        require(!listCard[id].endAuction, "Auction: This auction ended");
        require(
            listCard[id].from <= block.timestamp,
            "Auction: This auction is not ready yet"
        );
        if (listCard[id].to != 0) {
            require(
                listCard[id].to >= block.timestamp,
                "Auction: This auction ended "
            );
        }

        if (listCard[id].addressOfHighestBid == address(0)) {
            require(
                msg.value >= listCard[id].reserveBid,
                "Auction: Msg.value less than the reserve bid"
            );
        } else {
            require(
                msg.value > listCard[id].highestBid,
                "Auction: Msg.value less than the current price"
            );
        }
        uint256 returnBid = listCard[id].highestBid;
        (bool success, ) = payable(listCard[id].addressOfHighestBid).call{
            value: returnBid
        }("");
        require(success, "Transfer failed.");
        listCard[id].highestBid = msg.value;
        listCard[id].addressOfHighestBid = _msgSender();
    }

    function approveWinner(uint256 id)
        external
        ownerOfBid(id)
        auctionExist(id)
    {
        require(
            listCard[id].addressOfHighestBid != address(0),
            "Auction: This auction is not auction yet"
        );
        require(
            listCard[id].highestBid >= listCard[id].reserveBid,
            "Auction: Current bid must greater than reserver bid"
        );
        require(
            !listCard[id].endAuction,
            "Auction: Only can call this function one time"
        );
        listCard[id].endAuction = true;
    }

    function withdrawOfUserAuction(uint256 id, uint256 amount)
        external
        auctionExist(id)
    {
        require(
            _msgSender() != listCard[id].addressOfHighestBid,
            "Auction: This address cant withdraw"
        );
        require(
            balanceOfUserInBid[id][_msgSender()] -
                withdrawOfUserInBid[id][_msgSender()] <=
                amount,
            "Auction: The withdraw is higher than the balance of user in the contract"
        );
        withdrawOfUserInBid[id][_msgSender()] += amount;
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Auction: User withdraw fail");
    }

    function withdrawOfOwnerAuction(uint256 id)
        external
        ownerOfBid(id)
        auctionExist(id)
    {
        if (!listCard[id].endAuction && !ownerWithdraw[id]) {
            if (block.timestamp >= listCard[id].to) {
                listCard[id].endAuction = true;
                uint256 amount = listCard[id].highestBid;
                (bool success, ) = msg.sender.call{value: amount}("");
                require(success, "Auction: User withdraw fail");
                ownerWithdraw[id] = true;
            } else {
                revert("Auction: This auction cant be withdraw");
            }
        } else if (listCard[id].endAuction && !ownerWithdraw[id]) {
            uint256 amount = listCard[id].highestBid;
            (bool success, ) = msg.sender.call{value: amount}("");
            require(success, "Auction: User withdraw fail");
            ownerWithdraw[id] = true;
        } else {
            revert("Auction: The owner already withdraw");
        }
    }

    function getWinner(uint256 id)
        external
        view
        auctionExist(id)
        returns (address)
    {
        if (listCard[id].endAuction || block.timestamp >= listCard[id].to) {
            return listCard[id].addressOfHighestBid;
        } else return address(0);
    }

    function auctionFinish(uint256 id)
        external
        view
        auctionExist(id)
        returns (bool)
    {
      bool ownerConfirmed = listCard[id].ownerConfirmed;
      bool userConfirmed = listCard[id].userConfirmed;
        if (ownerConfirmed && userConfirmed) {
            return true;
        } else return false;
    }

    function userConfirmReceive(uint256 id)
        external
        auctionExist(id)
        returns (bool)
    {
        require(
            listCard[id].endAuction || block.timestamp >= listCard[id].to,
            "Auction: This Auction not end yet"
        );
        require(
            _msgSender() == listCard[id].addressOfHighestBid,
            "Auction: Only winner can call this function"
        );
        listCard[id].userConfirmed = true;
                   uint256 amount = listCard[id].highestBid;
            (bool success, ) = msg.sender.call{value: amount}("");
        return true;
    }

    function ownerConfirmSend(uint256 id)
        external
        auctionExist(id)
        returns (bool)
    {
        bool endAuction =  listCard[id].endAuction;
        require(
          endAuction  || block.timestamp >= listCard[id].to,
            "Auction: This Auction not end yet"
        );
        require(
            _msgSender() == listCard[id].owner,
            "Auction: Only owner can call this function"
        );
        listCard[id].ownerConfirmed = true;
        return true;
    }
}
