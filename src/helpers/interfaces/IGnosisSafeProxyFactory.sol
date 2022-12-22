// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IGnosisSafeProxyFactory {
    event ProxyCreation(address proxy, address singleton);

    function calculateCreateProxyWithNonceAddress(address _singleton, bytes memory initializer, uint256 saltNonce)
        external
        returns (address proxy);
    function createProxy(address singleton, bytes memory data) external returns (address proxy);
    function createProxyWithCallback(address _singleton, bytes memory initializer, uint256 saltNonce, address callback)
        external
        returns (address proxy);
    function createProxyWithNonce(address _singleton, bytes memory initializer, uint256 saltNonce)
        external
        returns (address proxy);
    function proxyCreationCode() external pure returns (bytes memory);
    function proxyRuntimeCode() external pure returns (bytes memory);
}
