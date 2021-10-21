# DividendsGroupContract

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
		<td><a href="#adddividendcontracts">addDividendContracts</a></td>
		<td>owner</td>
		<td>addiing dividendsContracts to group</td>
	</tr>
    <tr>
		<td><a href="#removedividendcontracts">removeDividendContracts</a></td>
		<td>owner</td>
		<td>removing  dividendsContracts from group</td>
	</tr>
    <tr>
		<td><a href="#getdividendcontracts">getDividendContracts</a></td>
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
token|address| token address that will be sending to DividendsContract
interval|uint256|interval in seconds. only DividendsContract with such interval can be added into the Group


#### addDividendContracts    
Params:   
name  | type | description
--|--|--
dividendsContractsArray|address[]|array of dividends contracts addresses to add

#### removeDividendContracts    
Params:   
name  | type | description
--|--|--
dividendsContractsArray|address[]|array of dividends contracts addresses to remove

#### getDividendContracts   
getting dividends contracts addresses from the list    
Params:   
name  | type | description
--|--|--
<td colspan=3>no params</td>   

Returns:   
name  | type | description
--|--|--
dividendsContractsArray|address[]|array of dividends contracts addresses in the list

#### disburse
disburse dividends through DividendsContract in the list      
Params:   
name  | type | description
--|--|--

## Example to use

Contract are used for disburse tokens for investors in Di
