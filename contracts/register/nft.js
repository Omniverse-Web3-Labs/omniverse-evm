const Web3 = require('web3');
const BN = require('bn.js');
const fs = require('fs');
const eccrypto = require('eccrypto');
const keccak256 = require('keccak256');
const secp256k1 = require('secp256k1');
const ethereum = require('./ethereum');
const { program } = require('commander');
const config = require('config');
const utils = require('./utils');

const TRANSFER = 0;
const MINT = 1;
const BURN = 2;

let web3;
let netConfig;
let chainId;
let skywalkerNonFungibleContract;

// Private key
let secret = JSON.parse(fs.readFileSync('./register/.secret').toString());
let testAccountPrivateKey = secret.sks[secret.index];
let privateKeyBuffer = Buffer.from(utils.toByteArray(testAccountPrivateKey));
let publicKeyBuffer = eccrypto.getPublic(privateKeyBuffer);
let publicKey = '0x' + publicKeyBuffer.toString('hex').slice(2);
// the first account pk: 0x878fc1c8fe074eec6999cd5677bf09a58076529c2e69272e1b751c2e6d9f9d13ed0165bc1edfe149e6640ea5dd1dc27f210de6cbe61426c988472e7c74f4cc29
// the first account address: 0xD6d27b2E732852D8f8409b1991d6Bf0cB94dd201
// the second account pk: 0x1c0ae2fe60e7b9e91b3690626318c8759147c6daf96147d886d37b4df8dd8829db901b1a4bbb9374b35322660503495597332b3944e49985fa2e827797634799
// the second account address: 0x30ad2981E83615001fe698b6fBa1bbCb52C19Dfa
// the third account pk: 0xcc643d259ada7570872ef9a4fd30b196f5b3a3bae0a6ffabd57fb6a3367fb6d3c5f45cb61994dbccd619bb6f11c522f71a5f636781a1f234fd79ec93bea579d3
// the third account address: 0x8408925fD39071270Ed1AcA5d618e1c79be08B27
// the forth account pk: 0xfb73e1e37a4999060a9a9b1e38a12f8a7c24169caa39a2fb304dc3506dd2d797f8d7e4dcd28692ae02b7627c2aebafb443e9600e476b465da5c4dddbbc3f2782
// the forth account address: 0x04e5d0f5478849C94F02850bFF91113d8F02864D

function _init(chainName) {
    let netConfig = config.get(chainName);
    if (!netConfig) {
        console.log('Config of chain (' + chainName + ') not exists');
        return [false];
    }

    let skywalkerNonFungibleAddress = netConfig.skywalkerNonFungibleAddress;
    // Load contract abi, and init contract object
    const skywalkerNonFungibleRawData = fs.readFileSync('./build/contracts/SkywalkerNonFungible.json');
    const skywalkerNonFungibleAbi = JSON.parse(skywalkerNonFungibleRawData).abi;

    let chainId = netConfig.omniverseChainId;
    let web3 = new Web3(netConfig.nodeAddress);
    web3.eth.handleRevert = true;
    let skywalkerNonFungibleContract = new web3.eth.Contract(skywalkerNonFungibleAbi, skywalkerNonFungibleAddress);

    return [true, web3, skywalkerNonFungibleContract, chainId, netConfig];
}

function init(chainName) {
    let ret = _init(chainName);

    if (ret[0]) {
        web3 = ret[1];
        skywalkerNonFungibleContract = ret[2];
        chainId = ret[3];
        netConfig = ret[4];
    }

    return ret[0];
}

let signData = (hash, sk) => {
    let signature = secp256k1.ecdsaSign(Uint8Array.from(hash), Uint8Array.from(sk));
    return '0x' + Buffer.from(signature.signature).toString('hex') + (signature.recid == 0 ? '1b' : '1c');
}

