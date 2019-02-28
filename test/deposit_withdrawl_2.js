var fixedSupplyToken = artifacts.require("./FixedSupplyToken.sol")
var exchange = artifacts.require("./Exchange.sol")
contract('Exchange Basic Tests', function(accounts){
	it("Add Tokens", function(){
		var myTokenInstance;
		var myExchangeInstance;
		return fixedSupplyToken.deployed().then(function(instance){
			myTokenInstance = instance;
			return exchange.deployed();
		}).then(function (exchangeInstance){
			myExchangeInstance = exchangeInstance;
			return myExchangeInstance.addToken("FIXED", myTokenInstance.address);
		}).then(function(txResult){
			assert.equal(txResult.logs[0].event, "TokenAddedToSystem", "TokenAddedtoSystem Event should be emitted");
			return myExchangeInstance.hasToken.call("FIXED");
		}).then(function (booleanHasToken){
			assert.equal(booleanHasToken, true, "The token was added");
			return myExchangeInstance.hasToken.call("SOMETHING");
		}).then(function (booleanHasNotToken){
			assert.equal(booleanHasNotToken, false, "The token doesn't exist");
		});
	});
	
	/*it("Deposit and Withdraw Ethers", function(){
		var myExchangeInstance;
		var balanceBeforeTransaction = web3.eth.getBalance(accounts[0])
		var balanceAfterDeposit;
		var balanceAfterWithdrawl;
		var gasUsed = 0;
		return exchange.deployed().then(function (instance){
			myExchangeInstance = instance;
			return myExchangeInstance.depositEther({from: accounts[0], value: web3.utils.toWei(web3.utils.toBN(1),"ether")});
		}).then(function (txHash){
			gasUsed += txHash.receipt.cumulativeGasUsed * web3.eth.getTransaction(txHash.receipt.transactionHash).gasPrice.toNumber();
			balanceAfterDeposit = web3.eth.getBalance(accounts[0]);
			return myExchangeInstance.getEthBalanceInWei.call();
		}).then(function (balanceInWei){
			assert.equal(balanceInWei.toNumber(),web3.utils.toWei(web3.utils.toBN(1),"ether"),"One ether availabl");
			assert.isAtleast(balanceBeforeTransaction.toNumber()-balanceAfterDeposit.toNumber(),web3.utils.toWei(web3.utils.toBN(1),"ether"),"Balances of the account are same");
			return myExchangeInstance.withdrawEther(web3.utils.toWei(web3.utils.toBN(1),"ether"));
		}).then(function(txHash){
			balanceAfterWithdrawl = web3.eth.getBalance(accounts[0]);
			return myExchangeInstance.getEthBalanceInWei.call();
		}).then(function (balanceInWei){
			assert.equal(balanceInWei.toNumber(),0,"There is no ether available anymore");
			assert.isAtleast(balanceAfterWithdrawl.toNumber(), balanceBeforeTransaction.toNumber() - gasUsed*2, "There is one ether availaible");
		});
	});*/
	
	it("Should be possible to deposit token", function(){
		var myExchangeInstance;
		var myTokenInstance;
		return fixedSupplyToken.deployed().then(function (instance){
			myTokenInstance = instance;
			return instance;
		}).then(function (tokenInstance){
			myTokenInstance = tokenInstance;
			return exchange.deployed()
		}).then(function (exchangeInstance){
			myExchangeInstance = exchangeInstance;
			return myTokenInstance.approve(myExchangeInstance.address, 2000);
		}).then(function (txResult){
			return myExchangeInstance.depositToken("FIXED", 2000);
		}).then(function (txResult){
			return myExchangeInstance.getBalance("FIXED");
		}).then(function (balanceToken){
			assert.equal(balanceToken, 2000, "There should be 2000 tokens for the address");
		});
	});
	
	it("Should be possible to withdraw token", function(){
		var myExchangeInstance;
		var myTokenInstance;
		var balancedTokenInExchangeBeforeWithdrawl;
		var balanceTokenInTokenBeforeWithdrawl;
		var balancedTokenInExchangeAfterWithdrawl;
		var balanceTokenInTokenAfterWithdrawl;
		return fixedSupplyToken.deployed().then(function (instance){
			myTokenInstance = instance;
			return instance;
		}).then(function (tokenInstance){
			myTokenInstance = tokenInstance;
			return exchange.deployed()
		}).then(function (exchangeInstance){
			myExchangeInstance = exchangeInstance;
			return myExchangeInstance.getBalance.call("FIXED");
		}).then(function (balanceExchange){
			balancedTokenInExchangeBeforeWithdrawl = balanceExchange.toNumber();
			return myTokenInstance.balanceOf.call(accounts[0]);
		}).then(function (balanceToken){
			balanceTokenInTokenBeforeWithdrawl = balanceToken.toNumber();
			return myExchangeInstance.withdrawToken("FIXED", balancedTokenInExchangeBeforeWithdrawl);
		}).then(function (txResult) {
			return myExchangeInstance.getBalance.call("FIXED");
		}).then(function (balanceExchange){
			balancedTokenInExchangeAfterWithdrawl = balanceExchange.toNumber();
			return myTokenInstance.balanceOf.call(accounts[0]);
		}).then(function (balanceToken){
			balanceTokenInTokenAfterWithdrawl = balanceToken.toNumber();
			assert.equal(balancedTokenInExchangeAfterWithdrawl, 0, "There should be 0 tokens left in the exchange");
			assert.equal(balanceTokenInTokenAfterWithdrawl, balancedTokenInExchangeBeforeWithdrawl+balanceTokenInTokenBeforeWithdrawl, "There should be 0 tokens left in the exchange");
		});
	});
});