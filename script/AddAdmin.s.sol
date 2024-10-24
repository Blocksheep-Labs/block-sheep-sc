import "../src/BlockSheep.sol";
import "../lib/forge-std/src/Script.sol";

contract AddAdmin is Script {
    BlockSheep internal blockSheep =
        BlockSheep(0x181b8bf1E2B454f0F2B17826cd5898c529BAc696);

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        blockSheep.setAdminRights(0xA5Fb97059479d610F6be759A6078B53Ed25f470e, true);

        vm.stopBroadcast();
    }
}