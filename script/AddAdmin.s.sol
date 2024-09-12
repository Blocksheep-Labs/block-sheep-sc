import "../src/BlockSheep.sol";
import "../lib/forge-std/src/Script.sol";

contract AddAdmin is Script {
    BlockSheep internal blockSheep =
        BlockSheep(0xC8277F250ea788434316c633168454f3d2376904);

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        blockSheep.setAdminRights(0x430EfD6d64E0AA04575D4e1bc60931Fc42C3a73A, true);

        vm.stopBroadcast();
    }
}