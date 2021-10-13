//var YourContract = artifacts.require("YourContract");
var DividendsContract = artifacts.require("DividendsContract");
var DividendsGroupContract = artifacts.require("DividendsGroupContract");

function printSize(instance) {
    var bytecode = instance.constructor._json.bytecode;
    var deployed = instance.constructor._json.deployedBytecode;
    var sizeOfB  = bytecode.length / 2;
    var sizeOfD  = deployed.length / 2;
    console.log("size of bytecode in bytes = ", sizeOfB);
    console.log("size of deployed in bytes = ", sizeOfD);
    console.log("initialisation and constructor code in bytes = ", sizeOfB - sizeOfD);
}
    
    
contract('Dividends', function(accounts) {
    it("get the size of the contract", async () => {
        let instance;
        instance = await DividendsContract.new();
        printSize(instance);
    });
});

contract('DividendsGroupContract', function(accounts) {
    it("get the size of the contract", async () => {
        let instance;
        instance = await DividendsGroupContract.new();
        printSize(instance);
    });
});