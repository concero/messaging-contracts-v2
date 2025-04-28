const code = await fetch(
    "https://raw.githubusercontent.com/concero/messaging-contracts-v2/refs/heads/master/clf/dist/messageReport.min.js",
).then(r => r.text());
const actual =
    "0x" +
    Array.from(new Uint8Array(await crypto.subtle.digest("SHA-256", new TextEncoder().encode(code))))
        .map(b => b.toString(16).padStart(2, "0"))
        .join("");

if (actual.toLowerCase() !== bytesArgs[0].toLowerCase()) throw "hash mismatch";
return eval(code);
