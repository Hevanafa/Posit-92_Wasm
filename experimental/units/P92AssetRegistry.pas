unit P92AssetRegistry;

{$Mode ObjFPC}
{$H-}  { Use ShortStrings }
{$J-}  { Don't allow assignments to typed consts }

interface

{$ifdef P92_WASM}
uses P92AssetHandles, P92BMFont, P92Tex;
{$endif}
{$ifdef P92_SDL2}
uses SDL2_Mixer, P92CoreSDL2, P92BMFont, P92Tex;
{$endif}

type
  TAssetStatus = (
    AssetStatusEmpty,
    AssetStatusLoading,
    AssetStatusReady,
    AssetStatusFailed
  );

  PSoftwareTexEntry = ^TSoftwareTexEntry;
  TSoftwareTexEntry = record
    texture: TSoftwareTex;
    status: TAssetStatus;
    errorCode: smallint;
  end;

  TBMFontLegacyEntry = record
    fontPtr: PBMFontLegacy;
    glyphsPtr: PBMFontGlyph;
    status: TAssetStatus;
    errorCode: smallint;
  end;

  PBMFontEntry = ^TBMFontEntry;
  TBMFontEntry = record
    font: TBMFont;
    status: TAssetStatus;
    errorCode: smallint;
  end;

{$ifdef P92_WASM}
  TSoundEntry = record
    volume: single;
    status: TAssetStatus;
    errorCode: smallint;
  end;
{$endif}

{$ifdef P92_SDL2}
  TSoundEntry = record
    chunk: PMix_Chunk;
    { 0.0 .. 1.0 }
    volume: single;
    status: TAssetStatus;
    errorCode: smallint;
  end;
{$endif}


var
  textures: array[1..255] of TSoftwareTexEntry;
  bmfonts: array[1..9] of TBMFontEntry;
  sounds: array[1..255] of TSoundEntry;

{$ifdef P92_WASM}
function GetAssetReadyCount: longword;
function GetAssetTotalCount: longword;
function AllAssetsReady: boolean;
{$endif}

procedure InitAssetRegistry;

function FindUnusedTextureHandle: TTextureHandle;
function FindUnusedBMFontHandle: TBMFontHandle;
function FindUnusedSoundHandle: TSoundHandle;

{$ifdef P92_WASM}
procedure JsRequestImage(texHandle: longint); external 'env' name 'JsRequestImage';
function RequestImage(const path: string): TTextureHandle;
{$endif}

{ function GetTextureEntryPtr(const texHandle: TTextureHandle): PSoftwareTexEntry; }

function BorrowBMFontEntryPtr(const bmfontHandle: TBMFontHandle): PBMFontEntry;
function BorrowBMFontPtr(const bmfontHandle: TBMFontHandle): PBMFont;

{$ifdef P92_WASM}
procedure JsRequestBMFont(bmfontHandle: longint); external 'env' name 'JsRequestBMFont';
function RequestBMFont(const path: string): longint;

function GetBMFontBufferPtr: pointer; public name 'GetBMFontBufferPtr';
function GetBMFontBufferLen: smallint; public name 'GetBMFontBufferLen';
procedure SetBMFontBufferLen(value: smallint); public name 'SetBMFontBufferLen';
function GetBMFontBufferCapacity: smallint; public name 'GetBMFontBufferCapacity';

procedure JsRequestSound(sndHandle: longint); external 'env' name 'JsRequestSound';
function RequestSound(const path: string): longint;

{ Reporting procedures }

procedure PascalImageLoaded(texHandle: TTextureHandle; w, h: smallint; pixelData: pointer); public name 'PascalImageLoaded';
procedure PascalImageFailed(texHandle: TTextureHandle; errorCode: smallint); public name 'PascalImageFailed';

procedure PascalBMFontLoaded(bmfontHandle: longint); public name 'PascalBMFontLoaded';
procedure PascalBMFontFailed(bmfontHandle: longint; errorCode: smallint); public name 'PascalBMFontFailed';

procedure PascalSoundLoaded(sndHandle: longint); public name 'PascalSoundLoaded';
procedure PascalSoundFailed(sndHandle: longint; errorCode: smallint); public name 'PascalSoundFailed';
{$endif}

{$ifdef P92_SDL2}
function LoadImage(const filename: string): TTextureHandle;
function LoadBMFont(const filename: string): TBMFontHandle;
function HwLoadImage(const filename: string): longint;
function LoadSound(const filename: string): TSoundHandle;
{$endif}


implementation

{$ifdef P92_WASM}
uses
  P92Conversions, P92Logger, P92Panic, P92Strings, P92InteropBuf;
{$endif}
{$ifdef P92_SDL2}
uses SysUtils, SDL2, SDL2_Image, P92TexRef;
{$endif}

{$ifdef P92_WASM}
const
  BMFontBufferCapacity = 32767;

var
  bmfontBuffer: array[0..BMFontBufferCapacity - 1] of byte;
  bmfontBufferLen: smallint;

var
  assetReadyCount, assetTotalCount: longword;

function GetAssetReadyCount: longword;
begin
  GetAssetReadyCount := assetReadyCount
end;

function GetAssetTotalCount: longword;
begin
  GetAssetTotalCount := assetTotalCount
end;

function AllAssetsReady: boolean;
begin
  AllAssetsReady := assetReadyCount >= assetTotalCount
end;

procedure IncAssetReadyCount;
begin
  inc(assetReadyCount)
end;

procedure SetAssetReadyCount(value: longint);
begin
  assetReadyCount := value
end;

procedure SetAssetTotalCount(value: longint);
begin
  assetTotalCount := value
end;
{$endif}

procedure InitAssetRegistry;
var
  a: word;
begin
{$ifdef P92_WASM}
  assetReadyCount := 0;
  assetTotalCount := 0;
{$endif}

  for a:=1 to high(textures) do begin
    textures[a] := default(TSoftwareTexEntry);
    textures[a].status := AssetStatusEmpty;
  end;

  for a:=1 to high(bmfonts) do begin
    bmfonts[a] := default(TBMFontEntry);
    bmfonts[a].status := AssetStatusEmpty;
  end;

  for a:=1 to high(sounds) do begin
    sounds[a] := default(TSoundEntry);
    sounds[a].status := AssetStatusEmpty;
  end;

{$ifdef P92_WASM}
  fillchar(bmfontBuffer, sizeof(bmfontBuffer), 0);
  bmfontBufferLen := 0;
{$endif}
end;

function FindUnusedTextureHandle: TTextureHandle;
var
  a: longint;
begin
  for a:=1 to high(textures) do
    if textures[a].status = AssetStatusEmpty then begin
      FindUnusedTextureHandle := a;
      exit
    end;

  FindUnusedTextureHandle := -1
end;

function FindUnusedBMFontHandle: TBMFontHandle;
var
  a: longint;
begin
  for a:=1 to high(bmfonts) do
    if bmfonts[a].status = AssetStatusEmpty then begin
      FindUnusedBMFontHandle := a;
      exit
    end;

  FindUnusedBMFontHandle := -1
end;

function FindUnusedSoundHandle: TSoundHandle;
var
  a: longint;
begin
  for a:=1 to high(sounds) do
    if sounds[a].status = AssetStatusEmpty then begin
      FindUnusedSoundHandle := a;
      exit
    end;

  FindUnusedSoundHandle := -1
end;

{$ifdef P92_WASM}
function RequestImage(const path: string): TTextureHandle;
var
  texHandle: longint;
begin
  inc(assetTotalCount);

  texHandle := FindUnusedTextureHandle;
  textures[texHandle] := default(TSoftwareTexEntry);
  textures[texHandle].status := AssetStatusLoading;

  WriteLog('RequestImage handle: ' + i32str(texHandle));

  WriteInteropString(path);
  JsRequestImage(texHandle);

  RequestImage := texHandle
end;
{$endif}

{ function GetTextureEntryPtr(const texHandle: TTextureHandle): PSoftwareTexEntry;
begin
  if (texHandle < low(textures)) or (texHandle > high(textures)) then
    PanicHalt('GetTextureEntryPtr: Invalid texHandle: ' + I32Str(texHandle));

  GetTextureEntryPtr := @textures[texHandle]
end; }

function BorrowBMFontEntryPtr(const bmfontHandle: TBMFontHandle): PBMFontEntry;
begin
  if (bmfontHandle < low(bmfonts)) or (bmfontHandle > high(bmfonts)) then
    PanicHalt('GetBMFontEntry: Invalid bmfontHandle: ' + I32Str(bmfontHandle));

  if bmfonts[bmfontHandle].status <> AssetStatusReady then
    PanicHalt('Attempting to use bmfont ' + i32str(bmfontHandle));

  BorrowBMFontEntryPtr := @bmfonts[bmfontHandle]
end;

function BorrowBMFontPtr(const bmfontHandle: TBMFontHandle): PBMFont;
begin
  { if bmfonts[bmfontHandle].status <> AssetStatusReady then
    raise Exception.Create('Attempting to use bmfont ' + i32str(bmfontHandle)); }

  BorrowBMFontPtr := @bmfonts[bmfontHandle]
end;

{$ifdef P92_WASM}
function RequestBMFont(const path: string): longint;
var
  handle: longint;
begin
  inc(assetTotalCount);

  handle := FindUnusedBMFontHandle;

  if handle < 0 then
    PanicHalt('RequestBMFont: BMFont handles are full!');

  RequestBMFont := handle;

  WriteInteropString(path);
  JsRequestBMFont(handle)
end;

function GetBMFontBufferPtr: pointer;
begin
  GetBMFontBufferPtr := @bmfontBuffer[0]
end;

function GetBMFontBufferLen: smallint;
begin
  GetBMFontBufferLen := bmfontBufferLen
end;

function GetBMFontBufferCapacity: smallint;
begin
  GetBMFontBufferCapacity := BMFontBufferCapacity
end;

procedure SetBMFontBufferLen(value: smallint);
begin
  bmfontBufferLen := value
end;

function RequestSound(const path: string): longint;
var
  sndHandle: longint;
begin
  inc(assetTotalCount);
  WriteLog('RequestSound: inc assetTotalCount');

  sndHandle := FindUnusedSoundHandle;

  if sndHandle < 0 then
    PanicHalt('RequestSound: Sound handles are full!');

  sounds[sndHandle] := default(TSoundEntry);
  sounds[sndHandle].status := AssetStatusLoading;

  WriteInteropString(path);
  JsRequestSound(sndHandle);

  RequestSound := sndHandle
end;
{$endif}

{$ifdef P92_SDL2}
function LoadImage(const filename: string): TTextureHandle;
var
  strBuffer: array[0..255] of char;
  surface: PSDL_Surface;
  texHandle: TTextureHandle;
  texture: PSoftwareTex;
  src, dest: PByte;
begin
  { writeLog('loadImage ' + filename); }

  strpcopy(strBuffer, filename);
  surface := IMG_Load(strBuffer);

  if surface = nil then begin
    writeLog('loadImage: Failed to load ' + filename);
    loadImage := -1;
    exit
  end;

  if surface^.format^.BitsPerPixel <> 32 then begin
    WriteWarn('loadImage: Warning: ' + filename + ' is not 32 BPP!');
    writeLog('loadImage: Convert it to 32 BPP then reload');
    SDL_FreeSurface(surface);
    loadImage := -1;
    exit
  end;

  texHandle := NewTexture(surface^.w, surface^.h);
  texture := BorrowTexturePtr(texHandle);

  src := PByte(surface^.pixels);
  dest := texture^.pixelData;
  move(src^, dest^, surface^.w * surface^.h * 4);

  SDL_FreeSurface(surface);
  loadImage := texHandle
end;

{ 32 to 126: 0 to 94 }
function LoadBMFont(const filename: string): TBMFontHandle;
var
  fontHandle: TBMFontHandle;
  font: PBMFont;

  f: text;
  textureFilename: string;
  txtLine: string;
  a: word;
  pairs: array[0..15] of string;
  pair: array[0..1] of string;
  k, v: string;
  newGlyph: TBMFontGlyph;
  glyphCount: word;
begin
  fontHandle := FindUnusedBMFontHandle;

  bmfonts[fontHandle].status := AssetStatusLoading;
  bmfonts[fontHandle].errorCode := 0;

  LoadBMFont := fontHandle;
  font := BorrowBMFontPtr(fontHandle);

  assign(f, filename);
  {$I-} reset(f); {$I+}

  if IOResult <> 0 then begin
    writeLog('Failed to open BMFont file: ' + filename);
    exit
  end;

  glyphCount := 0;

  while not eof(f) do begin
    readln(f, txtLine);

    if startsWith(txtLine, 'info') then begin
      split(txtLine, ' ', pairs);

      for a:=0 to high(pairs) do begin
        split(pairs[a], '=', pair);
        k := pair[0]; v := pair[1];

        { writeln('info ', k); }

        { if k = 'face' then
          font^.face := replaceAll(v, '"', '')
        else} if k = 'spacing' then begin
          split(v, ',', pair);
          font^.spacing[0] := parseInt(pair[0]);
          font^.spacing[1] := parseInt(pair[1]);
        end;
      end;

      { writeLog('font.face:' + font.face) }

    end else if startsWith(txtLine, 'common') then begin
      split(txtLine, ' ', pairs);

      for a:=0 to high(pairs) do begin
        split(pairs[a], '=', pair);
        k := pair[0]; v := pair[1];

        if k = 'lineHeight' then
          font^.lineHeight := parseInt(v);
      end;

    end else if startsWith(txtLine, 'page') then begin
      split(txtLine, ' ', pairs);

      for a:=0 to high(pairs) do begin
        split(pairs[a], '=', pair);
        k := pair[0]; v := pair[1];

        if k = 'file' then
          textureFilename := replaceAll(v, '"', '');
      end;

    end else if startsWith(txtLine, 'char') and not startsWith(txtLine, 'chars') then begin
      while contains(txtLine, '  ') do
        txtLine := replaceAll(txtLine, '  ', ' ');

      newGlyph := default(TBMFontGlyph);

      { Parse the whole line first, then copy the record to the list of font glyphs }
      split(txtLine, ' ', pairs);

      for a:=0 to high(pairs) do begin
        split(pairs[a], '=', pair);
        k := pair[0]; v := pair[1];

        { case-of can't be used with strings in Mode TP }
        if k = 'id' then
          newGlyph.id := parseInt(v)
        else if k = 'x' then
          newGlyph.x := parseInt(v)
        else if k = 'y' then
          newGlyph.y := parseInt(v)
        else if k = 'width' then
          newGlyph.width := parseInt(v)
        else if k = 'height' then
          newGlyph.height := parseInt(v)
        else if k = 'xoffset' then
          newGlyph.xoffset := parseInt(v)
        else if k = 'yoffset' then
          newGlyph.yoffset := parseInt(v)
        else if k = 'xadvance' then
          newGlyph.xadvance := parseInt(v);
      end;

      if newGlyph.id in [low(font^.glyphs)..high(font^.glyphs)] then begin
        font^.glyphs[newGlyph.id] := newGlyph;
        inc(glyphCount)
      end;
    end;
  end;

  close(f);

  { writeLog('Loaded ' + i32str(glyphCount) + ' glyphs'); }
  bmfonts[fontHandle].status := AssetStatusReady;
  bmfonts[fontHandle].errorCode := 0;

  font^.texHandle := LoadImage(textureFilename)
end;

function HwLoadImage(const filename: string): longint;
var
  surface: PSDL_Surface;
  tex: PSDL_Texture;
begin
  surface := IMG_Load(pchar(ansistring(filename)));
  if surface = nil then begin
    writelog('IMG_Load failed: ' + SDL_GetError);
    exit(-1)
  end;

  tex := SDL_CreateTextureFromSurface(renderer, surface);
  if tex = nil then begin
    writelog('CreateTexture failed: ' + SDL_GetError);
    exit(-1)
  end;

  SDL_FreeSurface(surface);

  SDL_SetTextureBlendMode(tex, SDL_BLENDMODE_BLEND);
  hwLoadImage := HwRegisterTexRef(tex, surface^.w, surface^.h);

  { writelog(format('hwLoadImage %d: %s', [hwLoadImage, filename])) }
end;


function LoadSound(const filename: string): TSoundHandle;
var
  sndHandle: TSoundHandle;
  strBuffer: array[0..255] of char;
  chunk: PMix_Chunk;
begin
  sndHandle := FindUnusedSoundHandle;

{
  writeLog('loadSound:');
  writeLogI32(key);
  writeLog(filename);
}

  { Assuming that SDL2 mixer is always initialised }
  { if not soundsInitialised then exit; }

  LoadSound := sndHandle;

  fillchar(strBuffer, length(strBuffer), #0);
  strpcopy(strBuffer, filename);
  chunk := Mix_LoadWAV(strBuffer);

  if chunk = nil then begin
    writeLog('loadSound: Failed to load ' + filename);
    exit
  end;

  if sounds[sndHandle].chunk <> nil then begin
    writeLog('loadSound: Warning: Possibly duplicate sound key ' + i32str(sndHandle));
    Mix_FreeChunk(sounds[sndHandle].chunk);
    exit
  end;

  sounds[sndHandle].status := AssetStatusReady;
  sounds[sndHandle].errorCode := 0;
  sounds[sndHandle].chunk := chunk;
  sounds[sndHandle].volume := 1.0;
end;
{$endif}

{$ifdef P92_WASM}
{ Report asset state to Pascal }

procedure PascalImageLoaded(texHandle: TTextureHandle; w, h: smallint; pixelData: pointer);
begin
  if (texHandle < 1) or (texHandle >= high(textures)) then
    PanicHalt('Invalid texture handle: ' + I32Str(texHandle));

  textures[texHandle].texture.width := w;
  textures[texHandle].texture.height := h;
  textures[texHandle].texture.allocSize := w * h * 4;
  textures[texHandle].texture.pixelData := pixelData;

  textures[texHandle].status := AssetStatusReady;
  textures[texHandle].errorCode := 0;

  inc(assetReadyCount);
  WriteLog('Image: inc assetReadyCount');
end;

procedure PascalImageFailed(texHandle: TTextureHandle; errorCode: smallint);
begin
  textures[texHandle].status := AssetStatusFailed;
  textures[texHandle].errorCode := errorCode;
end;
{$endif}

{ Used to help debug BMFont glyphs }
{
procedure DumpBMFontGlyphs(bmfontHandle: longint);
var
  a: smallint;
begin
  for a:=0 to high(bmfonts[bmfontHandle].font.glyphs) do begin
    with bmfonts[bmfontHandle].font do begin
      writelog(format('%d - x:%d, y:%d, width:%d, height:%d, xoffset:%d, yoffset:%d, xadvance:%d', [
        glyphs[a].id, glyphs[a].x, glyphs[a].y, glyphs[a].width, glyphs[a].height, glyphs[a].xoffset, glyphs[a].yoffset, glyphs[a].xadvance
      ]));
    end
  end;
end;
}

{$ifdef P92_WASM}
procedure ParseBMFontLine(bmfontHandle: longint; line: ShortString);
var
  filename: shortstring;
  kvPairs: array[0..19] of shortstring;
  token: shortstring;
  k, v: shortstring;

  idx: smallint;
  openQuote, closeQuote: smallint;
  pair: array[0..1] of shortstring;

  newGlyph: TBMFontGlyph;

begin
  filename := '';

  { Parse BMFont header }
  if StartsWith(line, 'info') then begin
    split(line, ' ', kvPairs);

    for token in kvPairs do begin
      split(token, '=', pair);
      k := pair[0];
      v := pair[1];

      if k = 'face' then begin
        { Find the first " then the second " }
        idx := pos('face', line);
        openQuote := pos('"', line, idx + 1);
        closeQuote := pos('"', line, openQuote + 1);
        WriteLog('Font name:' + copy(line, openQuote + 1, closeQuote - openQuote - 1));
      end
      else if k = 'spacing' then begin
        split(v, ',', pair);

        with bmfonts[bmfontHandle].font do begin
          spacing[0] := ParseInt(pair[0]);
          spacing[1] := ParseInt(pair[1]);
        end;
      end;
    end;
  end
  else if StartsWith(line, 'common') then begin
    split(line, ' ', kvPairs);

    for token in kvPairs do begin
      split(token, '=', pair);
      k := pair[0];
      v := pair[1];

      if k = 'lineHeight' then begin
        bmfonts[bmfontHandle].font.lineHeight :=
          ParseInt(v);
      end;
    end;
  end
  else if StartsWith(line, 'page') then begin
    split(line, ' ', kvPairs);

    for token in kvPairs do begin
      split(token, '=', pair);
      k := pair[0];
      v := pair[1];

      if k = 'file' then begin
        idx := pos('file', line);
        openQuote := pos('"', line, idx + 1);
        closeQuote := pos('"', line, openQuote + 1);

        filename := copy(line, openQuote + 1, closeQuote - openQuote - 1);

        writelog('Filename: ' + filename);
        bmfonts[bmfontHandle].font.texHandle :=
          RequestImage(filename);
      end;
    end;
  end

  { Parse BMFont glyphs }
  else if (not StartsWith(line, 'chars')) and StartsWith(line, 'char') then begin
    while Contains(line, '  ') do
      line := ReplaceAll(line, '  ', ' ');

    Split(line, ' ', kvPairs);

    { Parse the whole glyph first then push }
    newGlyph := default(TBMFontGlyph);

    for token in kvPairs do begin
      split(token, '=', pair);
      k := pair[0];
      v := pair[1];

      if k = 'id' then
        newGlyph.id := ParseInt(v)
      else if k = 'x' then
        newGlyph.x := ParseInt(v)
      else if k = 'y' then
        newGlyph.y := ParseInt(v)
      else if k = 'width' then
        newGlyph.width := ParseInt(v)
      else if k = 'height' then
        newGlyph.height := ParseInt(v)
      else if k = 'xoffset' then
        newGlyph.xoffset := ParseInt(v)
      else if k = 'yoffset' then
        newGlyph.yoffset := ParseInt(v)
      else if k = 'xadvance' then
        newGlyph.xadvance := ParseInt(v);
    end;

    bmfonts[bmfontHandle].font.glyphs[newGlyph.id] := newGlyph
  end;
end;

procedure PascalBMFontLoaded(bmfontHandle: longint);
var
  line: string;
  lineStart: smallint;
  lineLen: longint;

  byteIdx: longint;
begin
  bmfonts[bmfontHandle].status := AssetStatusReady;
  bmfonts[bmfontHandle].errorCode := 0;

  { Apparently SetString does byteIdx heap allocation }
  { SetString(line, PAnsiChar(@bmfontBuffer[0]), bmfontBufferLen); }

  writelog('buffer len: ' + i32str(bmfontBufferLen));

  line := '';
  byteIdx := 0;
  lineStart := 0;

  while byteIdx < bmfontBufferLen do begin
    if bmfontBuffer[byteIdx] = 13 then begin
      inc(byteIdx);
      continue
    end;

    if bmfontBuffer[byteIdx] = 10 then begin
      SetString(line, PAnsiChar(@bmfontBuffer[lineStart]), byteIdx - lineStart);
      ParseBMFontLine(bmfontHandle, line);

      { writelog('lineStart: ' + i32str(lineStart)); }

      lineStart := byteIdx + 1
    end;

    inc(byteIdx)
  end;

  if lineStart < bmfontBufferLen then begin
    SetString(line, PAnsiChar(@bmfontBuffer[lineStart]), bmfontBufferLen - lineStart);

    { writelog('(Last line)');
    writelog('Line start: ' + i32str(lineStart));
    writelog('Buffer len: ' + i32str(bmfontBufferLen)); }

    ParseBMFontLine(bmfontHandle, line);
  end;

  { for debugging }
  { DumpBMFontGlyphs(bmfontHandle); }

  { writelog(
    'Font ' + i32str(bmfontHandle) + ' texHandle: ' +
    i32str(bmfonts[bmfontHandle].font.texHandle)); }

  inc(assetReadyCount);
  WriteLog('BMFont: inc assetReadyCount');
end;

procedure PascalBMFontFailed(bmfontHandle: longint; errorCode: smallint);
begin
  bmfonts[bmfontHandle].status := AssetStatusFailed;
  bmfonts[bmfontHandle].errorCode := errorCode
end;

procedure PascalSoundLoaded(sndHandle: longint);
begin
  sounds[sndHandle].status := AssetStatusReady;
  sounds[sndHandle].errorCode := 0;

  inc(assetReadyCount);
  WriteLog('Sound: inc assetReadyCount');
end;

procedure PascalSoundFailed(sndHandle: longint; errorCode: smallint);
begin
  sounds[sndHandle].status := AssetStatusFailed;
  sounds[sndHandle].errorCode := errorCode
end;
{$endif}

end.
