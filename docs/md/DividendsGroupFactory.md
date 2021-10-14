# DividendsGroupFactory
Contract that can create new instance of DividendsGroupContract via calling produceInstance

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
		<td>creating intance of DividendsGroupContract</td>
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
_dividendsGroupContractInstance|address| addres of DividendsGroup instance

#### produceInstance
Produce a new instance of DividendsGroup contract   
Params:   

name  | type | description
--|--|--
token|address| token address that will be sending to DividendsContract
interval|uint256|interval in seconds. only DividendsContract with such interval can be added into the Group

#### produceDividendsList   
returns list of produced instances
Params:   

name  | type | description
--|--|--
sender|address| addres 

## Example to use
TBD
