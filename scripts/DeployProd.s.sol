// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Script.sol";
import "../contracts/VBITE.sol";
import "../contracts/VBITELifetimeNFT.sol";
import "../contracts/VBITEVestingVault.sol";
import "../contracts/VBITECrowdsale.sol";
import "../contracts/VBITEAccessTypes.sol";

contract DeployProd is Script {
    function run() external {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        address owner = vm.envAddress("OWNER_ADDRESS");
        address treasury = vm.envAddress("TREASURY_ADDRESS");
        address dexMultisig = vm.envAddress("DEX_MULTISIG_ADDRESS");
        address projectMultisig = vm.envAddress("PROJECT_MULTISIG_ADDRESS");

        // Chainlink feeds
        address maticFeed = vm.envAddress("MATIC_FEED");
        address usdcFeed = vm.envAddress("USDC_FEED");
        address usdtFeed = vm.envAddress("USDT_FEED");
        address daiFeed = vm.envAddress("DAI_FEED");
        address linkFeed = vm.envAddress("LINK_FEED");
        address aaveFeed = vm.envAddress("AAVE_FEED");
        address crvFeed = vm.envAddress("CRV_FEED");
        address balFeed = vm.envAddress("BAL_FEED");
        address sushiFeed = vm.envAddress("SUSHI_FEED");

        // ERC20 tokens
        address maticToken = vm.envAddress("MATIC_TOKEN");
        address usdcToken = vm.envAddress("USDC_TOKEN");
        address usdtToken = vm.envAddress("USDT_TOKEN");
        address daiToken = vm.envAddress("DAI_TOKEN");
        address linkToken = vm.envAddress("LINK_TOKEN");
        address aaveToken = vm.envAddress("AAVE_TOKEN");
        address crvToken = vm.envAddress("CRV_TOKEN");
        address balToken = vm.envAddress("BAL_TOKEN");
        address sushiToken = vm.envAddress("SUSHI_TOKEN");


        address[] memory proposers;
        address[] memory executors;
        executors[0] = owner;


        vm.startBroadcast(privateKey);

        VBITE vbite = new VBITE();
        VBITELifetimeNFT lifetimeNFT = new VBITELifetimeNFT(owner);
        VBITEVestingVault vestingVault = new VBITEVestingVault(address(vbite));

        uint256 initialRate = 0.01 * 1e8;
        VBITECrowdsale crowdsale = new VBITECrowdsale(
            owner,
            address(vbite),
            treasury,
            initialRate,
            address(lifetimeNFT),
            proposers,
            executors
        );

        VBITEAccessTypes.Tier[] memory allowedTiers = new VBITEAccessTypes.Tier[](3);
        allowedTiers[0] = VBITEAccessTypes.Tier.SILVER;
        allowedTiers[1] = VBITEAccessTypes.Tier.GOLD;
        allowedTiers[2] = VBITEAccessTypes.Tier.PLATINUM;

        lifetimeNFT.addMinter(address(crowdsale), allowedTiers);

        vbite.transfer(address(crowdsale), 300_000_000 * 1e18);
        crowdsale.setInitialVbiteAllocation(300_000_000 * 1e18);
        vbite.transfer(dexMultisig, 150_000_000 * 1e18);
        vbite.transfer(address(vestingVault), 75_000_000 * 1e18);
        vbite.transfer(projectMultisig, 200_000_000 * 1e18);

        crowdsale.addAcceptedToken(address(0), 18, maticFeed); // MATIC
        crowdsale.addAcceptedToken(usdcToken, 6, usdcFeed);
        crowdsale.addAcceptedToken(usdtToken, 6, usdtFeed);
        crowdsale.addAcceptedToken(daiToken, 18, daiFeed);
        crowdsale.addAcceptedToken(linkToken, 18, linkFeed);
        crowdsale.addAcceptedToken(aaveToken, 18, aaveFeed);
        crowdsale.addAcceptedToken(crvToken, 18, crvFeed);
        crowdsale.addAcceptedToken(balToken, 18, balFeed);
        crowdsale.addAcceptedToken(sushiToken, 18, sushiFeed);

        vm.stopBroadcast();

        string memory json = string.concat(
            '{',
            '"chainId":', vm.toString(block.chainid), ',',
            '"dapps":{',
            '"ownerAddress":"', vm.toString(vm.addr(privateKey)), '",',
            '"treasuryAddress":"', vm.toString(treasury), '",',
            '"dexAddress":"', vm.toString(dexMultisig), '",',
            '"projectAddress":"', vm.toString(projectMultisig), '",',
            '"vbiteAddress":"', vm.toString(address(vbite)), '",',
            '"crowdsaleAddress":"', vm.toString(address(crowdsale)), '",',
            '"nftAddress":"', vm.toString(address(lifetimeNFT)), '",',
            '"vestingAddress":"', vm.toString(address(vestingVault)), '"',
            '},',
            '"tokens":{',
            '"matic":"', vm.toString(maticToken), '",',
            '"usdc":"', vm.toString(usdcToken), '",',
            '"usdt":"', vm.toString(usdtToken), '",',
            '"dai":"', vm.toString(daiToken), '",',
            '"link":"', vm.toString(linkToken), '",',
            '"aave":"', vm.toString(aaveToken), '",',
            '"crv":"', vm.toString(crvToken), '",',
            '"bal":"', vm.toString(balToken), '",',
            '"sushi":"', vm.toString(sushiToken), '"',
            '},',
            '"feeds":{',
            '"matic":"', vm.toString(maticFeed), '",',
            '"usdc":"', vm.toString(usdcFeed), '",',
            '"usdt":"', vm.toString(usdtFeed), '",',
            '"dai":"', vm.toString(daiFeed), '",',
            '"link":"', vm.toString(linkFeed), '",',
            '"aave":"', vm.toString(aaveFeed), '",',
            '"crv":"', vm.toString(crvFeed), '",',
            '"bal":"', vm.toString(balFeed), '",',
            '"sushi":"', vm.toString(sushiFeed), '"',
            '}',
            '}'
        );

        string[] memory cmd = new string[](3);
        cmd[0] = "bash";
        cmd[1] = "-c";
        cmd[2] = string.concat("echo '", json, "' > deployed.prod.json");

        vm.ffi(cmd);
    }
}
