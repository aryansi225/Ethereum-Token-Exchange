pragma solidity ^0.5.0;

import "./FixedSupplyToken.sol";

contract Exchange is Owned{
    
    struct Offer{
        uint amount;
        address who;
    }
    
    struct OrderBook{
        uint higherPrice;
        uint lowerPrice;
        mapping (uint => Offer) offers;
        uint offers_key;
        uint offers_length;
    }
    
    struct Token{
        address tokenContract;
        string symbolName;
        
        mapping (uint => OrderBook) buyBook;
        
        uint currentBuyPrice;
        uint lowestBuyPrice;
        uint amountBuyPrices;
        
        mapping (uint => OrderBook) sellBook;
        
        uint currentSellPrice;
        uint highestSellPrice;
        uint amountSellPrices;
    }
    
    //255 tokens are given at max
    mapping (uint8 => Token) tokens;
    uint8 symbolNameIndex;
    
    //Balances
    mapping (address => mapping(uint8 => uint)) tokenBalanceForAddress;
    mapping (address => uint) balanceEthForAddress;
    
	//Events
	event DepositForTokenReceived(address indexed _from, uint indexed _symbolIndex, uint _amount, uint _timestamp);
	event WithdrawlToken(address indexed _to, uint indexed _symbolIndex, uint _amount, uint _timestamp);
	event DepositForEthReceived(address indexed _from, uint _amount, uint _timestamp);
	event WithdrawlEth(address indexed _to, uint _amount, uint _timestamp);
	
	event LimitSellOrderCreated(uint indexed _symbolIndex, address indexed _who, uint _amountTokens, uint _priceInWei, uint _orderKey);
	event SellOrderFulfilled(uint indexed _symbolIndex, uint _amount, uint _priceInWei, uint _orderKey);
	event SellOrderCancelled(uint indexed _symbolIndex, uint _priceInWei, uint _orderKey);
	event LimitBuyOrderCreated(uint indexed _symbolIndex, address indexed _who, uint _amountTokens, uint _priceInWei, uint _orderKey);
	event BuyOrderFulfilled(uint indexed _symbolIndex, uint _amount, uint _priceInWei, uint _orderKey);
	event BuyOrderCancelled(uint indexed _symbolIndex, uint _priceInWei, uint _orderKey);
	
	event TokenAddedToSystem(uint _symbolIndex, string _token, uint _timestamp);
	
	//Deposit and Withdraw For Ether
	function depositEther() public payable{
		require(balanceEthForAddress[msg.sender]+msg.value >= balanceEthForAddress[msg.sender]);
		balanceEthForAddress[msg.sender] += msg.value;
		emit DepositForEthReceived(msg.sender, msg.value, now);
	}
	function withdrawEther(uint amountInWei) public{
		require(balanceEthForAddress[msg.sender]-amountInWei >= 0);
		require(balanceEthForAddress[msg.sender]-amountInWei <= balanceEthForAddress[msg.sender]);
		balanceEthForAddress[msg.sender] -= amountInWei;
		msg.sender.transfer(amountInWei);
		emit WithdrawlEth(msg.sender, amountInWei, now);
	}
	function getEthBalanceInWei() public view returns(uint){
		return balanceEthForAddress[msg.sender];
	}
	
	//Deposit and Withdraw For Token
	function depositToken(string memory symbolName, uint amount) public{
		uint8 symbolIndex = getSymbolIndexOrThrow(symbolName);
		require(tokens[symbolIndex].tokenContract!=address(0));
		ERC20Interface token = ERC20Interface(tokens[symbolIndex].tokenContract);
		require(token.transferFrom(msg.sender, address(this), amount) == true);
		require(tokenBalanceForAddress[msg.sender][symbolIndex]+amount >= tokenBalanceForAddress[msg.sender][symbolIndex]);
		tokenBalanceForAddress[msg.sender][symbolIndex] += amount;
		emit DepositForTokenReceived(msg.sender, symbolIndex, amount, now);
	}
	
	function withdrawToken(string memory symbolName, uint amount) public{
		uint8 symbolIndex = getSymbolIndexOrThrow(symbolName);
		require(tokens[symbolIndex].tokenContract!=address(0));
		ERC20Interface token = ERC20Interface(tokens[symbolIndex].tokenContract);
		require(tokenBalanceForAddress[msg.sender][symbolIndex]-amount >= 0);
		require(tokenBalanceForAddress[msg.sender][symbolIndex]-amount <= tokenBalanceForAddress[msg.sender][symbolIndex]);
		tokenBalanceForAddress[msg.sender][symbolIndex] -= amount;
		require(token.transfer(msg.sender, amount) == true);
		emit WithdrawlToken(msg.sender, symbolIndex, amount, now);
	}
	
	function getBalance(string memory symbolName) public view returns (uint){
		uint8 symbolIndex = getSymbolIndexOrThrow(symbolName);
		return tokenBalanceForAddress[msg.sender][symbolIndex];
	}
	
    //Token Management
    function addToken(string memory symbolName, address erc20TokenAddress) public onlyOwner {
        require(!hasToken(symbolName));
        symbolNameIndex++;
        tokens[symbolNameIndex].symbolName = symbolName;
        tokens[symbolNameIndex].tokenContract = erc20TokenAddress;
		emit TokenAddedToSystem(symbolNameIndex, symbolName, now);
    }
    
    function hasToken(string memory symbolName) public view returns(bool){
        uint8 index = getSymbolIndex(symbolName);
        if(index == 0)
            return false;
        else
            return true;
    }
    
    function getSymbolIndex(string memory symbolName) internal view returns(uint8){
        for(uint8 i=1; i<=symbolNameIndex; i++){
            if(stringsEqual(tokens[i].symbolName, symbolName)) {
                return i;
            }
        }
        return 0;
    }
    
	function getSymbolIndexOrThrow(string memory symbolName) public view returns (uint8){
		uint8 index=getSymbolIndex(symbolName);
		require(index>0);
		return index;
	}
    
    //String Comparison
    function stringsEqual(string storage _a, string memory _b) internal view returns(bool){
        bytes storage a = bytes(_a);
        bytes memory b = bytes(_b);
        if(a.length != b.length)
            return false;
        for(uint i = 0; i< a.length; i++)
            if(a[i] != b[i])
                return false;
        return true;
    }
	
	//OrderBook - Bid Order
	function getBuyOrderBook(string memory symbolName) public view returns (uint[] memory, uint[] memory) {
        uint8 tokenNameIndex = getSymbolIndexOrThrow(symbolName);
        uint[] memory arrPricesBuy = new uint[](tokens[tokenNameIndex].amountBuyPrices);
		uint[] memory arrVolumesBuy = new uint[](tokens[tokenNameIndex].amountBuyPrices);
		uint whilePrice = tokens[tokenNameIndex].lowestBuyPrice;
        uint counter = 0;
        if (tokens[tokenNameIndex].currentBuyPrice > 0) {
            while (whilePrice <= tokens[tokenNameIndex].currentBuyPrice) {
                arrPricesBuy[counter] = whilePrice;
                uint volumeAtPrice = 0;
				uint offers_key = 0;
				offers_key = tokens[tokenNameIndex].buyBook[whilePrice].offers_key;
                while (offers_key <= tokens[tokenNameIndex].buyBook[whilePrice].offers_length) {
                    volumeAtPrice += tokens[tokenNameIndex].buyBook[whilePrice].offers[offers_key].amount;
                    offers_key++;
				}
				arrVolumesBuy[counter] = volumeAtPrice;
				if (whilePrice == tokens[tokenNameIndex].buyBook[whilePrice].higherPrice) {
					break;
				}else {
					whilePrice = tokens[tokenNameIndex].buyBook[whilePrice].higherPrice;
				}
				counter++;
			}
		}
		return (arrPricesBuy, arrVolumesBuy);
	}
	
	//OrderBook - Ask Order
	function getSellOrderBook(string memory symbolName) public view returns (uint[] memory, uint[] memory) {
        uint8 tokenNameIndex = getSymbolIndexOrThrow(symbolName);
        uint[] memory arrPricesSell = new uint[](tokens[tokenNameIndex].amountSellPrices);
        uint[] memory arrVolumesSell = new uint[](tokens[tokenNameIndex].amountSellPrices);
        uint sellWhilePrice = tokens[tokenNameIndex].currentSellPrice;
        uint sellCounter = 0;
        if (tokens[tokenNameIndex].currentSellPrice > 0) {
            while (sellWhilePrice <= tokens[tokenNameIndex].highestSellPrice) {
                arrPricesSell[sellCounter] = sellWhilePrice;
                uint sellVolumeAtPrice = 0;
                uint sell_offers_key = 0;
                sell_offers_key = tokens[tokenNameIndex].sellBook[sellWhilePrice].offers_key;
                while (sell_offers_key <= tokens[tokenNameIndex].sellBook[sellWhilePrice].offers_length) {
                    sellVolumeAtPrice += tokens[tokenNameIndex].sellBook[sellWhilePrice].offers[sell_offers_key].amount;
                    sell_offers_key++;
                }
                arrVolumesSell[sellCounter] = sellVolumeAtPrice;
                if (tokens[tokenNameIndex].sellBook[sellWhilePrice].higherPrice == 0) {
                    break;
                }
                else {
                    sellWhilePrice = tokens[tokenNameIndex].sellBook[sellWhilePrice].higherPrice;
                }
                sellCounter++;

            }
        }
        return (arrPricesSell, arrVolumesSell);
	}
	
	//New Order - Bid Order
	function buyToken(string memory symbolName, uint priceInWei, uint amount) public{
		uint8 tokenNameIndex = getSymbolIndexOrThrow(symbolName);
		uint total_amount_ether_necessary = 0;
		total_amount_ether_necessary = amount*priceInWei;
		require(total_amount_ether_necessary >= amount);
		require(total_amount_ether_necessary >= priceInWei);
		require(balanceEthForAddress[msg.sender] >= total_amount_ether_necessary);
		require(balanceEthForAddress[msg.sender] - total_amount_ether_necessary >= 0);
		balanceEthForAddress[msg.sender] -= total_amount_ether_necessary;
		if(tokens[tokenNameIndex].amountSellPrices == 0 || tokens[tokenNameIndex].currentSellPrice > priceInWei){
			addBuyOffer(tokenNameIndex, priceInWei, amount, msg.sender);
			emit LimitBuyOrderCreated(tokenNameIndex, msg.sender, amount, priceInWei, tokens[tokenNameIndex].buyBook[priceInWei].offers_length);
		}else{
			uint total_amount_ether_available = 0;
            uint whilePrice = tokens[tokenNameIndex].currentSellPrice;
            uint amountNecessary = amount;
            uint offers_key;
			while (whilePrice <= priceInWei && amountNecessary > 0) {
				offers_key = tokens[tokenNameIndex].sellBook[whilePrice].offers_key;
				while (offers_key <= tokens[tokenNameIndex].sellBook[whilePrice].offers_length && amountNecessary > 0) {
					uint volumeAtPriceFromAddress = tokens[tokenNameIndex].sellBook[whilePrice].offers[offers_key].amount;
					if (volumeAtPriceFromAddress <= amountNecessary) {
						total_amount_ether_available = volumeAtPriceFromAddress * whilePrice;
						require(balanceEthForAddress[msg.sender] >= total_amount_ether_available);
						require(balanceEthForAddress[msg.sender] - total_amount_ether_available <= balanceEthForAddress[msg.sender]);
						balanceEthForAddress[msg.sender] -= total_amount_ether_available;
						require(tokenBalanceForAddress[msg.sender][tokenNameIndex] + volumeAtPriceFromAddress >= tokenBalanceForAddress[msg.sender][tokenNameIndex]);
						require(balanceEthForAddress[tokens[tokenNameIndex].sellBook[whilePrice].offers[offers_key].who] + total_amount_ether_available >= balanceEthForAddress[tokens[tokenNameIndex].sellBook[whilePrice].offers[offers_key].who]);
						tokenBalanceForAddress[msg.sender][tokenNameIndex] += volumeAtPriceFromAddress;
                        tokens[tokenNameIndex].sellBook[whilePrice].offers[offers_key].amount = 0;
                        balanceEthForAddress[tokens[tokenNameIndex].sellBook[whilePrice].offers[offers_key].who] += total_amount_ether_available;
						tokens[tokenNameIndex].sellBook[whilePrice].offers_key++;
						emit SellOrderFulfilled(tokenNameIndex, volumeAtPriceFromAddress, whilePrice, offers_key);
						amountNecessary -= volumeAtPriceFromAddress;
					} else {
						require(tokens[tokenNameIndex].sellBook[whilePrice].offers[offers_key].amount > amountNecessary);
						total_amount_ether_necessary = amountNecessary * whilePrice;
						require(balanceEthForAddress[msg.sender] - total_amount_ether_necessary <= balanceEthForAddress[msg.sender]);
						balanceEthForAddress[msg.sender] -= total_amount_ether_necessary;
						require(balanceEthForAddress[tokens[tokenNameIndex].sellBook[whilePrice].offers[offers_key].who] + total_amount_ether_necessary >= balanceEthForAddress[tokens[tokenNameIndex].sellBook[whilePrice].offers[offers_key].who]);
						tokens[tokenNameIndex].sellBook[whilePrice].offers[offers_key].amount -= amountNecessary;
                        balanceEthForAddress[tokens[tokenNameIndex].sellBook[whilePrice].offers[offers_key].who] += total_amount_ether_necessary;
						tokenBalanceForAddress[msg.sender][tokenNameIndex] += amountNecessary;
						amountNecessary = 0;
						emit SellOrderFulfilled(tokenNameIndex, amountNecessary, whilePrice, offers_key);
					}
					
					if(offers_key == tokens[tokenNameIndex].sellBook[whilePrice].offers_length && tokens[tokenNameIndex].sellBook[whilePrice].offers[offers_key].amount == 0){
						tokens[tokenNameIndex].amountSellPrices--;
						if (whilePrice == tokens[tokenNameIndex].sellBook[whilePrice].higherPrice || tokens[tokenNameIndex].buyBook[whilePrice].higherPrice == 0) {
                            tokens[tokenNameIndex].currentSellPrice = 0;
						} else {
							tokens[tokenNameIndex].currentSellPrice = tokens[tokenNameIndex].sellBook[whilePrice].higherPrice;
							tokens[tokenNameIndex].sellBook[tokens[tokenNameIndex].buyBook[whilePrice].higherPrice].lowerPrice = 0;
						}
					}
					offers_key++;
				}
				whilePrice = tokens[tokenNameIndex].currentSellPrice;
			}
			if (amountNecessary > 0){
				buyToken(symbolName, priceInWei, amountNecessary);
			}
		}
	}
	
	//Bid Limit Order
	function addBuyOffer(uint8 tokenIndex, uint priceInWei, uint amount, address who) internal{
		tokens[tokenIndex].buyBook[priceInWei].offers_length++;
		tokens[tokenIndex].buyBook[priceInWei].offers[tokens[tokenIndex].buyBook[priceInWei].offers_length] = Offer(amount, who);
		if(tokens[tokenIndex].buyBook[priceInWei].offers_length == 1){
			tokens[tokenIndex].buyBook[priceInWei].offers_key = 1;
			tokens[tokenIndex].amountBuyPrices++;
			uint currBuyPrice = tokens[tokenIndex].currentBuyPrice;
			uint lowestBuyPrice = tokens[tokenIndex].lowestBuyPrice;
			if(lowestBuyPrice == 0 || lowestBuyPrice > priceInWei){
				if(currBuyPrice == 0){
					tokens[tokenIndex].currentBuyPrice = priceInWei;
					tokens[tokenIndex].buyBook[priceInWei].higherPrice = priceInWei;
					tokens[tokenIndex].buyBook[priceInWei].lowerPrice = 0;
				}else{
					tokens[tokenIndex].buyBook[lowestBuyPrice].lowerPrice = priceInWei;
					tokens[tokenIndex].buyBook[priceInWei].higherPrice = lowestBuyPrice;
					tokens[tokenIndex].buyBook[priceInWei].lowerPrice = 0;
				}
				tokens[tokenIndex].lowestBuyPrice = priceInWei;
			}else if(currBuyPrice < priceInWei){
				tokens[tokenIndex].buyBook[currBuyPrice].higherPrice = priceInWei;
                tokens[tokenIndex].buyBook[priceInWei].higherPrice = priceInWei;
                tokens[tokenIndex].buyBook[priceInWei].lowerPrice = currBuyPrice;
				tokens[tokenIndex].currentBuyPrice = priceInWei;
			}else{
				uint buyPrice = tokens[tokenIndex].currentBuyPrice;
				bool foundPos = false;
				while (buyPrice > 0 && !foundPos) {
                    if (buyPrice < priceInWei && tokens[tokenIndex].buyBook[buyPrice].higherPrice > priceInWei) {
						tokens[tokenIndex].buyBook[priceInWei].lowerPrice = buyPrice;
						tokens[tokenIndex].buyBook[priceInWei].higherPrice = tokens[tokenIndex].buyBook[buyPrice].higherPrice;
						tokens[tokenIndex].buyBook[tokens[tokenIndex].buyBook[buyPrice].higherPrice].lowerPrice = priceInWei;
						tokens[tokenIndex].buyBook[buyPrice].higherPrice = priceInWei;
						foundPos = true;
					}
					buyPrice = tokens[tokenIndex].buyBook[buyPrice].lowerPrice;
				}
			}
		}
	}
	
	//New Order - Ask Order
	function sellToken(string memory symbolName, uint priceInWei, uint amount) public {
        uint8 tokenNameIndex = getSymbolIndexOrThrow(symbolName);
        uint total_amount_ether_necessary = 0;
		uint total_amount_ether_available = 0;
		total_amount_ether_necessary = amount*priceInWei;
		require(total_amount_ether_necessary >= amount);
        require(total_amount_ether_necessary >= priceInWei);
        require(tokenBalanceForAddress[msg.sender][tokenNameIndex] >= amount);
        require(tokenBalanceForAddress[msg.sender][tokenNameIndex] - amount >= 0);
		require(balanceEthForAddress[msg.sender] + total_amount_ether_necessary >= balanceEthForAddress[msg.sender]);
		tokenBalanceForAddress[msg.sender][tokenNameIndex] -= amount;
		if (tokens[tokenNameIndex].amountBuyPrices == 0 || tokens[tokenNameIndex].currentBuyPrice < priceInWei) {
			addSellOffer(tokenNameIndex, priceInWei, amount, msg.sender);
			emit LimitSellOrderCreated(tokenNameIndex, msg.sender, amount, priceInWei, tokens[tokenNameIndex].sellBook[priceInWei].offers_length);
		} else {
			uint whilePrice = tokens[tokenNameIndex].currentBuyPrice;
            uint amountNecessary = amount;
			uint offers_key;
			while(whilePrice >= priceInWei && amountNecessary > 0){
				offers_key = tokens[tokenNameIndex].buyBook[whilePrice].offers_key;
				while (offers_key <= tokens[tokenNameIndex].buyBook[whilePrice].offers_length && amountNecessary > 0) {
					uint volumeAtPriceFromAddress = tokens[tokenNameIndex].buyBook[whilePrice].offers[offers_key].amount;
					if (volumeAtPriceFromAddress <= amountNecessary) {
						total_amount_ether_available = volumeAtPriceFromAddress * whilePrice;
						require(tokenBalanceForAddress[msg.sender][tokenNameIndex] >= volumeAtPriceFromAddress);
						require(tokenBalanceForAddress[msg.sender][tokenNameIndex] >= volumeAtPriceFromAddress);
						require(tokenBalanceForAddress[msg.sender][tokenNameIndex] - volumeAtPriceFromAddress >= 0);
                        require(tokenBalanceForAddress[tokens[tokenNameIndex].buyBook[whilePrice].offers[offers_key].who][tokenNameIndex] + volumeAtPriceFromAddress >= tokenBalanceForAddress[tokens[tokenNameIndex].buyBook[whilePrice].offers[offers_key].who][tokenNameIndex]);
						require(balanceEthForAddress[msg.sender] + total_amount_ether_available >= balanceEthForAddress[msg.sender]);
						tokenBalanceForAddress[tokens[tokenNameIndex].buyBook[whilePrice].offers[offers_key].who][tokenNameIndex] += volumeAtPriceFromAddress;
                        tokens[tokenNameIndex].buyBook[whilePrice].offers[offers_key].amount = 0;
                        balanceEthForAddress[msg.sender] += total_amount_ether_available;
                        tokens[tokenNameIndex].buyBook[whilePrice].offers_key++;
						emit SellOrderFulfilled(tokenNameIndex, volumeAtPriceFromAddress, whilePrice, offers_key);
						amountNecessary -= volumeAtPriceFromAddress;
					} else {
						require(volumeAtPriceFromAddress - amountNecessary > 0);
						total_amount_ether_necessary = amountNecessary * whilePrice;
						require(tokenBalanceForAddress[msg.sender][tokenNameIndex] >= amountNecessary);
						tokenBalanceForAddress[msg.sender][tokenNameIndex] -= amountNecessary;
						require(tokenBalanceForAddress[msg.sender][tokenNameIndex] >= amountNecessary);
                        require(balanceEthForAddress[msg.sender] + total_amount_ether_necessary >= balanceEthForAddress[msg.sender]);
						require(tokenBalanceForAddress[tokens[tokenNameIndex].buyBook[whilePrice].offers[offers_key].who][tokenNameIndex] + amountNecessary >= tokenBalanceForAddress[tokens[tokenNameIndex].buyBook[whilePrice].offers[offers_key].who][tokenNameIndex]);
						tokens[tokenNameIndex].buyBook[whilePrice].offers[offers_key].amount -= amountNecessary;
                        balanceEthForAddress[msg.sender] += total_amount_ether_necessary;
						tokenBalanceForAddress[tokens[tokenNameIndex].buyBook[whilePrice].offers[offers_key].who][tokenNameIndex] += amountNecessary;
						emit SellOrderFulfilled(tokenNameIndex, amountNecessary, whilePrice, offers_key);
						amountNecessary = 0;
					}
					if (offers_key == tokens[tokenNameIndex].buyBook[whilePrice].offers_length && tokens[tokenNameIndex].buyBook[whilePrice].offers[offers_key].amount == 0) {
						 tokens[tokenNameIndex].amountBuyPrices--;
						 if (whilePrice == tokens[tokenNameIndex].buyBook[whilePrice].lowerPrice || tokens[tokenNameIndex].buyBook[whilePrice].lowerPrice == 0) {
							tokens[tokenNameIndex].currentBuyPrice = 0;
						} else {
							tokens[tokenNameIndex].currentBuyPrice = tokens[tokenNameIndex].buyBook[whilePrice].lowerPrice;
							tokens[tokenNameIndex].buyBook[tokens[tokenNameIndex].buyBook[whilePrice].lowerPrice].higherPrice = tokens[tokenNameIndex].currentBuyPrice;
						}
					}
					offers_key++;
				}
				whilePrice = tokens[tokenNameIndex].currentBuyPrice;
			}
			if(amountNecessary > 0){
				sellToken(symbolName, priceInWei, amountNecessary);
			}
		}
	}
	
	//Ask Limit Order Logic
	function addSellOffer(uint8 tokenIndex, uint priceInWei, uint amount, address who) internal {
        tokens[tokenIndex].sellBook[priceInWei].offers_length++;
		tokens[tokenIndex].sellBook[priceInWei].offers[tokens[tokenIndex].sellBook[priceInWei].offers_length] = Offer(amount, who);
		if (tokens[tokenIndex].sellBook[priceInWei].offers_length == 1) {
			tokens[tokenIndex].sellBook[priceInWei].offers_key = 1;
			tokens[tokenIndex].amountSellPrices++;
			uint currSellPrice = tokens[tokenIndex].currentSellPrice;
			uint highestSellPrice = tokens[tokenIndex].highestSellPrice;
            if (highestSellPrice == 0 || highestSellPrice < priceInWei) {
				if (currSellPrice == 0) {
					tokens[tokenIndex].currentSellPrice = priceInWei;
                    tokens[tokenIndex].sellBook[priceInWei].higherPrice = 0;
					tokens[tokenIndex].sellBook[priceInWei].lowerPrice = 0;
				} else {
					tokens[tokenIndex].sellBook[highestSellPrice].higherPrice = priceInWei;
                    tokens[tokenIndex].sellBook[priceInWei].lowerPrice = highestSellPrice;
					tokens[tokenIndex].sellBook[priceInWei].higherPrice = 0;
				}
				tokens[tokenIndex].highestSellPrice = priceInWei;
			}else if (currSellPrice > priceInWei){
				tokens[tokenIndex].sellBook[currSellPrice].lowerPrice = priceInWei;
                tokens[tokenIndex].sellBook[priceInWei].higherPrice = currSellPrice;
                tokens[tokenIndex].sellBook[priceInWei].lowerPrice = 0;
				tokens[tokenIndex].currentSellPrice = priceInWei;
			} else {
				uint sellPrice = tokens[tokenIndex].currentSellPrice;
                bool foundPos = false;
                while (sellPrice > 0 && !foundPos) {
					if (sellPrice < priceInWei && tokens[tokenIndex].sellBook[sellPrice].higherPrice > priceInWei) {
						tokens[tokenIndex].sellBook[priceInWei].lowerPrice = sellPrice;
						tokens[tokenIndex].sellBook[priceInWei].higherPrice = tokens[tokenIndex].sellBook[sellPrice].higherPrice;
						tokens[tokenIndex].sellBook[tokens[tokenIndex].sellBook[sellPrice].higherPrice].lowerPrice = priceInWei;
						tokens[tokenIndex].sellBook[sellPrice].higherPrice = priceInWei;
						foundPos = true;
					}
					sellPrice = tokens[tokenIndex].sellBook[sellPrice].higherPrice;
				}
			}
		}
	}
	
	//Cancel Order
	function cancelOrder(string memory symbolName, bool isSellOrder, uint priceInWei, uint offerKey) public {
        uint8 symbolIndex = getSymbolIndexOrThrow(symbolName);
        if (isSellOrder) {
            require(tokens[symbolIndex].sellBook[priceInWei].offers[offerKey].who == msg.sender);
            uint tokensAmount = tokens[symbolIndex].sellBook[priceInWei].offers[offerKey].amount;
            require(tokenBalanceForAddress[msg.sender][symbolIndex] + tokensAmount >= tokenBalanceForAddress[msg.sender][symbolNameIndex]);
            tokenBalanceForAddress[msg.sender][symbolIndex] += tokensAmount;
            tokens[symbolIndex].sellBook[priceInWei].offers[offerKey].amount = 0;
            emit SellOrderCancelled(symbolIndex, priceInWei, offerKey);
        } else {
            require(tokens[symbolIndex].buyBook[priceInWei].offers[offerKey].who == msg.sender);
            uint etherToRefund = tokens[symbolIndex].buyBook[priceInWei].offers[offerKey].amount * priceInWei;
            require(balanceEthForAddress[msg.sender] + etherToRefund >= balanceEthForAddress[msg.sender]);
            balanceEthForAddress[msg.sender] += etherToRefund;
            tokens[symbolIndex].buyBook[priceInWei].offers[offerKey].amount = 0;
            emit BuyOrderCancelled(symbolNameIndex, priceInWei, offerKey);
        }
    }
}