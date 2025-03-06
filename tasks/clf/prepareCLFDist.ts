function prepareCLFDist(sourceCode: string): string {
	// Regular expression to find the export pattern and capture the module name
	const exportRegex = /export\s*\{([^}]+)\s+as\s+main\}\s*;?\s*$/;

	// Try to match the export pattern
	const match = sourceCode.match(exportRegex);

	if (!match) {
		// If the pattern isn't found, return the original source code
		return sourceCode;
	}

	// Extract the module name (e.g., "aM" from "export{aM as main};")
	const moduleName = match[1].trim();

	// Remove the export statement from the source code
	const codeWithoutExport = sourceCode.replace(exportRegex, "");

	// Append the return statement
	const finalCode = codeWithoutExport + `\nreturn ${moduleName}();\n`;

	return finalCode;
}

export { prepareCLFDist };