let getRawData = (txData, op, params) => {
    let bData;
    if (op == MINT) {
        bData = Buffer.concat([Buffer.from(new BN(op).toString('hex').padStart(2, '0'), 'hex'), Buffer.from(params[0].slice(2), 'hex'), Buffer.from(new BN(params[1]).toString('hex').padStart(32, '0'), 'hex')]);
    }
    else if (op == TRANSFER) {
        bData = Buffer.concat([Buffer.from(new BN(op).toString('hex').padStart(2, '0'), 'hex'), Buffer.from(params[0].slice(2), 'hex'), Buffer.from(new BN(params[1]).toString('hex').padStart(32, '0'), 'hex')]);
    }
    else if (op == BURN) {
        bData = Buffer.concat([Buffer.from(new BN(op).toString('hex').padStart(2, '0'), 'hex'), Buffer.from(params[0].slice(2), 'hex'), Buffer.from(new BN(params[1]).toString('hex').padStart(32, '0'), 'hex')]);
    }
    let ret = Buffer.concat([Buffer.from(new BN(txData.nonce).toString('hex').padStart(32, '0'), 'hex'), Buffer.from(new BN(txData.chainId).toString('hex').padStart(8, '0'), 'hex'),
        Buffer.from(txData.initiateSC.slice(2), 'hex'), Buffer.from(txData.from.slice(2), 'hex'), bData]);
    return ret;
}

async function initialize(baseUri, members) {
    await ethereum.sendTransaction(web3, netConfig.chainId, skywalkerNonFungibleContract, 'setCoolingDownTime',
        testAccountPrivateKey, [netConfig.coolingDown]);
    await ethereum.sendTransaction(web3, netConfig.chainId, skywalkerNonFungibleContract, 'setBaseURI', testAccountPrivateKey, [baseUri]);
    await ethereum.sendTransaction(web3, netConfig.chainId, skywalkerNonFungibleContract, 'setMembers', testAccountPrivateKey, [members]);
}

async function mint(to, tokenId) {
    let nonce = await ethereum.contractCall(skywalkerNonFungibleContract, 'getTransactionCount', [publicKey]);
    let txData = {
        nonce: nonce,
        chainId: chainId,
        initiateSC: netConfig.skywalkerNonFungibleAddress,
        from: publicKey,
        payload: web3.eth.abi.encodeParameters(['uint8', 'bytes', 'uint256'], [MINT, to, tokenId]),
    };
    console.log(txData);
    let bData = getRawData(txData, MINT, [to, tokenId]);
    let hash = keccak256(bData);
    txData.signature = signData(hash, privateKeyBuffer);
    await ethereum.sendTransaction(web3, netConfig.chainId, skywalkerNonFungibleContract, 'sendOmniverseTransaction', testAccountPrivateKey, [txData]);
}

async function transfer(to, tokenId) {
    let nonce = await ethereum.contractCall(skywalkerNonFungibleContract, 'getTransactionCount', [publicKey]);
    let txData = {
        nonce: nonce,
        chainId: chainId,
        initiateSC: netConfig.skywalkerNonFungibleAddress,
        from: publicKey,
        payload: web3.eth.abi.encodeParameters(['uint8', 'bytes', 'uint256'], [TRANSFER, to, tokenId]),
    };
    let bData = getRawData(txData, TRANSFER, [to, tokenId]);
    let hash = keccak256(bData);
    txData.signature = signData(hash, privateKeyBuffer);
    await ethereum.sendTransaction(web3, netConfig.chainId, skywalkerNonFungibleContract, 'sendOmniverseTransaction', testAccountPrivateKey, [txData]);
}

async function burn(from, tokenId) {
    let nonce = await ethereum.contractCall(skywalkerNonFungibleContract, 'getTransactionCount', [publicKey]);
    let txData = {
        nonce: nonce,
        chainId: chainId,
        initiateSC: netConfig.skywalkerNonFungibleAddress,
        from: publicKey,
        payload: web3.eth.abi.encodeParameters(['uint8', 'bytes', 'uint256'], [BURN, from, tokenId]),
    };
    let bData = getRawData(txData, BURN, [from, tokenId]);
    let hash = keccak256(bData);
    txData.signature = signData(hash, privateKeyBuffer);
    await ethereum.sendTransaction(web3, netConfig.chainId, skywalkerNonFungibleContract, 'sendOmniverseTransaction', testAccountPrivateKey, [txData]);
}

async function sync(toChain, pk) {
    let toChainInfo = _init(toChain);
    if (!toChainInfo[0]) {
        console.log('error init', toChain);
        return;
    }

    let fromNonce = await ethereum.contractCall(skywalkerNonFungibleContract, 'getTransactionCount', [pk]);
    let toNonce = await ethereum.contractCall(toChainInfo[2], 'getTransactionCount', [pk]);
    console.log('nonce', toNonce, fromNonce);
    for (let n = parseInt(toNonce); n < parseInt(fromNonce); n++) {
        let message = await ethereum.contractCall(skywalkerNonFungibleContract, 'getTransactionData', [pk, n]);
        let ret = await ethereum.sendTransaction(toChainInfo[1], toChainInfo[5].chainId, toChainInfo[3], 'sendOmniverseTransaction',
        testAccountPrivateKey, [message.txData]);
        if (!ret) {
            console.log('Send message failed');
        }
    }
}

