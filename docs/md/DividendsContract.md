# DividendsContract

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
		<td><a href="#init">initialize</a></td>
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
</tbody>
</table>


## Methods  

#### initialize
initialize contract. Should call after deploy if deployed out of factory(as single contract)
Params:   

name  | type | description
--|--|--
name_|string|Token name
symbol|string|Token symbol
defaultOperators|address[]| default operators. it's a part of erc777 token initialize
interval|uint256| interval in seconds
duration|uint256| how much interval will be tokens stake
multiplier|uint256| multiplier(in percent and mul by 1e2. means 0.05% is 5; 1% is 100; 100% is 10000). used for disburse via DividendsGroupContract
token|address| token address that will be acceptible for staking
whitelist|address[]|token address that wil be acceptible for dividends and disbursing for users

#### getInterval
Params:   
name  | type | description
--|--|--
<td colspan=3>no params</td>   

Returns:   
name  | type | description
--|--|--
interval|uint256| interval

#### getMultiplier   
Params:   
name  | type | description
--|--|--
<td colspan=3>no params</td>   

Returns:   
name  | type | description
--|--|--
multiplier|uint256| multiplier

#### getSharesSum   
calculatig sum of shares current intreval    
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
name  | type | description
--|--|--
<td colspan=3>no params</td>   

#### redeem   
redeem dividends    
Params:   
name  | type | description
--|--|--
<td colspan=3>no params</td>   

#### disburse    
one of the way to disburse dividends tokens     
Params:   
name  | type | description
--|--|--
token_|address| dividends token's address.  need to be allowance before
amount_|uint256| dividends token's amount allowed to disburse

## Example to use
TBD
