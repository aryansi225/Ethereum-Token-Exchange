# Ethereum-Token-Exchange
Basic Ethereum Token Exchange  based on ERC20 Token Standard

Smart Contarct is written to implement an Ethereum Token Exchange. The exchange contract is built on top of ERC 20 Token Standard Exchange contract. The contract built helps to do following :-

1. Manage Token - The admin can add any kind of token and put it up for sell for ether.
2. Initial Coing Offering - The owner of token can put up the token for initial selling for any exchange rate with ether.
3. Trading - Traders can buy and sell tokens or cancel their order. The exchange can execute the order based fulfillment availability.

For doing any of the transactions the admin to trader first have to deposit token or ether to exchange, and they can withdraw this from exchange if needed.

The contract's functionality has been extensively unit tested using TestRPC, Web3 and Mocha.

The contract has been built using truffle framework.

The front end's boiler plate code for interacting with contract is generated using truffle-init-webpack. The frontend html pages and javascript files are then added with logic to call the multiple account using web3 and contract functions. The 

Then using infura the contract is migrated to rinkeby test network and the front end is build and hosted using github pages.


How to interact with contract ?

The exchange can be accessed via - https://aryansi225.github.io/Ethereum-Token-Exchange/
You would require metamask with accounts on rinkeby networks with some ethers. After this you can deposit/withdraw ether to/from exchage and then buy token. Once you have some token you can put sell order to get ether back and it will be fulfilled when someone buys it back. The rights to add new token to exchange and put for ico is reserved to admin.


# Screenshots

First being as admin I added Fixed token to exchange
![image](https://user-images.githubusercontent.com/16362957/53591373-d4ff4b00-3bb9-11e9-871c-63ee3308a406.png)

Then I gave allowance to Exchange to send 50 tokens
![image](https://user-images.githubusercontent.com/16362957/53591500-27406c00-3bba-11e9-84a2-bcf867a009d2.png)

Then I deposited 50 tokens to exchange
![image](https://user-images.githubusercontent.com/16362957/53591526-3de6c300-3bba-11e9-802f-772a1ef1aa15.png)

![image](https://user-images.githubusercontent.com/16362957/53591606-6969ad80-3bba-11e9-979f-8d9eed83fb95.png)

Then I had put 20 tokens for 50000 wei each for sale
![image](https://user-images.githubusercontent.com/16362957/53591664-869e7c00-3bba-11e9-96f0-63db5970dc77.png)

![image](https://user-images.githubusercontent.com/16362957/53591701-9d44d300-3bba-11e9-8479-a6753b8a62a6.png)

Then I had put another 10 tokens for 40000 wei each for sale
![image](https://user-images.githubusercontent.com/16362957/53591772-c82f2700-3bba-11e9-96a5-cd492c2fd943.png)

Then using my second account (non-admin) I deposited 0.1 ether to exchange
![image](https://user-images.githubusercontent.com/16362957/53591840-fd3b7980-3bba-11e9-85fd-4e6d6cb6a351.png)

Then using the second account I placed a buy order of 5 tokens for 50000 wei each and it got instantly fulfilled with the seller asking for lower price as it would happen in a trading setup
![image](https://user-images.githubusercontent.com/16362957/53591979-48558c80-3bbb-11e9-87ab-29247ab73ee8.png)

![image](https://user-images.githubusercontent.com/16362957/53592010-5dcab680-3bbb-11e9-9d8e-89c5f9db2344.png)


# Dependencies
Solidity,
Truffle,
Ethereumjs-TestRPC,
NPM,
Geth,
Mist,
MetaMask,
Infura,
Mocha,
Web3.

# References and Credits
https://github.com/tomw1808/distributed_exchange_truffle_class_3




MIT License

Copyright (c)

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
