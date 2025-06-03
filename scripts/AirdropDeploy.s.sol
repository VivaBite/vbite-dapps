// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Script.sol";
import "../contracts/VBITEAirdrop.sol";

contract AirdropDeploy is Script {
    function run() external {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        address owner = vm.envAddress("OWNER_ADDRESS");
        address vbiteToken = vm.envAddress("VBITE_TOKEN_ADDRESS");
        uint256 airdropAllocation = vm.envUint("AIRDROP_ALLOCATION");
        
        // Опционально: кастомное время деплоя (0 для текущего времени)
        uint256 deploymentTime = vm.envOr("DEPLOYMENT_TIME", uint256(0));

        vm.startBroadcast(privateKey);

        // Деплой контракта аирдропа
        VBITEAirdrop airdrop = new VBITEAirdrop(
            vbiteToken,
            owner,
            deploymentTime
        );

        // Прямой перевод токенов в контракт аирдропа
        IERC20(vbiteToken).transfer(address(airdrop), airdropAllocation);

        // Вывод информации о деплое
        console.log("=== VBITE Airdrop Deployment ===");
        console.log("Contract address:", address(airdrop));
        console.log("VBITE token:", vbiteToken);
        console.log("Owner:", owner);
        console.log("Allocation:", airdropAllocation);
        console.log("Contract balance:", IERC20(vbiteToken).balanceOf(address(airdrop)));
        console.log("Current round:", airdrop.getCurrentRound());

        vm.stopBroadcast();
    }
}