import "../src/BlockSheep.sol";
import "../lib/forge-std/src/Script.sol";

contract AddAdmin is Script {
    BlockSheep internal blockSheep =
        BlockSheep(0x0D300B91087bA79BE970284B460B06D9222563D3);

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        blockSheep.setAdminRights(0xd8Fa137051acD7f3964524485be4b9A10CA22E94, true);

        vm.stopBroadcast();
    }
}