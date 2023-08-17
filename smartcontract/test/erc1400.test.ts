import { expect } from "chai";
import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import { ERC1400__factory, ERC1400 } from "../typechain-types";

describe("ERC1400 contract", function() {

    let erc1400: ERC1400;
    let deployer: SignerWithAddress;
    let trader1: SignerWithAddress;
    let trader2: SignerWithAddress;

    const contractName      = "TestToken";
    const contractSymbol    = "TT";
    const zeroAddress       = "0x0000000000000000000000000000000000000000";
    const ZERO_BYTES32      = "0x0000000000000000000000000000000000000000000000000000000000000000";


    before(async function() {
        [deployer, trader1, trader2] = await ethers.getSigners();
        const erc1400Factory = (await ethers.getContractFactory(
            "ERC1400", deployer
        )) as ERC1400__factory;

        erc1400 = await erc1400Factory.deploy(
            contractName,
            contractSymbol,
        )
        
    }) 

    context("deploy", async () => {
        it("- check information", async () => {
            expect(await erc1400.name()).to.be.equal(contractName);
            expect(await erc1400.symbol()).to.be.equal(contractSymbol);
        })
    })

    context("issue", async () => {
        it("- check contract is issuable", async() => {
            expect(await erc1400.isIssuable()).to.be.true;
        })
        it("- deployer issue 1000 tokens", async() => {
            await erc1400.issue(deployer.address, 1000, ZERO_BYTES32);
            expect(await erc1400.balanceOf(deployer.address)).to.be.equal(1000);
        })
    })
})