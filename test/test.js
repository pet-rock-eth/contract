const MyToken = artifacts.require('MyToken');
const truffleAssert = require('truffle-assertions');

contract("MyToken", (accounts) => {
    // before(async () => {
    //   myTokenInstance = await MyToken.new();
    // });
  describe("Customer mint a token", async () =>{
    it("should mint a new token id 1 by account 1", async () => {
      const myTokenInstance = await MyToken.new();
      const owner = accounts[0]
      const adopter = accounts[1];
      const tokenId = 1;

      await myTokenInstance.mint(adopter, 1);

      const balance = await myTokenInstance.balanceOf(owner, tokenId);
      assert.equal(balance.toNumber(), tokenId, "Token was not minted successfully"); 
    });
    it("Should get the true adopter by account 1" , async () =>{
      const myTokenInstance = await MyToken.new();
      const tokenId = 1;
      const adopterAddress = accounts[1];

      await myTokenInstance.mint(adopterAddress, 1);
      const adopter = await myTokenInstance.get_token_adopter(tokenId);

      assert.equal(adopter, adopterAddress, "The adopter isn't expected user");
    });
  })

  describe("Customer could should pay more than required to unlock.", async () =>{
    it("Should pay to unlock the NFT by account 1" , async () =>{
      const myTokenInstance = await MyToken.new();
      const tokenId = 1;
      const accountAddress = accounts[1];
      const lock_status = false
      
      await myTokenInstance.mint(accountAddress, tokenId);
      await myTokenInstance.unlock_payment(tokenId, {from:accountAddress, value: web3.utils.toWei('1', 'milli')});
      const token_lock_status = await myTokenInstance.get_token_lock_status(tokenId);
  
      assert.equal(token_lock_status, lock_status, "The lock isn't expected to lock while paying is enough.")
    });

    it("Error while the fee is lower than required.", async () =>{
      const myTokenInstance = await MyToken.new();
      const tokenId = 1;
      const accountAddress = accounts[1];
      
      await myTokenInstance.mint(accountAddress, tokenId);
      await truffleAssert.fails(
        myTokenInstance.unlock_payment(tokenId, {from:accountAddress, value: web3.utils.toWei('0.1', 'milli')})),
        truffleAssert.ErrorType.REVERT,
        "payment fee is lower than required."
    });
  })
  
  describe("The transfer should be done after the unlock have been done.",async() => {
    it("Should transfer in unlock condition.", async() => {
      const myTokenInstance = await MyToken.new();
      const tokenId = 1;
      const accountAddress = accounts[1];
      const amount = 1;
      const owner = accounts[0];

      await myTokenInstance.mint(accountAddress, tokenId);
      myTokenInstance.unlock_payment(tokenId, {from:accountAddress, value: web3.utils.toWei('1', 'milli')});
      await myTokenInstance.safeTransferFrom(accountAddress, owner, tokenId, amount, "0x00" );
    })

    // it("")
  })

  describe("The transfer should be done after the unlock have been done.",async() => {
    it("Should transfer in unlock condition.", async() => {
      const myTokenInstance = await MyToken.new();
      const tokenId = 1;
      const accountAddress = accounts[1];
      const amount = 1;
      const owner = accounts[0];

      await myTokenInstance.mint(accountAddress, tokenId);
      myTokenInstance.unlock_payment(tokenId, {from:accountAddress, value: web3.utils.toWei('1', 'milli')});
      await myTokenInstance.safeTransferFrom(accountAddress, owner, tokenId, amount, "0x00" );
    })

  })

})