import "../src/BlockSheep.sol";
import "../lib/forge-std/src/Script.sol";

contract AddAdmin is Script {
    BlockSheep internal blockSheep =
        BlockSheep(0x26D345faC6F304D7Ecb9dA21DE0C783f05A37cAe);

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        blockSheep.setAdminRights(0xd8Fa137051acD7f3964524485be4b9A10CA22E94, true);

        vm.stopBroadcast();
    }
}