// try {
// 	const [t, p] = await Promise.all([
// 		fetch('https://raw.githubusercontent.com/ethers-io/ethers.js/v6.10.0/dist/ethers.umd.min.js'),
// 		fetch('https://raw.githubusercontent.com/concero/v2-contracts/refs/heads/master/clf/dist/requestReport.min.js'),
// 	]);
// 	const [e, c] = await Promise.all([t.text(), p.text()]);
// 	const g = async s => {
// 		return (
// 			'0x' +
// 			Array.from(new Uint8Array(await crypto.subtle.digest('SHA-256', new TextEncoder().encode(s))))
// 				.map(v => ('0' + v.toString(16)).slice(-2).toLowerCase())
// 				.join('')
// 		);
// 	};
// 	const r = await g(c);
// 	const x = await g(e);
// 	const b = bytesArgs[0].toLowerCase();
// 	const o = bytesArgs[1].toLowerCase();
// 	if (r === b && x === o) {
// 		const ethers = new Function(e + '; return ethers;')();
// 		return await eval(c);
// 	}
// 	throw new Error(`${r}!=${b}||${x}!=${o}`);
// } catch (e) {
// 	throw new Error(e.message.slice(0, 255));
// }
//

enum Err {
	H, // HashMismatch
}

const code = await fetch(
	'https://raw.githubusercontent.com/concero/v2-contracts/refs/heads/master/clf/dist/requestReport.min.js',
).then(r => r.text());
const actual =
	'0x' +
	Array.from(new Uint8Array(await crypto.subtle.digest('SHA-256', new TextEncoder().encode(code))))
		.map(b => b.toString(16).padStart(2, '0'))
		.join('');

if (actual !== bytesArgs[0]) throw Err.H;
eval(code);
