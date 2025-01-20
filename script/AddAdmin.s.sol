import "../src/BlockSheep.sol";
import "../lib/forge-std/src/Script.sol";

contract AddAdmin is Script {
    BlockSheep internal blockSheep =
        BlockSheep(0x181b8bf1E2B454f0F2B17826cd5898c529BAc696);

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        blockSheep.setAdminRights(0x0e7f5b922AE381a532F80BFd145CEb2C382F9970, true);

        vm.stopBroadcast();
    }
}