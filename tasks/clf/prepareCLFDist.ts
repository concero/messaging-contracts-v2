/**
 * Processes JavaScript files to prepare them for distribution by removing export statements
 * and adding a return statement for the main function.
 *
 * @param sourceCode - Source code content to process
 * @param isMinified - Whether the source is minified (affects export pattern matching)
 * @returns Processed source code
 */
function prepareCLFDist(sourceCode: string, isMinified: boolean = false): string {
	if (isMinified) {
		// Pattern for minified files: export{moduleName as main};
		const minifiedExportRegex = /export\s*\{([^}]+)\s+as\s+main\}\s*;?\s*$/;
		const match = sourceCode.match(minifiedExportRegex);

		if (match) {
			const moduleName = match[1].trim();
			const processedCode = sourceCode.replace(minifiedExportRegex, "");
			return processedCode + `\nreturn ${moduleName}();\n`;
		}
	} else {
		// Pattern for unminified files: export { main };
		// This pattern matches the closing brace of the function followed by the export statement
		const unminifiedExportRegex = /\n?\}\n?export\s*\{\s*main\s*\}\s*;?\s*$/;
		if (unminifiedExportRegex.test(sourceCode)) {
			const processedCode = sourceCode.replace(unminifiedExportRegex, "\n}");
			return processedCode + `\nreturn main();\n`;
		}
	}

	// If no patterns matched, return the original code
	console.warn("Export pattern not found in the source code");
	return sourceCode;
}

export { prepareCLFDist };
