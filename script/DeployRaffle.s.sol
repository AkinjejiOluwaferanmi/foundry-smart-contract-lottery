// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "./Interactions.s.sol";

contract DeployRaffle is Script {
    function run() external returns (Raffle, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig(); // This comes with our mocks!
        HelperConfig.NetworkConfig memory networkConfig = helperConfig.getConfig();
        uint256 entranceFee = networkConfig.entranceFee;
        uint256 interval = networkConfig.interval;
        address vrfCoordinator = networkConfig.vrfCoordinator;
        bytes32 gasLane = networkConfig.gasLane;
        uint256 subscriptionId = networkConfig.subscriptionId;
        uint32 callbackGasLimit = networkConfig.callbackGasLimit;
        address link = networkConfig.link;
        uint256 deployerKey = networkConfig.deployerKey;

        if (subscriptionId == 0) {
            CreateSubscription createSubscription = new CreateSubscription();
            subscriptionId = createSubscription.createSubscription(vrfCoordinator, deployerKey);

            FundSubscription fundSubscription = new FundSubscription();
            fundSubscription.fundSubscription(vrfCoordinator, subscriptionId, link, deployerKey);
        }

        vm.startBroadcast();
        Raffle raffle = new Raffle(entranceFee, interval, vrfCoordinator, gasLane, subscriptionId, callbackGasLimit);
        vm.stopBroadcast();

        AddConsumer addConsumer = new AddConsumer();
        addConsumer.addConsumer(address(raffle), vrfCoordinator, subscriptionId, deployerKey);

        return (raffle, helperConfig);
    }
}
