var fixedSupplyToken = artifacts.require("./FixedSupplyToken.sol");
var exchange = artifacts.require("./Exchange.sol");

contract('Simple Order Tests', function (accounts) {
    before(function() {
        var instanceExchange;
        var instanceToken;
        return exchange.deployed().then(function (instance) {
            instanceExchange = instance;
            return instanceExchange.depositEther({from: accounts[0], value: web3.utils.toWei(web3.utils.toBN(3), "ether")});
        }).then(function(txResult) {
			assert.equal(txResult.logs[0].event, "DepositForEthReceived", "DepositForEthReceived Event should be emitted");
            return fixedSupplyToken.deployed();
        }).then(function(myTokenInstance) {
            instanceToken = myTokenInstance;
            return instanceExchange.addToken("FIXED", instanceToken.address);
        }).then(function(txResult) {
			assert.equal(txResult.logs[0].event, "TokenAddedToSystem", "TokenAddedToSystem Event should be emitted");
            return instanceToken.approve(instanceExchange.address, 2000);
        }).then(function(txResult) {
			assert.equal(txResult.logs[0].event, "Approval", "Approval Event should be emitted");
            return instanceExchange.depositToken("FIXED", 2000);
        }).then(function(txResult) {
			assert.equal(txResult.logs[0].event, "DepositForTokenReceived", "DepositForTokenReceived Event should be emitted");
		});
  });


    it("should be possible to add a limit buy order", function () {
        var myExchangeInstance;
        return exchange.deployed().then(function (instance) {
            myExchangeInstance = instance;
            return myExchangeInstance.getBuyOrderBook.call("FIXED");
        }).then(function (orderBook) {
            //assert.equal(orderBook.length, 2, "BuyOrderBook should have 2 elements");
            assert.equal(orderBook[0].length, 0, "OrderBook should have 0 buy offers");
            return myExchangeInstance.buyToken("FIXED", web3.utils.toWei(web3.utils.toBN(1), "finney"), 5);
        }).then(function(txResult) {
            assert.equal(txResult.logs.length, 1, "There should have been one Log Message emitted.");
            assert.equal(txResult.logs[0].event, "LimitBuyOrderCreated", "The Log-Event should be LimitBuyOrderCreated");
            return myExchangeInstance.getBuyOrderBook.call("FIXED");
        }).then(function(orderBook) {
            assert.equal(orderBook[0].length, 1, "OrderBook should have 0 buy offers");
            assert.equal(orderBook[1].length, 1, "OrderBook should have 0 buy volume has one element");
        });
    });




    it("should be possible to add three limit buy orders", function () {
        var myExchangeInstance;
        var orderBookLengthBeforeBuy;
        return exchange.deployed().then(function (exchangeInstance) {
            myExchangeInstance = exchangeInstance;
            return myExchangeInstance.getBuyOrderBook.call("FIXED");
        }).then(function (orderBook) {
            orderBookLengthBeforeBuy = orderBook[0].length;
            return myExchangeInstance.buyToken("FIXED", web3.utils.toWei(web3.utils.toBN(2), "finney"), 5);
        }).then(function(txResult) {
            assert.equal(txResult.logs[0].event, "LimitBuyOrderCreated", "The Log-Event should be LimitBuyOrderCreated");
            return myExchangeInstance.buyToken("FIXED", web3.utils.toWei((1.4).toString(), "finney"), 5);
        }).then(function(txResult) {
            assert.equal(txResult.logs[0].event, "LimitBuyOrderCreated", "The Log-Event should be LimitBuyOrderCreated");
            return myExchangeInstance.getBuyOrderBook.call("FIXED");
        }).then(function(orderBook) {
            assert.equal(orderBook[0].length, orderBookLengthBeforeBuy+2, "OrderBook should have one more buy offers");
            assert.equal(orderBook[1].length, orderBookLengthBeforeBuy+2, "OrderBook should have 2 buy volume elements");
        });
    });


    it("should be possible to add two limit sell orders", function () {
        var myExchangeInstance;
        return exchange.deployed().then(function (instance) {
            myExchangeInstance = instance;
            return myExchangeInstance.getSellOrderBook.call("FIXED");
        }).then(function (orderBook) {
            return myExchangeInstance.sellToken("FIXED", web3.utils.toWei(web3.utils.toBN(3), "finney"), 5);
        }).then(function(txResult) {
            assert.equal(txResult.logs.length, 1, "There should have been one Log Message emitted.");
            assert.equal(txResult.logs[0].event, "LimitSellOrderCreated", "The Log-Event should be LimitSellOrderCreated");
            return myExchangeInstance.sellToken("FIXED", web3.utils.toWei(web3.utils.toBN(6), "finney"), 5);
        }).then(function(txResult) {
            return myExchangeInstance.getSellOrderBook.call("FIXED");
        }).then(function(orderBook) {
            assert.equal(orderBook[0].length, 2, "OrderBook should have 2 sell offers");
            assert.equal(orderBook[1].length, 2, "OrderBook should have 2 sell volume elements");
        });
    });


    it("should be possible to create and cancel a buy order", function () {
       var myExchangeInstance;
       var orderBookLengthBeforeBuy, orderBookLengthAfterBuy, orderBookLengthAfterCancel, orderKey;
       return exchange.deployed().then(function (instance) {
           myExchangeInstance = instance;
           return myExchangeInstance.getBuyOrderBook.call("FIXED");
       }).then(function (orderBook) {
           orderBookLengthBeforeBuy = orderBook[0].length;
           return myExchangeInstance.buyToken("FIXED", web3.utils.toWei((2.2).toString(), "finney"), 5);
       }).then(function(txResult) {
           assert.equal(txResult.logs.length, 1, "There should have been one Log Message emitted.");
           assert.equal(txResult.logs[0].event, "LimitBuyOrderCreated", "The Log-Event should be LimitBuyOrderCreated");
           orderKey = txResult.logs[0].args._orderKey;
           return myExchangeInstance.getBuyOrderBook.call("FIXED");
       }).then(function (orderBook) {
           orderBookLengthAfterBuy = orderBook[0].length;
           assert.equal(orderBookLengthAfterBuy, orderBookLengthBeforeBuy + 1, "OrderBook should have 1 buy offers more than before");
           return myExchangeInstance.cancelOrder("FIXED", false, web3.utils.toWei((2.2).toString(), "finney"), orderKey);
       }).then(function(txResult) {
           assert.equal(txResult.logs[0].event, "BuyOrderCancelled", "The Log-Event should be BuyOrderCancelled");
           return myExchangeInstance.getBuyOrderBook.call("FIXED");
       }).then(function(orderBook) {
           orderBookLengthAfterCancel = orderBook[0].length;
           assert.equal(orderBookLengthAfterCancel, orderBookLengthAfterBuy, "OrderBook should have 1 buy offers, its not cancelling it out completely, but setting the volume to zero");
           assert.equal(orderBook[1][orderBookLengthAfterCancel-1], 0, "The available Volume should be zero");
       });
    });
});
