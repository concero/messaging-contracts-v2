import { ProxyEnum, conceroNetworks, getViemReceiptConfig } from "../../constants";
import { err, getEnvAddress, getFallbackClients, getViemAccount, log } from "../../utils";

export async function changeProxyAdminOwner(
	chains: string,
	newOwner: string,
	proxyType: ProxyEnum,
) {
	let chainNames: string[] | undefined;

	if (chains && chains.trim() !== "") {
		chainNames = chains
			.split(",")
			.map(chain => chain.trim())
			.filter(Boolean);
	}

	const { abi } = await import(
		"../../artifacts/contracts/Proxy/ConceroProxyAdmin.sol/ConceroProxyAdmin.json"
	);

	const networksToCheck = Object.entries(conceroNetworks)
		.filter(([_, network]) => network.type === "testnet")
		.filter(([name, _]) => !chainNames || chainNames.includes(name))
		.map(([name, network]) => ({ name, network: network }));

	for (const { name, network } of networksToCheck) {
		const viemAccount = getViemAccount(network.type, "deployer"); // TODO: change to proxyDeployer
		const [proxyAdmin] = getEnvAddress(`${proxyType}Admin`, name);
		const { walletClient, publicClient } = getFallbackClients(network, viemAccount);

		const currentOwner = await publicClient.readContract({
			address: proxyAdmin,
			abi,
			functionName: "owner",
		});

		if (currentOwner === newOwner) {
			log(
				`Admin owner is already set to ${newOwner}, proxyAdmin address: ${proxyAdmin}`,
				"changeProxyAdminOwner",
				name,
			);
			continue;
		} else {
			log(
				`Setting admin owner for ${proxyType}Admin on ${name}, proxyAdmin address: ${proxyAdmin}`,
				"changeProxyAdminOwner",
			);

			try {
				const txHash = await walletClient.writeContract({
					address: proxyAdmin,
					abi,
					functionName: "transferOwnership",
					account: viemAccount,
					args: [newOwner],
				});

				const receipt = await publicClient.waitForTransactionReceipt({
					...getViemReceiptConfig(name),
					hash: txHash,
				});

				log(
					`${proxyType}Admin owner successfully changed; hash: ${receipt.transactionHash}`,
					"changeProxyAdminOwner",
					name,
				);
			} catch (error) {
				err(
					`Error changing proxy admin owner for ${name}: ${error}`,
					"changeProxyAdminOwner",
				);
			}
		}
	}
}
