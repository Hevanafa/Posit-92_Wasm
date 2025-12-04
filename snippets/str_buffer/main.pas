library StrBuffer;

var
  stringBuffer: array[0..255] of byte;

procedure hello; external 'env' name 'hello';
procedure documentWrite; external 'env' name 'documentWrite';

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


procedure init;
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