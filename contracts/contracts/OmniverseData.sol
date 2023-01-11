// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

uint8 constant DEPOSIT = 0;
uint8 constant TRANSFER = 1;
uint8 constant WITHDRAW = 2;
uint8 constant MINT = 3;

struct OmniverseTokenProtocol {
    uint256 nonce;
    uint8 chainId;
    bytes from;
    string to;
    bytes data;
    bytes signature;
}