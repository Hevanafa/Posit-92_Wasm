{ Trimmed down version of LOGGER.PAS from POSIT-92 }

unit Logger;

{$Mode TP}

interface

{$ifdef WASM}
{ Must be registered in importObject }
procedure writeLogI32(const value: longint); external 'env' name 'writeLogI32';
procedure writeLogF32(const value: double); external 'env' name 'writeLogF32';

function getLogBuffer: pointer; public name 'getLogBuffer';
{ Forwards logBuffer to JS }
procedure flushLog; external 'env' name 'flushLog';
{$endif}
{$ifdef WIN64}
procedure initLogger;
procedure closeLogger;
{$endif}

procedure writeLog(const msg: string);


implementation

{$ifdef WASM}
var
  logBuffer: array[0..255] of byte;
{$endif}
{$ifdef WIN64}
const
  logFilename = 'LOG.TXT';
var
  logFile: Text;
  logOpened: boolean;
{$endif}

procedure initLogger;
begin
  assign(logFile, logFilename);
  {$I-}
  rewrite(logFile);
  {$I+}
  logOpened := (IOResult = 0);
  if not logOpened then begin
    writeLn('Failed to create "' + logFilename + '" file!');
    readLn;
    halt
  end;
end;

procedure closeLogger;
begin
  if logOpened then
    close(logFile);
end;

function getLogBuffer: pointer;
begin
{$ifdef WASM}
  getLogBuffer := @logBuffer
{$else}
  getLogBuffer := nil
{$endif}
end;


procedure writeLog(const msg: string);
{$ifdef WASM}
var
  a: byte;
  len: word;
{$endif}

begin

{$ifdef WASM}
  len := length(msg);

  { Cap length to 255 }
  if len > 255 then len := 255;

  logBuffer[0] := len;
  for a:=1 to len do
    logBuffer[a] := ord(msg[a]);

  { JS will read logBuffer }
  flushLog
{$endif}
{$ifdef WIN64}
  writeln(msg);
  if not logOpened then exit;
  writeln(logFile, msg);
  flush(logFile)
{$endif}
end;


end.