library Game;

{$Mode ObjFPC}
{$J-}  { Switch off assignments to typed constants }

uses
  Loading, Fullscreen,
  Conv, FPS, Graphics, Logger,
  Keyboard, Mouse,
  ImgRef, ImgRefFast,
  Maths, Timing, WasmMemMgr,
  Shapes, Panic, VGA,
  Assets;

type
  TGameStates = (
    GameStateIntro = 1,
    GameStateLoading = 2,
    GameStatePlaying = 3
  );

  TEnemyStates = (
    EnemyStateSpawning = 1,
    EnemyStateActive = 2,
    EnemyStateDespawning = 3
  );

  PEnemy = ^TEnemy;
  TEnemy = record
    alive: boolean;
    body: TPhysicsBody;
    nextScanTick: double;
    state: TEnemyStates;
    activeTick: double;  { when becoming active }
    despawnTick: double;
  end;

const
  SC_ESC = $01;
  SC_SPACE = $39;
  SC_ENTER = $1C;
  SC_W = $11;
  SC_A = $1E;
  SC_S = $1F;
  SC_D = $20;

  CornflowerBlue = $FF6495ED;
  Velocity = 90;
  EnemyVelocity = 30;

  Black = $FF000000;
  White = $FFFFFFFF;
  Red = $FFFF5555;

  PiOver2 = Pi / 2;


var
  lastEsc: boolean;

  { Game State }
  actualGameState: TGameStates;
  gameTime: double;
  playerBody: TPhysicsBody;
  isCaught, isWin: boolean;

  enemies: array[0..2] of PEnemy;


{ Use this to set `done` to true }
procedure signalDone; external 'env' name 'signalDone';
procedure hideCursor; external 'env' name 'hideCursor';
procedure hideLoadingOverlay; external 'env' name 'hideLoadingOverlay';
procedure loadAssets; external 'env' name 'loadAssets';

procedure drawFPS;
begin
  printDefault('FPS:' + i32str(getLastFPS), 240, 0);
end;

procedure drawMouse;
begin
  spr(imgCursor, mouseX, mouseY)
end;

function getAliveEnemyCount: smallint;
var
  a: word;
begin
  result := 0;

  for a:=0 to high(enemies) do
    if (enemies[a] <> nil) and enemies[a]^.alive then
      inc(result);
end;

procedure spawnEnemy(const x, y: smallint);
var
  a: word;
  enemy: PEnemy;
begin
  enemy := nil;
  for a:=0 to high(enemies) do begin
    if enemies[a] = nil then begin
      new(enemies[a]);
      enemies[a]^.alive := false;
    end;

    if not enemies[a]^.alive then begin
      enemy := enemies[a];
      break
    end;
  end;

  if enemy = nil then exit;

  enemy^.alive := true;
  enemy^.body.x := x;
  enemy^.body.y := y;
  enemy^.body.width := 8;
  enemy^.body.height := 8;
  enemy^.nextScanTick := gameTime + 0.5;

  enemy^.state := EnemyStateSpawning;
  enemy^.activeTick := gameTime + 2.0;
end;


procedure beginLoadingState;
begin
  actualGameState := GameStateLoading;
  fitCanvas;
  loadAssets
end;

procedure beginPlayingState;
var
  a: word;
begin
  hideCursor;
  fitCanvas;

  { Initialise game state here }
  actualGameState := GameStatePlaying;
  gameTime := 0.0;

  isCaught := false;
  isWin := false;

  playerBody.x := vgaWidth / 2;
  playerBody.y := vgaHeight / 2;
  playerBody.width := 8;
  playerBody.height := 8;

  RandSeed := trunc(getTimer);

  for a:=0 to high(enemies) do
    enemies[a] := nil;
end;


procedure init;
begin
  initHeapMgr;
  initDeltaTime;
  initFPSCounter
end;

procedure afterInit;
begin
  beginPlayingState
end;

procedure update;
var
  a: word;
  angle: double;
  dx, dy: double;