async function getNonce(pk) {
    let nonce = await ethereum.contractCall(skywalkerNonFungibleContract, 'getTransactionCount', [pk]);
    console.log(nonce);
}

async function omniverseBalanceOf(pk) {
    let amount = await ethereum.contractCall(skywalkerNonFungibleContract, 'omniverseBalanceOf', [pk]);
    console.log('amount', amount);
}

async function getOtherInformation(pk) {
    let nonce = await ethereum.contractCall(skywalkerNonFungibleContract, 'getTransactionCount', [pk]);
    let amount = await ethereum.contractCall(skywalkerNonFungibleContract, 'omniverseBalanceOf', [pk]);
    let members = await ethereum.contractCall(skywalkerNonFungibleContract, 'getMembers', []);
    let owner = await ethereum.contractCall(skywalkerNonFungibleContract, 'owner', []);
    let delayedCount = await ethereum.contractCall(skywalkerNonFungibleContract, 'getDelayedTxCount', []);
    let tx = await ethereum.contractCall(skywalkerNonFungibleContract, 'getExecutableDelayedTx', []);
    let cdTime = await ethereum.contractCall(skywalkerNonFungibleContract, 'cdTime', []);
    let cache = await ethereum.contractCall(skywalkerNonFungibleContract, 'transactionCache', [pk]);
    console.log('nonce', nonce);
    console.log('amount', amount);
    console.log('members', members);
    console.log('owner', owner);
    console.log('delayedCount', delayedCount);
    console.log('tx', tx);
    console.log('cdTime', cdTime);
    console.log('cache', cache);
}

async function balanceOf(address) {
    let amount = await ethereum.contractCall(skywalkerNonFungibleContract, 'balanceOf', [address]);
    console.log('amount', amount);
}

async function omniverseOwnerOf(tokenId) {
    let tokenOwner = await ethereum.contractCall(skywalkerNonFungibleContract, 'omniverseOwnerOf', [tokenId]);
    console.log('tokenOwner', tokenOwner);
}

async function ownerOf(tokenId) {
    let tokenOwner = await ethereum.contractCall(skywalkerNonFungibleContract, 'ownerOf', [tokenId]);
    console.log('tokenOwner', tokenOwner);
}

