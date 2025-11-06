using MockConceroRelayerLib as relayer;
using MockConceroValidatorLib as validator;
using MockPriceFeed as priceFeed;


methods {
    function relayer.getFee(IConceroRouter.MessageRequest) external returns (uint256) envfree;
    function validator.getFee(IConceroRouter.MessageRequest) external returns (uint256) envfree;
    function priceFeed.getUsdRate(address) external returns (uint256) envfree => ALWAYS(0) ALL;

    function getMessageFee(IConceroRouter.MessageRequest) external returns (uint256) envfree;
    function setMaxValidatorsCount(uint16) external envfree;
    function setMaxMessageSize(uint64) external envfree;
}

function setup(IConceroRouter.MessageRequest m) {
    address zeroAddress = 0;

    setMaxValidatorsCount(1);
    setMaxMessageSize(1000000);

    require m.feeToken == zeroAddress;
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