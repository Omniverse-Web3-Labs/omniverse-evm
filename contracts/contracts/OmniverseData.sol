// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

uint8 constant DEPOSIT = 0;
uint8 constant TRANSFER = 1;
uint8 constant WITHDRAW = 2;
uint8 constant MINT = 3;

struct OmniverseTransactionData {
    uint256 nonce;
    uint32 chainId;
    bytes initiator;
    bytes from;
    uint8 op;
    bytes data;
    uint256 amount;
    bytes signature;
}
    
struct OmniverseTx {
    OmniverseTransactionData txData;
    uint256 timestamp;
}

struct EvilTxData {
    OmniverseTx txData;
    uint256 hisNonce;
}

struct RecordedCertificate {
    // uint256 nonce;
    // address evmAddress;
    OmniverseTx[] txList;
    EvilTxData[] evilTxList;
}