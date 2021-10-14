# DividendsFactory
Contract that can create new instance of DividendsContract via calling produceInstance

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
		<td><a href="#init">init</a></td>
		<td>anyone</td>
		<td>initializing after deploy. Can be called only once</td>
	</tr>
    <tr>
		<td><a href="#produceinstance">produceInstance</a></td>
		<td>anyone</td>
		<td>creating intance of Dividends contract</td>
	</tr>
    <tr>
		<td><a href="#producedividendslist">produceDividendsList</a></td>
		<td>anyone</td>
		<td>viewing all instances list was created by sender</td>
	</tr>
</tbody>
</table>

## Methods

#### init
initialize contract after deploy.
Params:   

name  | type | description
--|--|--
_dividendsContractInstance|address| addres of Dividends instance

#### produceInstance
Produce a new instance of Dividends contract   
Params:   

name  | type | description
--|--|--
name|string| name of Dividends Token
symbol|string|symbol of Dividends Token
defaultOperators|address[]| default operators. it's a part of erc777 token initialize
interval|uint256| interval in seconds
duration|uint256| how much interval will be tokens stake
multiplier|uint256| multiplier(in percent and mul by 1e2. means 0.05% is 5; 1% is 100; 100% is 10000). used for disburse via DividendsGroupContract
token|address| token address that will be acceptible for staking
whitelist|address[]|token address that wil be acceptible for dividends and disbursing for users

#### produceDividendsList   
returns list of produced instances
Params:   

name  | type | description
--|--|--
sender|address| addres 

## Example to use
TBD
