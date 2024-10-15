pragma solidity 0.8.20;

import "./Errors.sol";
import {IConceroRouter} from "./Interfaces/IConceroRouter.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ConceroRouterStorage} from "./ConceroRouterStorage.sol";
import "./Constants.sol";

contract ConceroRouter is IConceroRouter, ConceroRouterStorage {
    using SafeERC20 for IERC20;

    ///////////////////////////////
    /////IMMUTABLE VARIABLES //////
    ///////////////////////////////

    address internal immutable i_USDC;

    //////////////////////////////////
    ////////EXTERNAL FUNCTIONS////////
    //////////////////////////////////

    constructor(address usdc) {
        i_USDC = usdc;
    }

    function sendMessage(Message calldata message) external payable {
        // step 1: validate the message (fee tokens, receiver)
        // TODO: mb validate data and extraArgs
        uint256 fee = getFee(message);

        //step 2: get fees from the user
        if (message.feeToken == i_USDC) {
            IERC20(i_USDC).safeTransferFrom(msg.sender, address(this), fee);
        }

        //step 3: TODO: transfer token amounts if exists

        //step 4: emit the message
        // TODO: add custom nonce to id generation
        bytes32 messageId = keccak256(
            abi.encode(message, block.number, block.prevrandao, msg.sender)
        );

        emit ConceroMessage(messageId, message);
    }

    function getFee(Message calldata message) public view returns (uint256) {
        _validateFeeToken(message.feeToken);
        _validateDstChainSelector(message.dstChainSelector);

        // TODO: add fee calculation logic
        return 50_000; // fee in usdc
    }

    function isChainSupported(uint64 chainSelector) external view returns (bool) {
        return _isChainSupported(chainSelector);
    }

    //////////////////////////////////
    ////////INTERNAL FUNCTIONS////////
    //////////////////////////////////

    function _validateFeeToken(address feeToken) internal view {
        // add this line in future: && feeToken != address(0)

        if (feeToken != i_USDC) {
            revert UnsupportedFeeToken();
        }
    }

    function _validateDstChainSelector(uint64 dstChainSelector) internal view {
        if (!_isChainSupported(dstChainSelector)) {
            revert UnsupportedDstChain();
        }
    }

    function _isChainSupported(uint64 chainSelector) internal view returns (bool) {
        if (_isMainnet()) {
            return _isMainnetChainSupported(chainSelector);
        } else {
            return _isTestnetChainSupported(chainSelector);
        }
    }

    function _isTestnetChainSupported(uint64 chainSelector) internal view returns (bool) {
        if (
            chainSelector == CHAIN_SELECTOR_ARBITRUM_SEPOLIA ||
            chainSelector == CHAIN_SELECTOR_BASE_SEPOLIA ||
            chainSelector == CHAIN_SELECTOR_OPTIMISM_SEPOLIA ||
            chainSelector == CHAIN_SELECTOR_POLYGON_AMOY
        ) {
            return true;
        }

        return false;
    }

    function _isMainnetChainSupported(uint64 chainSelector) internal view returns (bool) {
        if (
            chainSelector == CHAIN_SELECTOR_ARBITRUM ||
            chainSelector == CHAIN_SELECTOR_BASE ||
            chainSelector == CHAIN_SELECTOR_POLYGON ||
            chainSelector == CHAIN_SELECTOR_AVALANCHE ||
            chainSelector == CHAIN_SELECTOR_OPTIMISM
        ) {
            return true;
        }

        return false;
    }

    function _isMainnet() internal view returns (bool) {
        uint256 chainId = block.chainid;

        if (
            chainId == CHAIN_ID_ETHEREUM ||
            chainId == CHAIN_ID_BASE ||
            chainId == CHAIN_ID_AVALANCHE ||
            chainId == CHAIN_ID_ARBITRUM ||
            chainId == CHAIN_ID_POLYGON
        ) {
            return true;
        }

        return false;
    }
}
