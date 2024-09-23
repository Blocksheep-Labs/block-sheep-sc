import "../src/BlockSheep.sol";
import "../lib/forge-std/src/Script.sol";

contract AddAdmin is Script {
    BlockSheep internal blockSheep =
        BlockSheep(0x4B3b9F5afC9CC1083ce44a1c97E3a75490F6cFF0);

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        blockSheep.setAdminRights(0x430EfD6d64E0AA04575D4e1bc60931Fc42C3a73A, true);

        vm.stopBroadcast();
    }
}