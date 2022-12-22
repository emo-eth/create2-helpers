// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {BaseCreate2Script, console2} from "./BaseCreate2Script.s.sol";
import {
    SAFE_PROXY_FACTORY_1_3_0_CREATION_CODE,
    SAFE_PROXY_FACTORY_1_3_0_ADDRESS,
    SAFE_1_3_0_ADDRESS,
    SAFE_1_3_0_CREATION_CODE,
    SAFE_COMPATIBILITY_FALLBACK_HANDLER_1_3_0_ADDRESS,
    SAFE_COMPATIBILITY_FALLBACK_HANDLER_1_3_0_CREATION_CODE
} from "src/lib/Constants.sol";
import {IGnosisSafeProxyFactory} from "src/helpers/interfaces/IGnosisSafeProxyFactory.sol";
import {IGnosisSafe} from "src/helpers/interfaces/IGnosisSafe.sol";

contract DeploySafe is BaseCreate2Script {
    struct SafeSetupParams {
        address[] owners;
        uint256 threshold;
        address to;
        bytes data;
        address paymentToken;
        uint256 payment;
        address paymentReceiver;
    }

    struct SafeCreationParams {
        SafeSetupParams setup;
        uint256 saltNonce;
    }

    function run() public {
        runOnNetworks(deploy, vm.envString("NETWORKS", ","));
    }

    function deploy() internal {
        deploySafe(
            SafeCreationParams({
                setup: SafeSetupParams({
                    owners: vm.envAddress("SAFE_OWNERS", ","),
                    threshold: vm.envUint("SAFE_THRESHOLD"),
                    to: vm.envAddress("SAFE_TO"),
                    data: vm.envBytes("SAFE_DATA"),
                    paymentToken: vm.envAddress("SAFE_PAYMENT_TOKEN"),
                    payment: vm.envUint("SAFE_PAYMENT"),
                    paymentReceiver: vm.envAddress("SAFE_PAYMENT_RECEIVER")
                }),
                saltNonce: vm.envUint("SAFE_SALT_NONCE")
            })
        );
    }

    function deploySafe(SafeCreationParams memory params) internal {
        address safeSingletonAddress = _create2SafeSingletonIfNotDeployed();
        address safeCompatibilityFallbackAddress = _create2SafeCompatibilityFallbackAddressIfNotDeployed();
        address safeProxyFactoryAddress = _create2SafeProxyFactoryIfNotDeployed();
        IGnosisSafeProxyFactory safeProxyFactory = IGnosisSafeProxyFactory(safeProxyFactoryAddress);

        bytes memory initializer = abi.encodeWithSelector(
            IGnosisSafe.setup.selector,
            params.setup.owners,
            params.setup.threshold,
            params.setup.to,
            params.setup.data,
            safeCompatibilityFallbackAddress,
            params.setup.paymentToken,
            params.setup.payment,
            params.setup.paymentReceiver
        );
        address proxy = safeProxyFactory.createProxyWithNonce(safeSingletonAddress, initializer, params.saltNonce);
        console2.log("Safe deployed at: ", proxy);
    }

    function _create2SafeSingletonIfNotDeployed() internal returns (address) {
        address safeSingleton = _create2IfNotDeployed(deployer, 0, bytes32(0), SAFE_1_3_0_CREATION_CODE);
        require(safeSingleton == SAFE_1_3_0_ADDRESS, "Safe Singleton was not deployed");
        return safeSingleton;
    }

    function _create2SafeProxyFactoryIfNotDeployed() internal returns (address) {
        address safeProxyFactory =
            _create2IfNotDeployed(deployer, 0, bytes32(0), SAFE_PROXY_FACTORY_1_3_0_CREATION_CODE);
        require(safeProxyFactory == SAFE_PROXY_FACTORY_1_3_0_ADDRESS, "Safe Proxy Factory was not deployed");
        return safeProxyFactory;
    }

    function _create2SafeCompatibilityFallbackAddressIfNotDeployed() internal returns (address) {
        address safeCompatibilityFallbackAddress =
            _create2IfNotDeployed(deployer, 0, bytes32(0), SAFE_COMPATIBILITY_FALLBACK_HANDLER_1_3_0_CREATION_CODE);
        require(
            safeCompatibilityFallbackAddress == SAFE_COMPATIBILITY_FALLBACK_HANDLER_1_3_0_ADDRESS,
            "Safe Compatibility Fallback Address was not deployed"
        );
        return safeCompatibilityFallbackAddress;
    }
}
