// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol";

contract Dex {

    using SafeMath for uint; 

    enum Side {
        BUY,
        SELL
    }

    struct Token {
        bytes32 ticker;
        address tokenAddress;
    }
    
    struct Order{
        uint id;
        address trader;
        Side side;
        bytes32 ticker;
        uint amount;
        uint filled;
        uint price;
        uint date;
    }
    mapping(bytes32 => Token) public tokens;
    bytes32[] public tokenList;
    mapping(address => mapping(bytes32 =>uint)) public traderBalances;
    mapping(bytes32 => mapping(uint => Order[])) public orderBook;
    address public admin;
    uint public nextOrderId;
    uint public nextTradeId;
    bytes32 constant DAI = bytes32('DAI');

    event NewTrade(uint tradeId, 
    uint orderId, 
    bytes32 indexed ticker, 
    address indexed trader1,
    address indexed trader2,
    uint amount,
    uint price,
    uint date
    );

    constructor() {
        admin = msg.sender;
    }

    function addToken(bytes32 ticker, address tokenAddress) external onlyAdmin{
        tokens[ticker] = Token(ticker,tokenAddress);
        tokenList.push(ticker);
    }

    function deposit(
        uint amount,
        bytes32 ticker
    ) external tokenExists(ticker){
        IERC20(tokens[ticker].tokenAddress).transferFrom(msg.sender,address(this),amount);
        traderBalances[msg.sender][ticker] = traderBalances[msg.sender][ticker].add(amount);
    }

    function withdraw(
        uint amount,
        bytes32 ticker
    ) external tokenExists(ticker){
        require(traderBalances[msg.sender][ticker] >= amount,"Balance too low");
         traderBalances[msg.sender][ticker] = traderBalances[msg.sender][ticker].sub(amount);
          IERC20(tokens[ticker].tokenAddress).transfer(msg.sender,amount);
       
    }

    function createLimitOrder(
        bytes32 ticker,
        uint amount,
        uint price,
        Side side 
    ) external tokenExists(ticker) tokenIsNotDai(ticker){
       
        if (side == Side.SELL){
            //A assez de token pour vendre
            require(traderBalances[msg.sender][ticker] >= amount, "token balance too low");
        }
        else{
            //A assez de DAI pour acheter
            require(traderBalances[msg.sender][DAI] >= amount.mul(price), "Not enougth DAI to pay");
       
        }
        //Notre orderBook contient des ordres de vente et d'achat
        Order[] storage orders = orderBook[ticker][uint(side)];
        orders.push(Order(
            nextOrderId,
            msg.sender,
            side,
            ticker,
            amount,
            0,
            price,
            block.timestamp
        ));
        //Ordonne les orders pour avoir prix décroissant (30,25,20,...)
        // ou croissant selon le type d'ordre
        uint i = orders.length > 0 ? orders.length - 1 : 0;
        while (i>0){
            //On achète au prix le moins cher si possible
            if (side == Side.BUY && orders[i-1].price > orders[i].price){
                break;
            }
            // On vend au prix le plus fort si possible
            if (side == Side.SELL && orders[i-1].price < orders[i].price){
                break;
            }
            Order memory order = orders[i-1];
            orders[i-1] = orders[i];
            orders[i] = order;
            i = i.sub(1);
        }
        nextOrderId = nextOrderId.add(1);
    }

    function createMarketOrder(
        bytes32 ticker,
        uint amount,
        Side side 
    ) external tokenExists(ticker) tokenIsNotDai(ticker){
        uint orderIndexBook;
        if (side == Side.SELL){
            //A assez de token pour vendre
            require(traderBalances[msg.sender][ticker] >= amount, "token balance too low");
            orderIndexBook = uint(Side.BUY);
        }
        else{
            orderIndexBook = uint(Side.SELL);
        }
       // Si c'est un ordre d'achat on récuper le book des ventes
       // Si c'est un ordre de vente, on récupere le book des achats 
       Order[] storage orders = orderBook[ticker][orderIndexBook];
       uint i;
       uint remaining = amount;
       while ( i < orders.length && remaining > 0){
           uint available = orders[i].amount.sub(orders[i].filled);
           uint matched = (remaining > available) ? available : remaining;
           remaining = remaining.sub(matched);
           orders[i].filled = orders[i].filled.add(matched);
           emit NewTrade(
               nextTradeId,
               orders[i].id,
               ticker,
               orders[i].trader,
               msg.sender,
               matched,
               orders[i].price,
               block.timestamp
           );
           if (side == Side.SELL){
               //Vente
             traderBalances[msg.sender][ticker] = traderBalances[msg.sender][ticker].sub(matched);
             traderBalances[msg.sender][DAI] = traderBalances[msg.sender][DAI].add(matched.mul(orders[i].price));
             traderBalances[orders[i].trader][ticker] =  traderBalances[orders[i].trader][ticker] .add(matched);
             traderBalances[orders[i].trader][DAI] =  traderBalances[orders[i].trader][DAI].sub(matched.mul(orders[i].price));
           
            } 
            if (side == Side.BUY){
            require( traderBalances[msg.sender][DAI] >= matched*orders[i].price,"Not enough DAI in balance");
             // Achat 
             traderBalances[msg.sender][ticker] = traderBalances[msg.sender][ticker].add(matched);
             traderBalances[msg.sender][DAI] =  traderBalances[msg.sender][DAI].sub(matched.mul(orders[i].price));
             traderBalances[orders[i].trader][ticker] =  traderBalances[orders[i].trader][ticker].sub(matched);
             traderBalances[orders[i].trader][DAI] = traderBalances[orders[i].trader][DAI].add(matched.mul(orders[i].price));
           
            }
            nextTradeId  = nextTradeId.add(1);
            i = i.add(1);
       }

       i = 0 ;
       //On supprimer tous les orders filled du storage
       // Pour cela on décale tous les éléments du tableau vers la gauche
       // et on supprime le dernier element de la liste 
       while (i < orders.length && orders[i].filled == orders[i].amount ){
           for (uint j = i ; j < orders.length - 1 ; j++){
               orders[j] = orders[j+1];
           }
           orders.pop();
            i = i.add(1);
       }
      
    
    }


      modifier onlyAdmin(){
         require(msg.sender == admin, "Only admin ");
         _;
     }

        modifier tokenExists(bytes32 ticker){
         require(tokens[ticker].tokenAddress != address(0), "Token doesn't exists");
         _;
     }

      modifier tokenIsNotDai(bytes32 ticker){
          require(ticker != DAI, 'cannot trade DAI');
         _;
     }
}