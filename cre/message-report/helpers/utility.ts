export namespace Utility {
	export function safeJSONStringify(obj: object): string {
		return JSON.stringify(obj, (_, value) =>
			typeof value === "bigint" ? `0x${value.toString(16)}` : value,
		);
	}

	export function safeJSONParse<T = unknown>(json: string): T {
		if (typeof json !== "string") {
			json = JSON.stringify(json);
		}

		const parsed = JSON.parse(json, (key, value) => {
			if (
				key === "blockNumber" &&
				typeof value === "string" &&
				/^0x[0-9a-fA-F]+$/.test(value)
			) {
				try {
					return BigInt(value);
				} catch {
					return value;
				}
			}
			return value;
		});

		if (
			parsed &&
			typeof parsed === "object" &&
			!Array.isArray(parsed) &&
			Object.keys(parsed).every(k => /^\d+$/.test(k))
		) {
			return Object.values(parsed) as T;
		}

		return parsed;
	}
}
