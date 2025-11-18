{ Trimmed down version of LOGGER.PAS from POSIT-92 }

unit Logger;

interface

procedure writeLog(const msg: string);
function getLogBuffer: pointer; public name 'getLogBuffer';


implementation

var
  logBuffer: array[0..255] of byte;

procedure writeLog(const msg: string);
var
  a, len: byte;
begin
  len := length(msg);
  { Cap length to 255 }
  if len > 255 then len := 255;

  logBuffer[0] := len;
  if a:=1 to len do
    logBuffer[a] := ord(msg[a]);

  { TODO: JS will read logBuffer }
end;

function getLogBuffer: pointer;
begin
  getLogBuffer := @logBuffer;
end;

end.