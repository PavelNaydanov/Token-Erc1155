// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "forge-std/Script.sol";
import "../src/Token.sol";

contract DevDeployScript is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        string memory baseUri = vm.envString("BASE_URI");

        vm.startBroadcast(deployerPrivateKey);

        Token token = new Token(baseUri);

        console.log("Token ERC1155 deployed at:", address(token));

        vm.stopBroadcast();
    }
}
