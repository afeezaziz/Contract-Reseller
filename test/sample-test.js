/* jshint expr: true */
const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Reseller Contract", function () {
  let reseller;
  let owner;
  let reseller01;
  // let reseller02;
  // let buyer01;
  // let buyer02;

  beforeEach(async function () {
    const Reseller = await ethers.getContractFactory("Reseller");
    reseller = await Reseller.deploy();
    // [owner, reseller01, reseller02, buyer01, buyer02] = await ethers.getSigners();
    [owner, reseller01] = await ethers.getSigners();
  });

  it("Owner of the contract is msg.sender", async function () {
    expect(await reseller.owner()).to.equal(owner.address);
  });

  it("Register seller01", async function () {
    const registerSellerTx = await reseller.registerSeller(reseller01.address);
    await registerSellerTx.wait();
    expect(await reseller.sellers(1)).to.equal(reseller01.address);
  });

});