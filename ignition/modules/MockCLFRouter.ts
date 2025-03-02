import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("MockCLFRouter", m => {
	const deployer = m.getAccount(0);

	const mockCLFRouter = m.contract("MockCLFRouter", [], {
		from: deployer,
	});

	return {
		mockCLFRouter,
	};
});
