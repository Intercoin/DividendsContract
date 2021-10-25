const BigNumber = require('bignumber.js');
const truffleAssert = require('truffle-assertions');

var SharesLibTest = artifacts.require("SharesLibTest");

const helper = require("../helpers/truffleTestHelper");

require('@openzeppelin/test-helpers/configure')({ web3 });
const { singletons } = require('@openzeppelin/test-helpers');

contract('SharesLib', (accounts) => {
    
    // Setup accounts.
    const accountOne = accounts[0];
    const accountTwo = accounts[1];
    const accountThree = accounts[2];
    const accountFourth = accounts[3];
    const accountFive = accounts[4];
    const accountSix = accounts[5];
    const accountSeven = accounts[6];
    const accountEight = accounts[7];
    const accountNine = accounts[8];
    const accountTen = accounts[9];
    
    const zeroAddress = "0x0000000000000000000000000000000000000000";
    
    //const noneExistTokenID = '99999999';
    const oneToken = "1000000000000000000";
    const twoToken = "2000000000000000000";
    const oneToken07 = "700000000000000000";
    const oneToken05 = "500000000000000000";    
    const oneToken03 = "300000000000000000";    
    var DividendsContractInstance, 
        DividendsFactoryInstance, 
        DividendsGroupFactoryInstance,
        ERC20MintableInstanceToken,
        ERC777MintableInstanceToken,
        ERC20MintableInstanceDividend,
        ERC777MintableInstanceDividend
    ;
        
    function getArgs(tr, eventname) {
        for (var i in tmpTr.logs) {
            if (eventname == tmpTr.logs[i].event) {
                return tmpTr.logs[i].args;
            }
        }
        return '';
    }
    
    before(async () => {
        erc1820 = await singletons.ERC1820Registry(accountNine);
        
    });
    
    beforeEach(async () => {
        SharesLibTestInstance = await SharesLibTest.new({ from: accountFive });
        
    });

    it('should produce instances by factories', async () => {
        let arr = [1,6,8,11,13,15,17,25,22,27];
        for (var i in arr) {
            await SharesLibTestInstance.justInsertKey(arr[i]);    
        }
        let arr2 = [
            [1,1],[2,1],[3,1],[4,1],[5,1],
            [6,6],[7,6],
            [8,8],[9,8],[10,8],
            [11,11],[12,11],
            [13,13],[14,13],
            [15,15],[16,15],
            [17,17],[18,17],[19,17],[20,17],[21,17],[22,17],
            [25,25],[26,25],
            [27,27],[28,27]
        ];
        for (var i in arr2) {
            assert.equal((await SharesLibTestInstance.getLessIndex(arr2[i][0])).toString(), (arr2[i][1]).toString(), 'getLessIndex error');
        }
      
    });
    
});