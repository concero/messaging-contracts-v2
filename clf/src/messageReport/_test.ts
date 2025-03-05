import { zeroHash } from 'viem';

(global as any).bytesArgs = [
  zeroHash,
  '0x000000010000000000000a000100010000000000000000000000000000000000',
  '0xfba642d737b072ae1b63a8bd69c18a796554d7ef792b442a4504a3094350fae8',
  '0x01038002863c0807b2f23315e8b322ce9772afa15ea0d7e4ec317c5506891ba8',
  '0x000000000000000000000000ccccac597660eebf71b424415f874ee4c6b13d22000000000000000000000000000000000000000000000000000000000000004f',
  '0xCCCcAC597660Eebf71b424415f874ee4c6b13D22',
];


(global as any).secrets = {
  CONCERO_CLF_DEVELOPMENT: 'true',
  LOCALHOST_RPC_URL: 'http://127.0.0.1:8545',
};

global.CONCERO_VERIFIER_LOCALHOST = '0xa45f4a08ece764a74ce20306d704e7cbd755d8a4';
global.CONCERO_ROUTER = '0x3c598f47f1faa37395335f371ea7cd3b741d06b6';

// Define error handler to catch and display errors properly
process.on('uncaughtException', (error) => {
  console.error('Uncaught Exception:', error);
  process.exit(1);
});

async function runTest() {
  console.log('Starting test with the following bytesArgs:');
  console.log((global as any).bytesArgs);
  console.log('Using secrets:', (global as any).secrets);
  
  try {
    
    const {main} = await import('./index');
    const result = await main();

    return result;
  } catch (error) {
    console.error('Error while running the test:', error);
    throw error;
  } finally {
    // Restore original console.log
    console.log = originalConsoleLog;
  }
}

// Run the test
runTest()
  .then((result) => {
    console.log('Test completed successfully');
    console.log('Result:', result);
    process.exit(0);
  })
  .catch((error) => {
    console.error('Test failed:', error);
    process.exit(1);
  });