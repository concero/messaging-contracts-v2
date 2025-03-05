import {
	CLF_OPERATOR_REGISTRATION_JS_URL,
	CLF_REQUEST_REPORT_JS_URL,
} from "../constants/functionsJsCodeUrls";

export enum ClfJsCodeType {
	MessageReport,
	OperatorRegistration,
}

async function fetchCode(url: string) {
	const response = await fetch(url);

	if (!response.ok) {
		throw new Error(`Failed to fetch code from ${url}: ${response.statusText}`);
	}

	return response.text();
}

export async function getClfJsCode(clfJsCodeType: ClfJsCodeType) {
	switch (clfJsCodeType) {
		case ClfJsCodeType.MessageReport:
			return fetchCode(CLF_REQUEST_REPORT_JS_URL);
		case ClfJsCodeType.OperatorRegistration:
			return fetchCode(CLF_OPERATOR_REGISTRATION_JS_URL);
		default:
			throw new Error(`Unknown ClfJsCodeType: ${clfJsCodeType}`);
	}
}
