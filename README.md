# MiniYearn

This is a smart contract for depositing Ether and gain interest through the AAVE pool. 

The contract MiniYearn.sol allows the users to deposit their Ether and receive an ERC20 token (MY) as deposit representation.
Then the contract deposits the user's Ether through the IWrappedTokenGatewayV3 contract from AAVE into the AAVE pool, where the
interest is earned.  
Users can withdraw their funds and interest via the contract MiniYearn at any time.
  
![](https://github.com/carmar0/MiniYearn/blob/main/MiniYearn.JPG)
