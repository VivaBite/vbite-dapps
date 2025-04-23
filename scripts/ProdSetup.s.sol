// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Script.sol";
import "../contracts/VBITE.sol";
import "../contracts/VBITELifetimeNFT.sol";
import "../contracts/VBITEVestingVault.sol";
import "../contracts/VBITECrowdsale.sol";
import "../contracts/VBITEAccessTypes.sol";

contract ProdSetup is Script {
    function run() external {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");

        address crowdsale = vm.envAddress("CROWDSALE_ADDRESS");
        address vbite = vm.envAddress("VBITE_ADDRESS");
        address nft = vm.envAddress("NFT_ADDRESS");
        address vesting = vm.envAddress("VESTING_ADDRESS");
        address dex = vm.envAddress("DEX_MULTISIG_ADDRESS");
        address project = vm.envAddress("PROJECT_MULTISIG_ADDRESS");

        address maticFeed = vm.envAddress("MATIC_FEED");
        address usdcFeed = vm.envAddress("USDC_FEED");
        address usdtFeed = vm.envAddress("USDT_FEED");
        address daiFeed = vm.envAddress("DAI_FEED");
        address linkFeed = vm.envAddress("LINK_FEED");
        address aaveFeed = vm.envAddress("AAVE_FEED");
        address crvFeed = vm.envAddress("CRV_FEED");
        address balFeed = vm.envAddress("BAL_FEED");
        address sushiFeed = vm.envAddress("SUSHI_FEED");

        address usdcToken = vm.envAddress("USDC_TOKEN");
        address usdtToken = vm.envAddress("USDT_TOKEN");
        address daiToken = vm.envAddress("DAI_TOKEN");
        address linkToken = vm.envAddress("LINK_TOKEN");
        address aaveToken = vm.envAddress("AAVE_TOKEN");
        address crvToken = vm.envAddress("CRV_TOKEN");
        address balToken = vm.envAddress("BAL_TOKEN");
        address sushiToken = vm.envAddress("SUSHI_TOKEN");

        vm.startBroadcast(privateKey);

        // Transfer tokens
        VBITE(vbite).transfer(crowdsale, 300_000_000 * 1e18);
        VBITE(vbite).transfer(dex, 150_000_000 * 1e18);
        VBITE(vbite).transfer(vesting, 75_000_000 * 1e18);
        VBITE(vbite).transfer(project, 200_000_000 * 1e18);

        // Allocation setup
        VBITECrowdsale(crowdsale).setInitialVbiteAllocation(300_000_000 * 1e18);

        // adding accepted tokens
        VBITECrowdsale(crowdsale).addAcceptedToken(address(0), 18, maticFeed);
        VBITECrowdsale(crowdsale).addAcceptedToken(usdcToken, 6, usdcFeed);
        VBITECrowdsale(crowdsale).addAcceptedToken(usdtToken, 6, usdtFeed);
        VBITECrowdsale(crowdsale).addAcceptedToken(daiToken, 18, daiFeed);
        VBITECrowdsale(crowdsale).addAcceptedToken(linkToken, 18, linkFeed);
        VBITECrowdsale(crowdsale).addAcceptedToken(aaveToken, 18, aaveFeed);
        VBITECrowdsale(crowdsale).addAcceptedToken(crvToken, 18, crvFeed);
        VBITECrowdsale(crowdsale).addAcceptedToken(balToken, 18, balFeed);
        VBITECrowdsale(crowdsale).addAcceptedToken(sushiToken, 18, sushiFeed);

        // Minting tiers
        VBITEAccessTypes.Tier[] memory allowedTiers = new VBITEAccessTypes.Tier[](3);
        allowedTiers[0] = VBITEAccessTypes.Tier.SILVER;
        allowedTiers[1] = VBITEAccessTypes.Tier.GOLD;
        allowedTiers[2] = VBITEAccessTypes.Tier.PLATINUM;
        VBITELifetimeNFT(nft).addMinter(crowdsale, allowedTiers);

        vm.stopBroadcast();
    }
}
