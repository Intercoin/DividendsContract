# DividendsContract
Operates pools for distributing dividends to reward investors staking ERC20 token or liquidity pool tokens.

## Docs contracts
- [DividendsContract](/docs/md/DividendsContract.md) ([abi](/docs/abi/DividendsContract.json))
- [DividendsContractUNI](/docs/md/DividendsContractUNI.md) ([abi](/docs/abi/DividendsContractUNI.json))
- [DividendsFactory](/docs/md/DividendsFactory.md) ([abi](/docs/abi/DividendsFactory.json))
- [DividendsGroupContract](/docs/md/DividendsGroupContract.md) ([abi](/docs/abi/DividendsGroupContract.json))
- [DividendsGroupFactory](/docs/md/DividendsGroupFactory.md) ([abi](/docs/abi/DividendsGroupFactory.json))

## Install
1. deploy instances: DividendsContract and DividendsGroupContract
2. deploy factories: DividendsFactory and DividendsGroupFactory
3. initialize factories with instances deployed in point 1.
4. that's all. now our factories can produce new contract instances by calling factory method `produceInstance`

## General 
how it works.
Below we describe a lot of tokens:  
- T1 - stake erc20/erc777tokens  
- T2 - dividends erc20/erc777tokens  
- T3 - rewards erc20/erc777 tokens  

User can stake  T1 token by sending it to DividendsContract.  
DividendsContract receiving T1 tokens and send T2 tokens back to user and hold them for a some period.  
In turn, DividendsGroupContract can `disburse` such DividendsContract any T3 tokens(that was setup while initialization in DividendsContract) to users as reward for hold T2 tokens.  
User can `claim` to obtain T3 tokens or can `redeem` to get back T1 tokens(T2 will be burn)  
