#

Required variables

```pascal
var
  stringBuffer: array[0..255] of byte;
  stringBufferLength: word;
```

Required features

```pascal
function getStringBuffer: pointer;
procedure setStringBufferLength(const length: word);
```

Load a string buffer from JS side:

```js
loadStringBuffer("Your string");

// This is automatically included:
wasm.exports.setStringBufferLength(bytes.length);
```

Then you can use the string buffer to an actual Pascal string

```pascal
strPtrToString(@stringBuffer, stringBufferLength)
```