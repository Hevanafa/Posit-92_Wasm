{ Trimmed down version of LOGGER.PAS from POSIT-92 }

unit Logger;

{$Mode TP}

interface

procedure writeLog(const msg: string);
{ Must be registered in importObject }
procedure writeLogI32(const value: longint); external 'env' name 'writeLogI32';
procedure writeLogF32(const value: double); external 'env' name 'writeLogF32';

function getLogBuffer: pointer; public name 'getLogBuffer';
{ Forwards logBuffer to JS }
procedure flushLog; external 'env' name 'flushLog';


implementation

var
  logBuffer: array[0..255] of byte;

procedure writeLog(const msg: string);
var
  a: byte;
  len: word;
begin
  len := length(msg);

  { Cap length to 255 }
  if len > 255 then len := 255;

  logBuffer[0] := len;
  for a:=1 to len do
    logBuffer[a] := ord(msg[a]);

  { JS will read logBuffer }
  flushLog
end;

function getLogBuffer: pointer;
begin
  getLogBuffer := @logBuffer;
end;

end.