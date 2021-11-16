const Auction = artifacts.require("Auction");
let web3 = Auction.web3;
const truffleAssert = require("truffle-assertions");
const { ethers, waffle } = require("hardhat");
const utils = require("./utils");
const BigNumber = require("bignumber.js");
const { assert } = require("chai");
const provider = waffle.provider;

describe("Auction test", function () {
  before(async function () {
    accounts = await web3.eth.getAccounts();

    deployer = accounts[0];
    user1 = accounts[1];
    user2 = accounts[2];
    user3 = accounts[3];
    user4 = accounts[4];

    auction = await Auction.new("123123123123", { from: deployer });
  });

  it("Add new Auction", async function () {
    const frontendCard = {
      nameOfCard: "Hung1231231233",
      from: parseInt(new Date().valueOf() / 100),
      to: parseInt(new Date().valueOf() / 100) + 1000,
      reserveBid: 10000,
      stepBid: 0,
    };
    await auction.addNewCard(deployer, 1, frontendCard, { from: deployer });
    const frontendCard1 = {
      nameOfCard: "Hung1231231233",
      from: parseInt(new Date().valueOf() / 100),
      to: parseInt(new Date().valueOf() / 100) + 1000,
      reserveBid: 10000,
      stepBid: 0,
    };
    await auction.addNewCard(deployer, 2, frontendCard, { from: deployer });
  });

  it("Make offer", async function () {
    await utils.setTime(parseInt(new Date().valueOf() / 100));
    await auction.makeOffer(1, {
      from: user1,
      value: ethers.utils.parseEther("0.0001"),
    });
    assert.equal(user1,(await auction.listCard(1)).addressOfHighestBid)
    assert.equal((ethers.utils.parseEther("0.0001")).toString(),((await auction.listCard(1)).highestBid).toString())
    await auction.makeOffer(1, {
      from: user2,
      value: ethers.utils.parseEther("0.001"),
    });
    assert.equal(user2,(await auction.listCard(1)).addressOfHighestBid)
    assert.equal((ethers.utils.parseEther("0.001")).toString(),((await auction.listCard(1)).highestBid).toString())
    await auction.makeOffer(1, {
      from: user3,
      value: ethers.utils.parseEther("0.01"),
    });
    assert.equal(user3,(await auction.listCard(1)).addressOfHighestBid)
    assert.equal((ethers.utils.parseEther("0.01")).toString(),((await auction.listCard(1)).highestBid).toString())
    console.log((await auction.listCard(1)).totalBalance.toString())
  });
});
