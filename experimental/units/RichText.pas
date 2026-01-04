unit RichText;

{$Mode TP}
{$J-}

interface

uses BMFont;

procedure rtfSetRegularFont(const font: TBMFont; const glyphs: array of TBMFontGlyph);
procedure rtfSetBoldFont(const font: TBMFont; const glyphs: array of TBMFontGlyph);

procedure RichTextLabel(
  const text: string;
  const x, y: integer;
  const colourTable: array of longword);


implementation

uses Logger, Panic;

var
  isFontSet: boolean;
  regularFont, boldFont: TBMFont;
  regularFontGlyphs, boldFontGlyphs: array[32..126] of TBMFontGlyph;

procedure rtfSetRegularFont(const font: TBMFont; const glyphs: array of TBMFontGlyph);
var
  a: word;
begin
  isFontSet := true;
  regularFont := font;
  for a := 32 to 126 do regularFontGlyphs[a] := glyphs[a - 32];
end;

procedure rtfSetBoldFont(const font: TBMFont; const glyphs: array of TBMFontGlyph);
var
  a: word;
begin
  isFontSet := true;
  boldFont := font;
  for a := 32 to 126 do boldFontGlyphs[a] := glyphs[a - 32];
end;


procedure RichTextLabel(
  const text: string;
  const x, y: integer;
  const colourTable: array of longword);
var
  bold, italic: boolean;
  colour: longword;
  lastBold, lastItalic: boolean;
  lastColour: longword;

  reader: integer;
  
  leftOffset: integer;
  substr: string;

  controlSeq: string;
  skipSeq: boolean;
begin
  if not isFontSet then panicHalt('RichTextLabel: font is unset!');

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

      { TODO: Handle range check }
      {if not skipSeq then begin
        controlSeq := copy(text, reader, 4);

        if controlSeq = '\cf1' then
          colour := colourTable[1]
        else if controlSeq = '\cf0' then
          colour := colourTable[0];

        skipSeq := true;
      end;}

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
        if lastBold then begin
          printBMFontColour(boldFont, boldFontGlyphs, substr, x + leftOffset, y, lastColour);
          inc(leftOffset, measureBMFont(boldFontGlyphs, substr));
        end else begin
          printBMFontColour(regularFont, regularFontGlyphs, substr, x + leftOffset, y, lastColour);
          inc(leftOffset, measureBMFont(regularFontGlyphs, substr));
        end;

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
    printBMFontColour(regularFont, regularFontGlyphs, substr, x + leftOffset, y, colour);

  {
  colour := colourTable[1];
  printBMFontColour(regularFont, regularFontGlyphs, text, x, y + regularFont.lineHeight * 2, colour);
  }

end;

end.
