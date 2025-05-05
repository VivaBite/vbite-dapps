// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Script.sol";
import "../contracts/VBITE.sol";
import "../contracts/VBITELifetimeNFT.sol";
import "../contracts/VBITEVestingVault.sol";
import "../contracts/VBITECrowdsale.sol";
import "../contracts/VBITEAccessTypes.sol";
import "../mocks/MockV3Aggregator.sol";
import "../mocks/MockERC20.sol";

contract DeployLocal is Script {
    function run() external {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        address owner = vm.envAddress("OWNER_ADDRESS");
        address treasury = vm.envAddress("TREASURY_ADDRESS");
        address dexMultisig = vm.envAddress("DEX_MULTISIG_ADDRESS");
        address projectMultisig = vm.envAddress("PROJECT_MULTISIG_ADDRESS");

        // Получаем тестовые адреса из окружения, если они есть
        address user1;
        address user2;
        bool hasTestUsers = false;

        try vm.envAddress("USER1_ADDRESS") returns (address _user1) {
            user1 = _user1;
            try vm.envAddress("USER2_ADDRESS") returns (address _user2) {
                user2 = _user2;
                hasTestUsers = true;
                console.log("Test users found: USER1=%s, USER2=%s", user1, user2);
            } catch {
                console.log("USER2_ADDRESS not found in environment");
            }
        } catch {
            console.log("USER1_ADDRESS not found in environment");
        }


        // Proposers и executors для timelock (можно добавить из env файла)
        address[] memory proposers = new address[](1);
        proposers[0] = owner;

        address[] memory executors = new address[](1);
        executors[0] = owner;

        vm.startBroadcast(privateKey);

        // 1. Деплой VBITE токена
        VBITE vbite = new VBITE();
        console.log("VBITE deployed at:", address(vbite));

        // 2. Деплой NFT контракта
        VBITELifetimeNFT lifetimeNFT = new VBITELifetimeNFT(owner);
        console.log("VBITELifetimeNFT deployed at:", address(lifetimeNFT));

        // 3. Деплой контракта вестинга
        VBITEVestingVault vestingVault = new VBITEVestingVault(address(vbite));
        console.log("VBITEVestingVault deployed at:", address(vestingVault));

        // 4. Деплой контракта краудсейла
        // Rate: 100 VBITE за 1 USD (1 VBITE = $0.01)
        uint256 initialRate = 1e6;
        VBITECrowdsale crowdsale = new VBITECrowdsale(
            owner,
            address(vbite),
            treasury,
            initialRate,
            address(lifetimeNFT),
            proposers,
            executors
        );
        console.log("VBITECrowdsale deployed at:", address(crowdsale));

        // 5. Настройка прав для минтинга NFT
        VBITEAccessTypes.Tier[] memory allowedTiers = new VBITEAccessTypes.Tier[](3);
        allowedTiers[0] = VBITEAccessTypes.Tier.SILVER;
        allowedTiers[1] = VBITEAccessTypes.Tier.GOLD;
        allowedTiers[2] = VBITEAccessTypes.Tier.PLATINUM;

        lifetimeNFT.addMinter(address(crowdsale), allowedTiers);
        console.log("Crowdsale added as NFT minter");

        // 6. Распределение токенов

        // Для краудсейла: 300,000,000 VBITE
        uint256 crowdsaleAmount = 300_000_000 * 1e18;
        vbite.transfer(address(crowdsale), crowdsaleAmount);
        crowdsale.setInitialVbiteAllocation(crowdsaleAmount);
        console.log("Transferred to crowdsale:", crowdsaleAmount / 1e18);

        // Для DEX ликвидности: 150,000,000 VBITE
        uint256 dexLiquidityAmount = 150_000_000 * 1e18;
        vbite.transfer(dexMultisig, dexLiquidityAmount);
        console.log("Transferred to DEX multisig:", dexLiquidityAmount / 1e18);

        // Для вестинга команды: 75,000,000 VBITE
        uint256 teamAmount = 75_000_000 * 1e18;
        vbite.transfer(address(vestingVault), teamAmount);
        console.log("Transferred to vesting vault:", teamAmount / 1e18);

        // Для остальных целей: 200,000,000 VBITE
        uint256 multisigAmount = 200_000_000 * 1e18;
        vbite.transfer(projectMultisig, multisigAmount);
        console.log("Transferred to project multisig:", multisigAmount / 1e18);

        // Проверка общего количества переведенных токенов
        uint256 totalDistributed = crowdsaleAmount + dexLiquidityAmount + teamAmount + multisigAmount;
        console.log("Total tokens distributed:", totalDistributed / 1e18);

        // деплой моков чайинлинка м самих токенов
        // MATIC USDC USDT DAI LINK AAVE CRV BAL SUSHI
        // function addAcceptedToken(address token, uint8 decimals, address priceFeed)
        MockV3Aggregator maticFeed = new MockV3Aggregator(8, 70_000_000); // 0.70 MATIC
        console.log("MATIC feed deployed at:", address(maticFeed));
        crowdsale.addAcceptedToken(address(0), 18, address(maticFeed));

        MockERC20 usdc = new MockERC20("Mock USDC", "USDC", 6, 10**12);
        console.log("USDC token deployed at:", address(usdc));
        MockV3Aggregator usdcFeed = new MockV3Aggregator(8, 100_000_000); // 1.00 USDC
        console.log("USDC feed deployed at:", address(usdcFeed));
        crowdsale.addAcceptedToken(address(usdc), 6, address(usdcFeed));
        if (hasTestUsers) {
            uint256 supply = 5 * 10**10;
            usdc.transfer(user1, supply);
            usdc.transfer(user2, supply);
            console.log("Transferred USDC to test users: %s tokens each", supply / 1e6);
        }

        MockERC20 usdt = new MockERC20("Mock USDT", "USDT", 6, 10**12);
        console.log("USDT token deployed at:", address(usdt));
        MockV3Aggregator usdtFeed = new MockV3Aggregator(8, 100_000_000); // 1.00 USDT
        console.log("USDT feed deployed at:", address(usdtFeed));
        crowdsale.addAcceptedToken(address(usdt), 6, address(usdtFeed));
        if (hasTestUsers) {
            uint256 supply = 5 * 10**10;
            usdt.transfer(user1, supply);
            usdt.transfer(user2, supply);
            console.log("Transferred USDT to test users: %s tokens each", supply / 1e6);
        }

        MockERC20 dai = new MockERC20("Mock DAI", "DAI", 18, 10**24);
        console.log("DAI token deployed at:", address(dai));
        MockV3Aggregator daiFeed = new MockV3Aggregator(8, 100_000_000);  // 1.00 DAI
        console.log("DAI feed deployed at:", address(daiFeed));
        crowdsale.addAcceptedToken(address(dai), 18, address(daiFeed));
        if (hasTestUsers) {
            uint256 supply = 5 * 10**22;
            dai.transfer(user1, supply);
            dai.transfer(user2, supply);
            console.log("Transferred DAI to test users: %s tokens each", supply / 1e18);
        }

        MockERC20 link = new MockERC20("Mock LINK", "LINK", 18, 10**24);
        console.log("LINK token deployed at:", address(dai));
        MockV3Aggregator linkFeed = new MockV3Aggregator(8, 1_450_000_000); // 14.50 LINK
        console.log("LINK feed deployed at:", address(linkFeed));
        crowdsale.addAcceptedToken(address(link), 18, address(linkFeed));
        if (hasTestUsers) {
            uint256 supply = 5 * 10**22;
            link.transfer(user1, supply);
            link.transfer(user2, supply);
            console.log("Transferred LINK to test users: %s tokens each", supply / 1e18);
        }

        MockERC20 aave = new MockERC20("Mock AAVE", "AAVE", 18, 10**24);
        console.log("AAVE token deployed at:", address(aave));
        MockV3Aggregator aaveFeed = new MockV3Aggregator(8, 9_800_000_000); // 98.00 AAVE
        console.log("AAVE feed deployed at:", address(aaveFeed));
        crowdsale.addAcceptedToken(address(aave), 18, address(aaveFeed));
        if (hasTestUsers) {
            uint256 supply = 5 * 10**22;
            aave.transfer(user1, supply);
            aave.transfer(user2, supply);
            console.log("Transferred AAVE to test users: %s tokens each", supply / 1e18);
        }

        MockERC20 crv = new MockERC20("Mock CRV", "CRV", 18, 10**24);
        console.log("CRV token deployed at:", address(crv));
        MockV3Aggregator crvFeed = new MockV3Aggregator(8, 36_000_000); // 0.36 CRV
        console.log("CRV feed deployed at:", address(crvFeed));
        crowdsale.addAcceptedToken(address(crv), 18, address(crvFeed));
        if (hasTestUsers) {
            uint256 supply = 5 * 10**22;
            crv.transfer(user1, supply);
            crv.transfer(user2, supply);
            console.log("Transferred CRV to test users: %s tokens each", supply / 1e18);
        }

        MockERC20 bal = new MockERC20("Mock BAL", "BAL", 18, 10**24);
        console.log("BAL token deployed at:", address(crv));
        MockV3Aggregator balFeed = new MockV3Aggregator(8, 420_000_000); // 4.20 BAL
        console.log("BAL feed deployed at:", address(balFeed));
        crowdsale.addAcceptedToken(address(bal), 18, address(balFeed));
        if (hasTestUsers) {
            uint256 supply = 5 * 10**22;
            bal.transfer(user1, supply);
            bal.transfer(user2, supply);
            console.log("Transferred BAL to test users: %s tokens each", supply / 1e18);
        }

        MockERC20 sushi = new MockERC20("Mock SUSHI", "SUSHI", 18, 10**24);
        console.log("SUSHI token deployed at:", address(sushi));
        MockV3Aggregator sushiFeed = new MockV3Aggregator(8, 120_000_000); // 1.20 SUSHI
        console.log("SUSHI feed deployed at:", address(sushiFeed));
        crowdsale.addAcceptedToken(address(sushi), 18, address(sushiFeed));
        if (hasTestUsers) {
            uint256 supply = 5 * 10**22;
            sushi.transfer(user1, supply);
            sushi.transfer(user2, supply);
            console.log("Transferred SUSHI to test users: %s tokens each", supply / 1e18);
        }


        vm.stopBroadcast();

        string memory json = string.concat(
            '{',
            '"chainId":', vm.toString(block.chainid), ",",
            '"dapps":{',
            '"ownerAddress":"', vm.toString(vm.addr(privateKey)), '",',
            '"treasuryAddress":"', vm.toString(address(treasury)), '",',
            '"dexAddress":"', vm.toString(address(dexMultisig)), '",',
            '"projectAddress":"', vm.toString(address(projectMultisig)), '",',
            '"vbiteAddress":"', vm.toString(address(vbite)), '",',
            '"crowdsaleAddress":"', vm.toString(address(crowdsale)), '",',
            '"nftAdderss":"', vm.toString(address(lifetimeNFT)), '",',
            '"vestingAddress":"', vm.toString(address(vestingVault)), '",',
            '},',
            '"tokens":{',
            '"matic":"', vm.toString(address(matic)), '",',
            '"usdc":"', vm.toString(address(usdc)), '",',
            '"usdt":"', vm.toString(address(usdt)), '",',
            '"dai":"', vm.toString(address(dai)), '",',
            '"link":"', vm.toString(address(link)), '",',
            '"aave":"', vm.toString(address(aave)), '",',
            '"crv":"', vm.toString(address(crv)), '",',
            '"bal":"', vm.toString(address(bal)), '",',
            '"sushi":"', vm.toString(address(sushi)), '"',
            '},',
            '"feeds":{',
            '"matic":"', vm.toString(address(maticFeed)), '",',
            '"usdc":"', vm.toString(address(usdcFeed)), '",',
            '"usdt":"', vm.toString(address(usdtFeed)), '",',
            '"dai":"', vm.toString(address(daiFeed)), '",',
            '"link":"', vm.toString(address(linkFeed)), '",',
            '"aave":"', vm.toString(address(aaveFeed)), '",',
            '"crv":"', vm.toString(address(crvFeed)), '",',
            '"bal":"', vm.toString(address(balFeed)), '",',
            '"sushi":"', vm.toString(address(sushiFeed)), '"',
            '}',
            '}'
        );
        string[] memory cmd = new string[](3);
        cmd[0] = "bash";
        cmd[1] = "-c";
        cmd[2] = string.concat("echo '", json, "' > deployed.local.json");

        vm.ffi(cmd);
    }
}
