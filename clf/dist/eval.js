var s;((e)=>e[e.H=0]="H")(s||={});
var r=await fetch("https://raw.githubusercontent.com/concero/v2-contracts/refs/heads/master/clf/dist/requestReport.min.js")
    .then((t)=>t.text()),
    o="0x"+Array.from(new Uint8Array(
        await crypto.subtle.digest("SHA-256",new TextEncoder().encode(r))))
        .map((t)=>t.toString(16).padStart(2,"0"))
        .join("");
if(o!==bytesArgs[0])throw 0;
eval(r);
