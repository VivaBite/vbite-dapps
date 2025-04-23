// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Script.sol";
import "../contracts/VBITE.sol";
import "../contracts/VBITELifetimeNFT.sol";
import "../contracts/VBITEVestingVault.sol";
import "../contracts/VBITECrowdsale.sol";
import "../contracts/VBITEAccessTypes.sol";

contract DeployProdFull is Script {
    function run() external {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        address owner = vm.envAddress("OWNER_ADDRESS");
        address treasury = vm.envAddress("TREASURY_ADDRESS");
        address dexMultisig = vm.envAddress("DEX_MULTISIG_ADDRESS");
        address projectMultisig = vm.envAddress("PROJECT_MULTISIG_ADDRESS");

        vm.startBroadcast(privateKey);

        VBITE vbite = new VBITE();
        VBITELifetimeNFT lifetimeNFT = new VBITELifetimeNFT(owner);
        VBITEVestingVault vestingVault = new VBITEVestingVault(address(vbite));

        uint256 initialRate = 1e6;
        VBITECrowdsale crowdsale = new VBITECrowdsale(
            owner,
            address(vbite),
            treasury,
            initialRate,
            address(lifetimeNFT)
        );

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
            '}'
        );

        string[] memory cmd = new string[](3);
        cmd[0] = "bash";
        cmd[1] = "-c";
        cmd[2] = string.concat("echo '", json, "' > deployed.prod.json");

        vm.ffi(cmd);
    }
}
