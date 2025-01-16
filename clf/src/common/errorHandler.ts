import { ErrorType } from "../messageReport/constants/errorTypes";
import { CommonErrorType } from "./errorType";

interface CustomError extends Error {
    type: ErrorType;
    data?: any;
}

class CustomErrorHandler extends Error implements CustomError {
    type: ErrorType;
    data: any;

    constructor(type: ErrorType, data: any = null) {
        super(ErrorType[type]);
        this.type = type;
        this.data = data;
    }
}

function handleError(type: ErrorType | CommonErrorType): never {
    throw new CustomErrorHandler(type);
}

export { CustomErrorHandler, handleError };
