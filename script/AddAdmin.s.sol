import "../src/BlockSheep.sol";

contract AddAdmin is Script {
    BlockSheep internal blockSheep =
        BlockSheep(0xAe064eeD6b8Ec3c85cE95A65BEe555567505d580);

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        BlockSheep.setAdminRights()

        vm.stopBroadcast();
    }
}