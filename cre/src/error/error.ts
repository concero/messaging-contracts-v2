import { ErrorTypes } from "./types";

export class CustomError extends Error  {
	type: ErrorTypes.Type;
	data: unknown;

	constructor(type: ErrorTypes.Type, data: unknown = null) {
		super(type.toString());
		this.type = type;
		this.data = data;
	}
}