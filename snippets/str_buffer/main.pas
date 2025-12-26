library StrBuffer;

var
  stringBuffer: array[0..255] of byte;
  stringBufferLength: word;

procedure hello; external 'env' name 'hello';
procedure documentWrite; external 'env' name 'documentWrite';

{ Requires at least 1 `exports` item to use `public name` }
function getStringBuffer: pointer; public name 'getStringBuffer';
begin
  getStringBuffer := @stringBuffer
end;

procedure loadStringBuffer(const str: string);
var
  a: word;
begin
  stringBuffer[0] := length(str);

  for a:=1 to length(str) do
    stringBuffer[a] := ord(str[a]);
end;

procedure setStringBufferLength(const length: word); public name 'setStringBufferLength';
begin
  stringBufferLength := length
end;


procedure init; public name 'init';
begin
  fillchar(stringBuffer, 255, 0);

  hello;

  loadStringBuffer('Hello from Pascal!');
  documentWrite
end;

exports
  init;

begin

end.