(async function () {
    function list(val) {
		return val.split(',')
	}

    program
        .version('0.1.0')
        .option('-i, --initialize <chain name>,<base uri>,<chain id>|<contract address>,...', 'Initialize omnioverse contracts', list)
        .option('-t, --transfer <chain name>,<pk>,<tokenId>', 'Transfer token', list)
        .option('-m, --mint <chain name>,<pk>,<tokenId>', 'Mint token', list)
        .option('-b, --burn <chain name>,<pk>,<tokenId>', 'Burn token', list)
        .option('-ob, --omniBalance <chain name>,<pk>', 'Query the balance of the omniverse token', list)
        .option('-ba, --balance <chain name>,<address>', 'Query the balance of the local token', list)
        .option('-oo, --omniOwner <chain name>,<tokenId>', 'Query the omniverse owner of the specified token', list)
        .option('-ow, --owner <chain name>,<tokenId>', 'Query the owner of the specified token', list)
        .option('-tr, --trigger <chain name>', 'Trigger the execution of delayed transactions', list)
        .option('-d, --delayed <chain name>', 'Query an executable delayed transation', list)
        .option('-s, --switch <index>', 'Switch the index of private key to be used')
        .option('-sc, --sync <chain name>,<to chain>,<pk>', 'Sync messages from one to the other chain', list)
        .option('-n, --nonce <chain name>,<pk>', 'Nonce of a pk on a chain', list)
        .option('--other <chain name>,<pk>', 'Get other information of an account', list)
        .parse(process.argv);

    if (program.opts().initialize) {
        if (program.opts().initialize.length <= 1) {
            console.log('At least 2 arguments are needed');
            return;
        }
        
        if (!init(program.opts().initialize[0])) {
            return;
        }

        let members = [];
        let param = program.opts().initialize.slice(2);
        for (let i = 0; i < param.length; i++) {
            let m = param[i].split('|');
            members.push({
                chainId: m[0],
                contractAddr: m[1]
            });
        }
        await initialize(program.opts().initialize[1], members);
    }
    else if (program.opts().transfer) {
        if (program.opts().transfer.length != 3) {
            console.log('3 arguments are needed, but ' + program.opts().transfer.length + ' provided');
            return;
        }
        
        if (!init(program.opts().transfer[0])) {
            return;
        }
        await transfer(program.opts().transfer[1], program.opts().transfer[2]);
    }
    else if (program.opts().mint) {
        if (program.opts().mint.length != 3) {
            console.log('3 arguments are needed, but ' + program.opts().mint.length + ' provided');
            return;
        }
        
        if (!init(program.opts().mint[0])) {
            return;
        }
        await mint(program.opts().mint[1], program.opts().mint[2]);
    }
    else if (program.opts().burn) {
        if (program.opts().burn.length != 3) {
            console.log('3 arguments are needed, but ' + program.opts().burn.length + ' provided');
            return;
        }
        
        if (!init(program.opts().burn[0])) {
            return;
        }
        await burn(program.opts().burn[1], program.opts().burn[2]);
    }
    else if (program.opts().omniBalance) {
        if (program.opts().omniBalance.length != 2) {
            console.log('2 arguments are needed, but ' + program.opts().omniBalance.length + ' provided');
            return;
        }
        
        if (!init(program.opts().omniBalance[0])) {
            return;
        }
        await omniverseBalanceOf(program.opts().omniBalance[1]);
    }
    else if (program.opts().balance) {
        if (program.opts().balance.length != 2) {
            console.log('2 arguments are needed, but ' + program.opts().balance.length + ' provided');
            return;
        }
        
        if (!init(program.opts().balance[0])) {
            return;
        }
        await balanceOf(program.opts().balance[1]);
    }
    else if (program.opts().omniOwner) {
        if (program.opts().omniOwner.length != 2) {
            console.log('2 arguments are needed, but ' + program.opts().omniOwner.length + ' provided');
            return;
        }
        
        if (!init(program.opts().omniOwner[0])) {
            return;
        }
        await omniverseOwnerOf(program.opts().omniOwner[1]);
    }
    else if (program.opts().owner) {
        if (program.opts().owner.length != 2) {
            console.log('2 arguments are needed, but ' + program.opts().owner.length + ' provided');
            return;
        }
        
        if (!init(program.opts().owner[0])) {
            return;
        }
        await ownerOf(program.opts().owner[1]);
    }
    else if (program.opts().trigger) {
        if (program.opts().trigger.length != 1) {
            console.log('1 arguments are needed, but ' + program.opts().trigger.length + ' provided');
            return;
        }
        
        if (!init(program.opts().trigger[0])) {
            return;
        }
        await trigger();
    }
    else if (program.opts().delayed) {
        if (program.opts().delayed.length != 1) {
            console.log('1 arguments are needed, but ' + program.opts().delayed.length + ' provided');
            return;
        }
        
        if (!init(program.opts().delayed[0])) {
            return;
        }
        await getDelayedTx();
    }
    else if (program.opts().sync) {
        if (program.opts().sync.length != 3) {
            console.log('3 arguments are needed, but ' + program.opts().sync.length + ' provided');
            return;
        }
        
        if (!init(program.opts().sync[0])) {
            return;
        }
        await sync(program.opts().sync[1], program.opts().sync[2]);
    }
    else if (program.opts().nonce) {
        if (program.opts().nonce.length != 2) {
            console.log('2 arguments are needed, but ' + program.opts().nonce.length + ' provided');
            return;
        }
        
        if (!init(program.opts().nonce[0])) {
            return;
        }
        await getNonce(program.opts().nonce[1]);
    }
    else if (program.opts().other) {
        if (program.opts().other.length != 2) {
            console.log('2 arguments are needed, but ' + program.opts().other.length + ' provided');
            return;
        }
        
        if (!init(program.opts().other[0])) {
            return;
        }
        await getOtherInformation(program.opts().other[1]);
    }
    else if (program.opts().switch) {
        secret.index = parseInt(program.opts().switch);
        fs.writeFileSync('./register/.secret', JSON.stringify(secret, null, '\t'));
    }
}());
