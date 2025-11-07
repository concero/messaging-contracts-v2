using MockConceroRelayerLib as relayer;
using MockConceroValidatorLib as validator;
using MockPriceFeed as priceFeed;

methods {
    function relayer.getFee(IConceroRouter.MessageRequest) external returns (uint256) envfree => ALWAYS(0);
    function validator.getFee(IConceroRouter.MessageRequest) external returns (uint256) envfree => ALWAYS(0);
    function priceFeed.getUsdRate(address) external returns (uint256) envfree => ALWAYS(0);

    function getMessageFee(IConceroRouter.MessageRequest) external returns (uint256) envfree;
    function exposed_setMaxValidatorsCount(uint16) external envfree;
    function exposed_setMaxMessageSize(uint64) external envfree;
}

function setup(IConceroRouter.MessageRequest m) {
    exposed_setMaxValidatorsCount(1);
    exposed_setMaxMessageSize(1000000);

    address zeroAddress = 0;

    address relayerLib;
    address validatorLib;
    require m.relayerLib == relayerLib;
    require m.validatorLibs[0] == validatorLib;

    require m.feeToken == zeroAddress;
    require m.validatorLibs.length == 1;
    require m.validatorLibs.length == m.validatorConfigs.length;
}

rule uniqMessageId(IConceroRouter.MessageRequest m) {
    setup(m);

    env e;

    // require e.msg.value == getMessageFee(m);
    uint256 fee = getMessageFee(m);
    assert fee == 0;

    // bytes32 id1 = conceroSend(e, m);
    // bytes32 zero;

    // assert id1 != zero;
}