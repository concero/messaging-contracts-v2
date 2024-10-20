pragma solidity 0.8.28;

error MismatchedSignatureArrays();
error IncorrectNumberOfSignatures();
error InvalidSignature();
error DuplicateSignatureDetected(address signer);
error UnauthorizedSigner(address signer);
error UnsupportedFeeToken();
error UnsupportedChainSelector();
error InsufficientFee();
error InvalidMessageHash();
error MessageProcessingFailed(bytes error);
