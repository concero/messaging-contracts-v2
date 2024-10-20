pragma solidity 0.8.28;

contract ConceroRouterStorage {
    mapping(address => bool) internal s_isAllowedOperator;
    mapping(address => uint256) internal s_operatorFeesEarnedUSDC;
    mapping(bytes32 messageId => bool isProcessed) internal s_isMessageProcessed;
}
