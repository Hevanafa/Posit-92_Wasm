library StrBuffer;

var
  stringBuffer: array[0..255] of byte;

procedure hello; external 'env' name 'hello';
procedure documentWrite; external 'env' name 'documentWrite';

function getStringBuffer: pointer; public name 'getStringBuffer';
begin
  getStringBuffer := @stringBuffer
end;

procedure init;
begin
  fillchar(stringBuffer, 255, 0);
  { hello }
  documentWrite('Hello from Pascal!')
end;

exports
  init;

begin

end.