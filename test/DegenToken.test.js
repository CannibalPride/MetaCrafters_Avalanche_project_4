const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("DegenToken", function () {
    let owner;
    let user;
    let degenToken;

    beforeEach(async () => {
        [owner, user] = await ethers.getSigners();

        const DegenToken = await ethers.getContractFactory("DegenToken");
        degenToken = await DegenToken.deploy();

        await degenToken.addItem(1, 10, "Test Item #1");
        await degenToken.addItem(2, 20, "Test Item #2");
        await degenToken.addItem(3, 30, "Test Item #3");

        await degenToken.deployed();
    });

    it("Should mint tokens to the owner", async function () {
        const initialBalance = await degenToken.balanceOf(owner.address);
        expect(initialBalance).to.equal(0);

        const mintAmount = 1000;
        await degenToken.mintTokens(owner.address, mintAmount);

        const newBalance = await degenToken.balanceOf(owner.address);
        expect(newBalance).to.equal(mintAmount);
    });

    it("Should burn tokens from an account", async function () {
        // Mint some tokens to the owner
        const mintAmount = 1000;
        await degenToken.mintTokens(owner.address, mintAmount);

        const initialBalance = await degenToken.balanceOf(owner.address);

        // Burn a reasonable amount of tokens (e.g., half of the initial balance)
        const burnAmount = initialBalance.div(2);
        await degenToken.burnTokens(burnAmount);

        const newBalance = await degenToken.balanceOf(owner.address);

        // Ensure the new balance is less than or equal to the initial balance
        expect(newBalance).to.be.lte(initialBalance);
    });

    it("Should access and verify the struct data", async function () {
        // Access and verify the struct data
        const item1 = await degenToken.getItem(1);
        const item2 = await degenToken.getItem(2);


        // Verify the values of the struct
        expect(item1.name).to.equal("Test Item #1");
        expect(item1.cost).to.equal(10);

        expect(item2.name).to.equal("Test Item #2");
        expect(item2.cost).to.equal(20);
    });

    it("Should allow redemption of in-game items", async function () {
        const initialBalance = await degenToken.balanceOf(owner.address);

        // Mint tokens to the user to cover the item cost
        await degenToken.mintTokens(owner.address, 1000);

        // Attempt to redeem an item
        await degenToken.redeemTokens(1); // Assuming choice 1 corresponds to an item

        const finalBalance = await degenToken.balanceOf(owner.address);

        // Ensure that the user's balance decreased after redeeming an item
        expect(finalBalance).to.be.lt(1000);
    });

    it("Should display the correct in-game items", async function () {
        const items = await degenToken.displayItems();
        const expectedItemList = `
1: Test Item #1 for 10 Tokens
2: Test Item #2 for 20 Tokens
3: Test Item #3 for 30 Tokens`;

        expect(items).to.equal(expectedItemList);
    });

    it("Should allow updating item cost", async function () {
        const newItemPrice = 11;
        await degenToken.updateItemCost(1, newItemPrice);

        const updatedItem = await degenToken.getItem(1);

        // Verify that the item price has been updated
        expect(updatedItem.cost).to.equal(newItemPrice);
    });

    it("Should remove items", async function () {
        // Remove an item (assuming you have implemented a removeItem function)
        await degenToken.removeItem(1);

        // Attempt to access the removed item
        const removedItem = await degenToken.getItem(1);

        // Verify that the removed item's price is now 0 or some other expected value
        expect(removedItem.cost).to.equal(0);
    });
});
