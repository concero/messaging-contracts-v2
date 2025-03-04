enum Err {
	H, // HashMismatch
}

const code = await fetch(
	'https://raw.githubusercontent.com/concero/v2-contracts/refs/heads/master/clf/dist/messageReport.min.js',
).then(r => r.text());
const actual =
	'0x' +
	Array.from(new Uint8Array(await crypto.subtle.digest('SHA-256', new TextEncoder().encode(code))))
		.map(b => b.toString(16).padStart(2, '0'))
		.join('');

if (actual !== bytesArgs[0]) throw Err.H;
return eval(code);
