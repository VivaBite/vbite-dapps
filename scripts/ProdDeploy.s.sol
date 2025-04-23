// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Script.sol";
import "../contracts/VBITE.sol";
import "../contracts/VBITELifetimeNFT.sol";
import "../contracts/VBITEVestingVault.sol";
import "../contracts/VBITECrowdsale.sol";
import "../contracts/VBITEAccessTypes.sol";

contract ProdDeploy is Script {
    struct FeedConfig {
        address token;
        uint8 decimals;
        address feed;
    }

    function run() external {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        address owner = vm.envAddress("OWNER_ADDRESS");
        address treasury = vm.envAddress("TREASURY_ADDRESS");
        address dexMultisig = vm.envAddress("DEX_MULTISIG_ADDRESS");
        address projectMultisig = vm.envAddress("PROJECT_MULTISIG_ADDRESS");

        vm.startBroadcast(privateKey);

        VBITE vbite = new VBITE();
        VBITELifetimeNFT nft = new VBITELifetimeNFT(owner);
        VBITEVestingVault vesting = new VBITEVestingVault(address(vbite));

        address[] memory proposers = new address[](1);
        proposers[0] = owner;

        address[] memory executors = new address[](1);
        executors[0] = owner;

        uint256 initialRate = 1e6;
        VBITECrowdsale crowdsale = new VBITECrowdsale(
            owner,
            address(vbite),
            treasury,
            initialRate,
            address(nft),
            proposers,
            executors
        );

        VBITE(vbite).transfer(address(crowdsale), 300_000_000 * 1e18);
        VBITE(vbite).transfer(dexMultisig, 150_000_000 * 1e18);
        VBITE(vbite).transfer(address(vesting), 75_000_000 * 1e18);
        VBITE(vbite).transfer(projectMultisig, 200_000_000 * 1e18);

        VBITECrowdsale(crowdsale).setInitialVbiteAllocation(300_000_000 * 1e18);
        FeedConfig[] memory feeds = new FeedConfig[](9);

        feeds[0] = FeedConfig(address(0), 18, vm.envAddress("MATIC_FEED"));
        feeds[1] = FeedConfig(vm.envAddress("USDC_TOKEN"), 6, vm.envAddress("USDC_FEED"));
        feeds[2] = FeedConfig(vm.envAddress("USDT_TOKEN"), 6, vm.envAddress("USDT_FEED"));
        feeds[3] = FeedConfig(vm.envAddress("DAI_TOKEN"), 18, vm.envAddress("DAI_FEED"));
        feeds[4] = FeedConfig(vm.envAddress("LINK_TOKEN"), 18, vm.envAddress("LINK_FEED"));
        feeds[5] = FeedConfig(vm.envAddress("AAVE_TOKEN"), 18, vm.envAddress("AAVE_FEED"));
        feeds[6] = FeedConfig(vm.envAddress("CRV_TOKEN"), 18, vm.envAddress("CRV_FEED"));
        feeds[7] = FeedConfig(vm.envAddress("BAL_TOKEN"), 18, vm.envAddress("BAL_FEED"));
        feeds[8] = FeedConfig(vm.envAddress("SUSHI_TOKEN"), 18, vm.envAddress("SUSHI_FEED"));

        for (uint i = 0; i < feeds.length; i++) {
            VBITECrowdsale(crowdsale).addAcceptedToken(feeds[i].token, feeds[i].decimals, feeds[i].feed);
        }

        VBITEAccessTypes.Tier[] memory allowedTiers = new VBITEAccessTypes.Tier[](3);
        allowedTiers[0] = VBITEAccessTypes.Tier.SILVER;
        allowedTiers[1] = VBITEAccessTypes.Tier.GOLD;
        allowedTiers[2] = VBITEAccessTypes.Tier.PLATINUM;
        VBITELifetimeNFT(nft).addMinter(address(crowdsale), allowedTiers);

        vm.stopBroadcast();
    }
}
