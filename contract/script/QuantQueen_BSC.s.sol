// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "forge-std/Script.sol";
import {QuantQueen} from "../src/QuantQueen.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
/// @dev Minimal interface types used in constructor only.
interface IERC20Like {}
interface ITicketBuyerLike {}

contract QuantQueenScript is Script {
    function run() external {
        address token = address(0x55d398326f99059fF775485246999027B3197955); //BSC-USDT
        address treasury = address(0xD038213A84a86348d000929C115528AE9DdC1158);
        address admin = address(0x35a1C761D7c2B8bb3D6EC65b9198025C02620000);
        address bot = address(0xB8D3597156888Cde196c066bE6Ab6b24796A2fE1);
        uint256 currentCutoff = 1766332800; //部署的当月22日
        uint256 payout = 1767196800; //部署的次月1日
        uint256 nextPayout = 1769875200; //部署的次次月1日

        uint256 deployerPk = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPk);

        QuantQueen quantQueen = new QuantQueen(
            token,
            treasury,
            admin,
            bot,
            currentCutoff,
            payout,
            nextPayout
        );

        vm.stopBroadcast();

        console2.log("BSC QuantQueen deployed at:", address(quantQueen));
        console2.log("token:", token);
        console2.log("treasury:", treasury);
        console2.log("admin:", admin);
        console2.log("bot:", bot);
    }
}
