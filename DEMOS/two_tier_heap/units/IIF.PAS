unit IIF;

interface

function i16Iif(const expr: boolean; const truePart, falsePart: integer): integer;
function u16Iif(const expr: boolean; const truePart, falsePart: word): word;
function i32Iif(const expr: boolean; const truePart, falsePart: longint): longint;
function u32Iif(const expr: boolean; const truePart, falsePart: longword): longword;
function stringIif(const expr: boolean; const truePart, falsePart: string): string;


implementation

function i16Iif(const expr: boolean; const truePart, falsePart: integer): integer;
begin
  if expr then
    i16Iif := truePart
  else
    i16Iif := falsePart;
end;

function u16Iif(const expr: boolean; const truePart, falsePart: word): word;
begin
  if expr then
    u16Iif := truePart
  else
    u16Iif := falsePart;
end;

function i32Iif(const expr: boolean; const truePart, falsePart: longint): longint;
begin
  if expr then
    i32Iif := truePart
  else
    i32Iif := falsePart;
end;

function u32Iif(const expr: boolean; const truePart, falsePart: longword): longword;
begin
  if expr then
    u32Iif := truePart
  else
    u32Iif := falsePart;
end;

function stringIif(const expr: boolean; const truePart, falsePart: string): string;
begin
  if expr then
    stringIif := truePart
  else
    stringIif := falsePart;
end;

end.