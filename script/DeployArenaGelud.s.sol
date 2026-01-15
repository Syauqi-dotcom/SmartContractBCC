// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/ArenaGelud.sol";

contract DeployScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Duration: 1 day (86400 seconds)
        uint256 duration = 1 days;
        ArenaGelud arenaGelud = new ArenaGelud(duration);

        console.log("ArenaGelud deployed at:", address(arenaGelud));

        vm.stopBroadcast();
    }
}
