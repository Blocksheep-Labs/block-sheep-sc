const { expect } = require("chai")
const { Contract, ContractFactory } = require("ethers")
const { ethers } = require("hardhat")

describe("BlockSheep Contract", function () {
    let token
    let ownerAccount, playerA, playerB, playerC
    let initialBalance = 100*10**6
    let raceCost = 10*10**6
    let mockUSDC
    let blockSheepContract
    before(async function(){
        [ownerAccount, playerA, playerB, playerC] = await ethers.getSigners()
        mockUSDC = await ethers.deployContract("MockUSDC")
        blockSheepContract = await ethers.deployContract("BlockSheep", [
            mockUSDC.address,
            ownerAccount,
            raceCost
        ])

        console.log("mock USDC", mockUSDC.target)
        console.log("block sheep", blockSheepContract.target)

    })

    it(" ", async function(){

    })


   
})
