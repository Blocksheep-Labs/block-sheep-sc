import "../src/BlockSheep.sol";
import "../lib/forge-std/src/Script.sol";

contract AddAdmin is Script {
    BlockSheep internal blockSheep =
        BlockSheep(0xAe064eeD6b8Ec3c85cE95A65BEe555567505d580);

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        blockSheep.setAdminRights(0x384F0db13B415ED245d65a729f039CF5734BfE14, true);

        vm.stopBroadcast();
    }
}