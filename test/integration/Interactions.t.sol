// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Test} from "forge-std/Test.sol";
import {Raffle} from "../../src/Raffle.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "../../script/Interactions.s.sol";
import {VRFCoordinatorV2PlusMock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2PlusMock.sol";

contract InteractionsTest is Test {
    Raffle public raffle;
    HelperConfig public helperConfig;

    address public PLAYER = makeAddr("player");
    uint256 public constant STARTING_PLAYER_BALANCE = 10 ether;

    uint256 entranceFee;
    uint256 interval;
    address vrfCoordinator;
    bytes32 gasLane;
    uint32 callbackGasLimit;
    uint256 subscriptionId;
    address link;
    uint256 deployerKey;
    uint256 subId;

    function setUp() public {
        DeployRaffle deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.run();

        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        entranceFee = config.entranceFee;
        interval = config.interval;
        vrfCoordinator = config.vrfCoordinator;
        gasLane = config.gasLane;
        callbackGasLimit = config.callbackGasLimit;
        subscriptionId = config.subscriptionId;
        link = config.link;
        deployerKey = config.deployerKey;
        vm.deal(PLAYER, STARTING_PLAYER_BALANCE);

        CreateSubscription createSubscription = new CreateSubscription();
        subId = createSubscription.createSubscriptionUsingConfig();

        FundSubscription fundSubscription = new FundSubscription();
        fundSubscription.fundSubscription(vrfCoordinator, subId, link, deployerKey);

        AddConsumer addConsumer = new AddConsumer();
        addConsumer.addConsumer(address(raffle), vrfCoordinator, subId, deployerKey);
    }

    function testRaffleDeployedCorrectly() public view {
        assert(address(raffle) != address(0));
        assertGt(raffle.getEntranceFee(), 0);
    }

    function testConsumerIsAdded() public view {
        bool isConsumer = VRFCoordinatorV2PlusMock(vrfCoordinator).consumerIsAdded(subId, address(raffle));
        assertTrue(isConsumer, "Raffle contract is not a consumer of the VRF Coordinator");
    }
}
