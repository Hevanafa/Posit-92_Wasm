# Compile targetting wasm32-embedded
E:\lazarus-wasm\fpc\bin\x86_64-win64\fpc.exe -Pwasm32 -Tembedded .\game.pas

if (test-path -path "game.wasm" -pathType leaf) {
	del "game.wasm"
}
ren "game" "game.wasm"