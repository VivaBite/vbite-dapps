// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Script.sol";
import "../contracts/VBITEAirdrop.sol";
import "../contracts/VBITE.sol";

contract AirdropDeploy is Script {
    function run() external {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        address owner = vm.envAddress("OWNER_ADDRESS");
        address vbiteToken = vm.envAddress("VBITE_TOKEN_ADDRESS");
        uint256 airdropAllocation = vm.envUint("AIRDROP_ALLOCATION");
        
        // Опционально: кастомное время деплоя (0 для текущего времени)
        uint256 deploymentTime = vm.envOr("DEPLOYMENT_TIME", uint256(0));

        vm.startBroadcast(privateKey);

        // Получаем адрес деплоящего аккаунта
        address deployer = vm.addr(privateKey);
        
        console.log("=== Pre-Deployment Checks ===");
        console.log("Deployer address:", deployer);
        console.log("VBITE token address:", vbiteToken);
        console.log("Required allocation:", airdropAllocation);

        // Создаем экземпляр VBITE контракта
        VBITE vbite = VBITE(vbiteToken);
        
        // Проверяем, что деплоер является овнером токена
        require(
            vbite.owner() == deployer, 
            "Deployer must be the owner of VBITE token"
        );

        console.log("Token owner:", vbite.owner());
        console.log("Access rights verified");

        // Деплой контракта аирдропа
        console.log("\n=== Deploying Airdrop Contract ===");
        VBITEAirdrop airdrop = new VBITEAirdrop(
            vbiteToken,
            owner,
            deploymentTime
        );

        console.log("Airdrop contract deployed at:", address(airdrop));

        // Минтим токены напрямую в контракт аирдропа
        console.log("\n=== Minting Tokens to Airdrop Contract ===");
        console.log("Minting", airdropAllocation, "VBITE tokens to:", address(airdrop));
        
        vbite.mintTokens(address(airdrop), airdropAllocation);

        // Проверяем баланс контракта после минтинга
        uint256 contractBalance = vbite.balanceOf(address(airdrop));
        
        console.log("=== Deployment Summary ===");
        console.log("Contract address:", address(airdrop));
        console.log("VBITE token:", vbiteToken);
        console.log("Owner:", owner);
        console.log("Deployer:", deployer);
        console.log("Allocation minted:", airdropAllocation);
        console.log("Contract balance:", contractBalance);
        console.log("Current round:", airdrop.getCurrentRound());
        console.log("Deployment time:", airdrop.deploymentTime());
        console.log("Max allowed round:", airdrop.maxAllowedRound());

        // Проверяем, что минтинг прошел успешно
        require(
            contractBalance >= airdropAllocation, 
            "Minting failed: insufficient contract balance"
        );

        console.log("Airdrop deployment completed successfully!");

        vm.stopBroadcast();
    }
}