# Compile targetting wasm32-embedded
E:\lazarus-wasm\fpc\bin\x86_64-win64\fpc.exe -Pwasm32 -Tembedded .\gradient.pas

if (test-path -path "gradient.wasm" -pathType leaf) {
	del "gradient.wasm"
}
ren "gradient" "gradient.wasm"