// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "forge-std/Script.sol";
import "../src/Token.sol";

contract DevDeployScript is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        string memory contractURI = vm.envString("CONTRACT_URI");
        string memory tokenURI = vm.envString("TOKEN_URI");

        vm.startBroadcast(deployerPrivateKey);

        Token token = new Token(contractURI, tokenURI);

        console.log("Token ERC1155 deployed at:", address(token));

        vm.stopBroadcast();
    }
}
