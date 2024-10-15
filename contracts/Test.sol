pragma solidity 0.8.20;

contract Test {
    event Event(bytes32 id);

    function emitEvent() external {
        emit Event(keccak256(abi.encodePacked(block.timestamp)));
    }
}