begin
  updateDeltaTime;
  incrementFPS;

  { Handle inputs }
  updateMouse;
{
  if lastEsc <> isKeyDown(SC_ESC) then begin
    lastEsc := isKeyDown(SC_ESC);

    if lastEsc then begin
      writeLog('ESC is pressed!');
      signalDone
    end;
  end;
}

  if not isCaught and not isWin then begin
    if isKeyDown(sc_w) then playerBody.y := playerBody.y - velocity * dt;
    if isKeyDown(SC_S) then playerBody.y := playerBody.y + velocity * dt;
    if isKeyDown(sc_a) then playerBody.x := playerBody.x - velocity * dt;
    if isKeyDown(SC_D) then playerBody.x := playerBody.x + velocity * dt;
  end;

  if getAliveEnemyCount < 3 then
    spawnEnemy(20 + random(vgaWidth - 40), 20 + random(vgaHeight - 40));

  { Update enemies }
  if not isCaught and not isWin then
    for a:=0 to high(enemies) do begin
      if not enemies[a]^.alive then continue;
      if enemies[a]^.state = EnemyStateSpawning then begin
        if gameTime >= enemies[a]^.activeTick then begin
          enemies[a]^.state := EnemyStateActive;
          enemies[a]^.despawnTick := gameTime + 5.0 + random(5);
        end;

        continue
      end;

      { Check for despawn }
      if enemies[a]^.state = EnemyStateActive then
        if gameTime >= enemies[a]^.despawnTick then begin
          enemies[a]^.alive := false;
          break
        end;

      enemies[a]^.body.x := enemies[a]^.body.x + enemies[a]^.body.vx * dt;
      enemies[a]^.body.y := enemies[a]^.body.y + enemies[a]^.body.vy * dt;

      if zoneIntersects(
        physicsBodyToZone(playerBody),
        physicsBodyToZone(enemies[a]^.body)) then begin
        isCaught := true
      end;

      if gameTime >= enemies[a]^.nextScanTick then begin
        enemies[a]^.nextScanTick := gameTime + 0.5;

        dx := playerBody.x - enemies[a]^.body.x;
        dy := playerBody.y - enemies[a]^.body.y;
        angle := ArcTan2(dy, dx) + piOver2;
        enemies[a]^.body.vx := sin(angle) * EnemyVelocity;
        enemies[a]^.body.vy := -cos(angle) * EnemyVelocity;
      end;
    end;

  if not isCaught and (gameTime >= 60.0) then
    isWin := true;

  gameTime := gameTime + dt
end;


procedure draw;
var
  a: word;
  s: string;
  w: integer;
  remainingTime: double;

begin
  if actualGameState = GameStateLoading then begin
    renderLoadingScreen;
    exit
  end;

  cls(CornflowerBlue);

  if (trunc(gameTime * 4) and 1) > 0 then
    spr(imgDosuEXE[1], vgaWidth - getImageWidth(imgDosuEXE[1]) - 10, 120)
  else
    spr(imgDosuEXE[0], vgaWidth - getImageWidth(imgDosuEXE[1]) - 10, 120);

  if isCaught then
    s := 'You are caught!'
  else if not isWin then
    s := 'Survive for 60 seconds!'
  else
    s := 'You win!';

  w := measureDefault(s);
  printDefaultCentred(s, vgaWidth div 2, 120);

  { Debug enemies }
  { for a:=0 to high(enemies) do
    if enemies[a]^.alive then
      printDefault(i32str(a), 10, 10); }

  for a:=0 to high(enemies) do begin
    if enemies[a] = nil then Continue;
    if not enemies[a]^.alive then continue;

    if enemies[a]^.state = EnemyStateSpawning then begin
      if (trunc(gameTime * 8) and 1) = 1 then
        drawZone(physicsBodyToZone(enemies[a]^.body), red)
    end else
      drawZone(physicsBodyToZone(enemies[a]^.body), red);
  end;

  drawZone(physicsBodyToZone(playerBody), white);

  remainingTime := 60.0 - gameTime;
  if remainingTime >= 0 then
    printDefaultCentred(
      toFixed(remainingTime, 1),
      vgaWidth div 2, 10);

  { if isCaught then
    printDefaultCentred('You are caught!', vgaWidth div 2, vgaHeight div 2 - 5); }

  drawMouse;
  drawFPS;

  vgaFlush
end;

exports
  beginLoadingState,
  init, afterInit, update, draw;

begin
{ Starting point is intentionally left empty }
end.


