pragma solidity 0.8.28;

contract Test {
    event Event(bytes32 id);

    function emitEvent() external {
        emit Event(keccak256(abi.encodePacked(block.timestamp)));
    }
}
