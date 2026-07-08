unit P92Iif;

{$Mode ObjFPC}
{$H-}{$J-}

interface

function I16Iif(const expr: boolean; const truePart, falsePart: smallint): smallint;
function U16Iif(const expr: boolean; const truePart, falsePart: word): word;
function I32Iif(const expr: boolean; const truePart, falsePart: longint): longint;
function U32Iif(const expr: boolean; const truePart, falsePart: longword): longword;
function StringIif(const expr: boolean; const truePart, falsePart: string): string;


implementation

function I16Iif(const expr: boolean; const truePart, falsePart: smallint): smallint;
begin
  if expr then
    I16Iif := truePart
  else
    I16Iif := falsePart;
end;

function U16Iif(const expr: boolean; const truePart, falsePart: word): word;
begin
  if expr then
    U16Iif := truePart
  else
    U16Iif := falsePart;
end;

function I32Iif(const expr: boolean; const truePart, falsePart: longint): longint;
begin
  if expr then
    I32Iif := truePart
  else
    I32Iif := falsePart;
end;

function U32Iif(const expr: boolean; const truePart, falsePart: longword): longword;
begin
  if expr then
    U32Iif := truePart
  else
    U32Iif := falsePart;
end;

function StringIif(const expr: boolean; const truePart, falsePart: string): string;
begin
  if expr then
    StringIif := truePart
  else
    StringIif := falsePart;
end;

end.
