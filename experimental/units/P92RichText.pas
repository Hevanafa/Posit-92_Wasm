unit P92RichText;

{$Mode ObjFPC}
{$H+}{$J-}

interface

uses P92AssetHandles;

{ Assign all 4 font styles & weights }
procedure RtfSetFont(const font: TBMFontHandle);

procedure RtfSetRegularFont(const font: TBMFontHandle);
procedure RtfSetBoldFont(const font: TBMFontHandle);
procedure RtfSetItalicFont(const font: TBMFontHandle);
procedure RtfSetBoldItalicFont(const font: TBMFontHandle);

procedure RichTextLabel(
  const text: string;
  const x, y: smallint;
  const colourTable: array of longword
);


implementation

uses P92Conversions, P92Logger, P92BMFont, P92Strings, P92Panic;

var
  fontRegular, fontBold, fontItalic, fontBoldItalic: TBMFontHandle;

procedure RtfSetFont(const font: TBMFontHandle);
begin
  RtfSetRegularFont(font);
  RtfSetBoldFont(font);
  RtfSetItalicFont(font);
  RtfSetBoldItalicFont(font);
end;

function IsFontSet: boolean;
begin
  IsFontSet := (fontRegular > 0) and (fontItalic > 0) and (fontBold > 0) and (fontBoldItalic > 0)
end;

procedure RtfSetRegularFont(const font: TBMFontHandle);
begin
  fontRegular := font
end;

procedure RtfSetBoldFont(const font: TBMFontHandle);
begin
  fontBold := font
end;

procedure RtfSetItalicFont(const font: TBMFontHandle);
begin
  fontItalic := font
end;

procedure RtfSetBoldItalicFont(const font: TBMFontHandle);
begin
  fontBoldItalic := font
end;


procedure RtfPrintWithFormat(
  const text: string;
  const x, y: smallint;
  const bold, italic: boolean;
  const colour: longword;
  var leftOffset: smallint
);
begin
  if bold and italic then begin
    PrintBMFontColour(
      fontBoldItalic,
      text,
      x + leftOffset, y, colour);

    inc(leftOffset, measureBMFont(fontBoldItalic, text));
    
  end else if bold then begin
    PrintBMFontColour(
      fontBold,
      text,
      x + leftOffset, y, colour);

    inc(leftOffset, measureBMFont(fontBold, text));

  end else if italic then begin
    printBMFontColour(
      fontItalic,
      text,
      x + leftOffset, y, colour);

    inc(leftOffset, measureBMFont(fontItalic, text));

  end else begin
    printBMFontColour(
      fontRegular,
      text,
      x + leftOffset, y, colour);

    inc(leftOffset, measureBMFont(fontRegular, text));
  end;
end;


procedure RichTextLabel(
  const text: string;
  const x, y: smallint;
  const colourTable: array of longword);
var
  bold, italic: boolean;
  colour: longword;
  lastBold, lastItalic: boolean;
  lastColour: longword;

  reader: smallint;
  leftOffset: smallint;
  substr: string;
  digitChar: char;
  colourIdx: smallint;

  controlSeq: string;
  skipSeq: boolean;
begin
  if not isFontSet then PanicHalt('RichTextLabel: font is unset!');

  { init internal state }
  bold := false;
  italic := false;
  colour := colourTable[0];
  lastBold := bold;
  lastItalic := italic;
  lastColour := colour;

  { reader + renderer }
  substr := '';
  reader := 1;
  leftOffset := 0;
  while reader <= length(text) do begin
    { writeLog(text[reader]); }

    if text[reader] <> '\' then begin
      substr := substr + text[reader];
      inc(reader)
    end else begin
      { Parse control sequence }
      skipSeq := false;
      if copy(text, reader, 6) = '\plain' then begin
        controlSeq := copy(text, reader, 6);
        bold := false;
        italic := false;
        colour := colourTable[0];

        skipSeq := true;
      end;

      if not skipSeq then begin
        controlSeq := copy(text, reader, 4);

        { \cf0, \cf1, \cf2 and so on }
        if startsWith(controlSeq, '\cf') then begin
          digitChar := controlSeq[4];

          if digitChar in ['0'..'9'] then begin
            colourIdx := ord(digitChar) - ord('0');

            if colourIdx <= high(colourTable) then begin
              colour := colourTable[colourIdx];
              skipSeq := true
            end else
              panicHalt('RichTextLabel: Colour index out of bounds ' + i32str(colourIdx));
          end else
            panicHalt('RichTextLabel: Invalid colour code format ' + controlSeq);
        end;
      end;

      if not skipSeq then begin
        controlSeq := copy(text, reader, 3);
        
        if controlSeq = '\b0' then begin
          bold := false;
          skipSeq := true
        end else if controlSeq = '\i0' then begin
          italic := false;
          skipSeq := true
        end;
      end;

      if not skipSeq then begin
        controlSeq := copy(text, reader, 2);

        if controlSeq = '\b' then
          bold := true
        else if controlSeq = '\i' then
          italic := true;
      end;

      { Commit buffer }
      if length(substr) > 0 then begin
        RtfPrintWithFormat(
          substr, x, y,
          lastBold, lastItalic, lastColour,
          leftOffset);

        substr := '';
      end;
      
      lastBold := bold;
      lastItalic := italic;
      lastColour := colour;
      inc(reader, length(controlSeq));
      controlSeq := ''
    end;
  end;

  { Commit leftover string buffer }
  if length(substr) > 0 then
    RtfPrintWithFormat(
      substr, x, y,
      lastBold, lastItalic, lastColour,
      leftOffset);
end;

begin
  fontRegular := 0;
  fontBold := 0;
  fontItalic := 0;
  fontBoldItalic := 0;
end.

