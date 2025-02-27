import { ErrorType } from "./errorType";

interface CustomError extends Error {
	type: ErrorType;
	data?: any;
}

class CustomErrorHandler extends Error implements CustomError {
	type: ErrorType;
	data: any;

	constructor(type: ErrorType, data: any = null) {
		super(ErrorType[type]); // Convert enum value to string for error message
		this.type = type;
		this.data = data;
	}
}

function handleError(type: ErrorType): never {
	throw new CustomErrorHandler(type);
}

export { CustomError, CustomErrorHandler, handleError };
