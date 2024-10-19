pragma solidity 0.8.28;

error MismatchedSignatureArrays();
error IncorrectNumberOfSignatures(uint256 expected, uint256 received);
error InvalidSignature();
error DuplicateSignatureDetected(address signer);
error UnauthorizedSigner(address signer);
error UnsupportedFeeToken();
error UnsupportedChainSelector();
error UnsupportedDstChain();
