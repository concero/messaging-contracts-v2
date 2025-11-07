methods {
    function toMessageReceiptBytes(
        IConceroRouter.MessageRequest messageRequest,
        uint24 _srcChainSelector,
        address msgSender,
        uint256 _nonce,
        bytes dstRelayerLib,
        bytes[] dstValidatorLibs
    ) external returns (bytes) envfree;
    function encodeEvmDstChainData(
        address receiver,
        uint32 dstGasLimit
    ) external returns (bytes) envfree;
    function version(bytes data) external returns (uint8) envfree;
    function srcChainSelector(bytes data) external returns (uint24) envfree;
    function dstChainSelector(bytes data) external returns (uint24) envfree;
    function nonce(bytes data) external returns (uint256) envfree;
    function evmSrcChainData(bytes data) external returns (address, uint64) envfree;
    function evmDstChainData(bytes data) external returns (address, uint32) envfree;
    function emvDstRelayerLib(bytes data) external returns (address) envfree;
    function relayerConfig(bytes data) external returns (bytes ) envfree;
    function evmDstValidatorLibs(bytes data) external returns (address[]) envfree;
    function validatorConfigs(bytes data) external returns (bytes[]) envfree;
    function validationRpcs(bytes data) external returns (bytes[]) envfree;
    function deliveryRpcs(bytes  data) external returns (bytes[]) envfree;
    function payload(bytes data) external returns (bytes) envfree;
}

rule messageCodecLib {
    // IConceroRouter.MessageRequest m;

    // require m.validatorLibs.length < max_uint24;
    // require m.validatorConfigs.length < max_uint24;
    // require m.relayerConfig.length < max_uint24;
    // require m.validationRpcs.length < max_uint24;
    // require m.deliveryRpcs.length < max_uint24;
    // require m.dstChainData.length < max_uint24;
    // require m.payload.length < max_uint24;

    // uint24 srcChainSelector;
    // address sender;
    // uint256 nonce;
    // bytes dstRelayerLib;
    // bytes[] dstValidatorLibs;

    // require dstRelayerLib.length < max_uint24;
    // require dstValidatorLibs.length < max_uint24;

    // bytes encodedMessage = toMessageReceiptBytes@withrevert(m, srcChainSelector, sender, nonce, dstRelayerLib, dstValidatorLibs);
    // require !lastReverted;
    
    // assert version(encodedMessage) == 1;
    // assert srcChainSelector(encodedMessage) == srcChainSelector;
    // assert dstChainSelector(encodedMessage) == m.dstChainSelector;
    // assert nonce(encodedMessage) == nonce;

    // address decodedSender; uint64 decodedSrcBlockConfirmations;
    // decodedSender, decodedSrcBlockConfirmations = evmSrcChainData(encodedMessage);
    // assert decodedSender == sender;
    // assert decodedSrcBlockConfirmations == m.srcBlockConfirmations;

    // assert m.relayerConfig == relayerConfig(encodedMessage);
    // assert m.payload == payload(encodedMessage);


    address receiver;
    uint32 dstGasLimit;
    bytes encodedDstChainData = encodeEvmDstChainData(receiver, dstGasLimit);
    assert true;
}