unit RichText;

{$Mode TP}
{$J-}

interface

uses BMFont;

procedure rtfSetFont(const font: TBMFont; const glyphs: array of TBMFontGlyph);
procedure rtfSetRegularFont(const font: TBMFont; const glyphs: array of TBMFontGlyph);
procedure rtfSetBoldFont(const font: TBMFont; const glyphs: array of TBMFontGlyph);
procedure rtfSetItalicFont(const font: TBMFont; const glyphs: array of TBMFontGlyph);
procedure rtfSetBoldItalicFont(const font: TBMFont; const glyphs: array of TBMFontGlyph);

procedure RichTextLabel(
  const text: string;
  const x, y: integer;
  const colourTable: array of longword);


implementation

uses Conv, Logger, UStrings, Panic;

var
  isFontSet: boolean;
  regularFont, boldFont, italicFont, boldItalicFont: TBMFont;
  regularFontGlyphs, boldFontGlyphs, italicFontGlyphs, boldItalicFontGlyphs: array[32..126] of TBMFontGlyph;

procedure rtfSetFont(const font: TBMFont; const glyphs: array of TBMFontGlyph);
begin
  isFontSet := true;

  rtfSetRegularFont(font, glyphs);
  rtfSetBoldFont(font, glyphs);
  rtfSetItalicFont(font, glyphs);
  rtfSetBoldItalicFont(font, glyphs);
end;

procedure rtfSetRegularFont(const font: TBMFont; const glyphs: array of TBMFontGlyph);
var
  a: word;
begin
  regularFont := font;
  for a := 32 to 126 do regularFontGlyphs[a] := glyphs[a - 32];
end;

procedure rtfSetBoldFont(const font: TBMFont; const glyphs: array of TBMFontGlyph);
var
  a: word;
begin
  boldFont := font;
  for a := 32 to 126 do boldFontGlyphs[a] := glyphs[a - 32];
end;

procedure rtfSetItalicFont(const font: TBMFont; const glyphs: array of TBMFontGlyph);
var
  a: word;
begin
  italicFont := font;
  for a := 32 to 126 do italicFontGlyphs[a] := glyphs[a - 32];
end;

procedure rtfSetBoldItalicFont(const font: TBMFont; const glyphs: array of TBMFontGlyph);
var
  a: word;
begin
  boldItalicFont := font;
  for a := 32 to 126 do boldItalicFontGlyphs[a] := glyphs[a - 32];
end;


procedure rtfPrintWithFormat(
  const text: string;
  const x, y: integer;
  const bold, italic: boolean;
  const colour: longword;
  var leftOffset: integer);
begin
  if bold and italic then begin
    printBMFontColour(
      boldItalicFont, boldItalicFontGlyphs,
      text,
      x + leftOffset, y, colour);

    inc(leftOffset, measureBMFont(boldItalicFontGlyphs, text));
    
  end else if bold then begin
    printBMFontColour(
      boldFont, boldFontGlyphs,
      text,
      x + leftOffset, y, colour);

    inc(leftOffset, measureBMFont(boldFontGlyphs, text));

  end else if italic then begin
    printBMFontColour(
      italicFont, italicFontGlyphs,
      text,
      x + leftOffset, y, colour);

    inc(leftOffset, measureBMFont(italicFontGlyphs, text));

  end else begin
    printBMFontColour(
      regularFont, regularFontGlyphs,
      text,
      x + leftOffset, y, colour);

    inc(leftOffset, measureBMFont(regularFontGlyphs, text));
  end;
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
  digitChar: char;
  colourIdx: integer;

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
        rtfPrintWithFormat(
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
    rtfPrintWithFormat(
      substr, x, y,
      lastBold, lastItalic, lastColour,
      leftOffset);
end;

end.
