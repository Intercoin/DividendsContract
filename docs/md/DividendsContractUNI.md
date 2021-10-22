# DividendsContractUNI

# Latest contract instances in test networks

Binance SmartChain TestNet<br>
TBD

# Overview

Once installed will be use methods:

<table>
<thead>
	<tr>
		<th>method name</th>
		<th>called by</th>
		<th>description</th>
	</tr>
</thead>
<tbody>
	<tr>
		<td><a href="#initialize">initialize</a></td>
		<td>anyone</td>
		<td>initializing after deploy. Can be called only once if was created out of factory</td>
	</tr>
    <tr>
		<td><a href="#getinterval">getInterval</a></td>
		<td>anyone</td>
		<td>period in seconds in which contract accomulating tokens, dividends, etc</td>
	</tr>
    <tr>
		<td><a href="#getmultiplier">getMultiplier</a></td>
		<td>anyone</td>
		<td>viewing multiplier value. used by GroupContract to calculated proportions of dividends which will be send to DividendsContract</td>
	</tr>
    <tr>
		<td><a href="#getsharessum">getSharesSum</a></td>
		<td>anyone</td>
		<td>viewing shares sum in current interval</td>
	</tr>
    <tr>
		<td><a href="#claim">claim</a></td>
		<td>anyone</td>
		<td>claim dividends</td>
	</tr>
    <tr>
		<td><a href="#redeem">redeem</a></td>
		<td>anyone</td>
		<td>redeem stake tokens</td>
	</tr>
    <tr>
		<td><a href="#disburse">disburse</a></td>
		<td>anyone</td>
		<td>called externally. used to disburse dividends tokens in current interval</td>
	</tr>
    <tr>
		<td><a href="#addliquidityandstakecoin">addLiquidityAndStakeCoin</a></td>
		<td>anyone</td>
		<td>stake coin(eth)</td>
	</tr>
    <tr>
		<td><a href="#addliquidityandstaketoken">addLiquidityAndStakeToken</a></td>
		<td>anyone</td>
		<td>send tokens to add liquidity</td>
	</tr>
</tbody>
</table>


## Methods  

#### initialize
initialize contract. Should call after deploy if deployed out of factory(as single contract)
Params:   

name  | type | description
--|--|--
name_|string|Token name
symbol_|string|Token symbol
defaultOperators_|address[]| default operators. it's a part of erc777 token initialize
interval_|uint256| interval in seconds
duration_|uint256| how much interval will be tokens stake
multiplier_|uint256| multiplier(in percents and mul by 1e2. means 0.05% is 5; 1% is 100; 100% is 10000). used for disburse via DividendsGroupContract
token_|address| second token from pair <a href="https://etherscan.io/address/0x6ef5febbd2a56fab23f18a69d3fb9f4e2a70440b">ITR</a> - this token
whitelist_|address[]|token address that will be applicable for dividends and disbursing for users

#### getInterval   
Params:   
<table><thead><th>name</th><th>type</th><th>description</th></thead><tbody><tr><td colspan=3 align=center>no params</td></tr></tbody></table>

Returns:   
name  | type | description
--|--|--
interval|uint256| interval

#### getMultiplier   
Params:   
<table><thead><th>name</th><th>type</th><th>description</th></thead><tbody><tr><td colspan=3 align=center>no params</td></tr></tbody></table>  

Returns:   
name  | type | description
--|--|--
multiplier|uint256| multiplier

#### getSharesSum   
calculatig sum of shares current interval    
Params:   
name  | type | description
--|--|--
intervalIndex|uint256| current timestamp or interval index   

Returns:   
name  | type | description
--|--|--
shares|uint256| sum shares

#### claim   
claiming dividends   
Params:   
<table><thead><th>name</th><th>type</th><th>description</th></thead><tbody><tr><td colspan=3 align=center>no params</td></tr></tbody></table>   

#### redeem   
redeem dividends    
Params:   
<table><thead><th>name</th><th>type</th><th>description</th></thead><tbody><tr><td colspan=3 align=center>no params</td></tr></tbody></table>  

#### disburse    
one of the way to disburse dividends tokens     
Params:   
name  | type | description
--|--|--
token_|address| dividends token's address.  need to be approve before
amount_|uint256| dividends token's amount approved to disburse

#### addLiquidityAndStakeCoin    
one of the way to adding ETH to liquidity pool
Params:   
<table><thead><th>name</th><th>type</th><th>description</th></thead><tbody><tr><td colspan=3 align=center>no params</td></tr></tbody></table>  

#### addLiquidityAndStakeToken    
one of the way to adding tokens to liquidity pool    
Params:   
name  | type | description
--|--|--
token_|address| tokens. need to be approve before
amount_|uint256| token's amount allowed to disburse

## Example to use
TBD
