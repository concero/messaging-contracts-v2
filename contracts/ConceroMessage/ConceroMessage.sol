pragma solidity 0.8.20;

import "./Errors.sol";
import {IConceroMessage} from "./Interfaces/IConceroMessage.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ConceroMessageStorage} from "./ConceroMessageStorage.sol";

contract ConceroMessage is IConceroMessage, ConceroMessageStorage {
    using SafeERC20 for IERC20;

    ///////////////////////////////
    /////IMMUTABLE VARIABLES //////
    ///////////////////////////////

    address internal i_USDC;

    //////////////////////////////////
    ////////EXTERNAL FUNCTIONS////////
    //////////////////////////////////

    constructor(address usdc) {
        i_USDC = usdc;
    }

    function sendMessage(Message calldata message) external payable {
        // step 1: validate the message (fee tokens, receiver)
        address feeToken = abi.decode(message.feeToken, (address));
        uint256 fee = getFee(message);

        //step 2: get fees from the user
        if (feeToken == i_USDC) {
            IERC20(i_USDC).safeTransferFrom(msg.sender, address(this), fee);
        }

        //step 3: TODO: transfer token amounts if exists

        //step 4: emit the message
        bytes32 messageId = keccak256(
            abi.encode(message, block.number, block.prevrandao, msg.sender)
        );

        emit ConceroMessage(messageId, message);
    }

    function getFee(Message calldata message) public view returns (uint256) {
        _validateFeeToken(abi.decode(message.feeToken, (address)));
        _validateDstChainSelector(message.dstChainSelector);

        // TODO: add fee calculation logic
        return 50_000; // fee in usdc
    }

    function isChainSupported(uint64 chainSelector) external view returns (bool) {
        return s_supportedChainSelectors[chainSelector];
    }

    //////////////////////////////////
    ////////INTERNAL FUNCTIONS////////
    //////////////////////////////////

    function _validateFeeToken(address feeToken) internal {
        // add this line in future: && feeToken != address(0)

        if (feeToken != i_USDC) {
            revert UnsupportedFeeToken();
        }
    }

    function _validateDstChainSelector(uint64 dstChainSelector) internal {
        if (!s_supportedChainSelectors[dstChainSelector]) {
            revert UnsupportedDstChain();
        }
    }
}
