import { ErrorCode } from "./code.ts";

export class DomainError extends Error  {
	type: ErrorCode;
	data: unknown;

	constructor(type: ErrorCode, data: unknown = null) {
		super(type.toString());
		this.type = type;
		this.data = data;
	}
}