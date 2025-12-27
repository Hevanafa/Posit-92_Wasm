library Game;

{$Mode ObjFPC}

uses
  SysUtils, FGL,
  Conv, FPS, Loading, Logger,
  Keyboard, Mouse,
  ImgRef, ImgRefFast,
  PostProc, Timing, WasmMemMgr, VGA,
  Assets;

const
  SC_ESC = $01;
  SC_SPACE = $39;

type
  TEnemy = class
    active: boolean;
    x, y: smallint;
    health: smallint;
    enemyType: smallint;
  end;
  TEnemyList = specialize TFPGObjectList<TEnemy>;

var
  lastEsc: boolean;

  { Init your game state here }
  gameTime: double;
  enemies: TEnemyList;

{ Use this to set `done` to true }
procedure signalDone; external 'env' name 'signalDone';

procedure drawFPS;
begin
  printDefault('FPS:' + i32str(getLastFPS), 240, 0);
end;

procedure drawMouse;
begin
  spr(imgCursor, mouseX, mouseY)
end;


procedure init;
begin
  initMemMgr;
  initBuffer;
  initDeltaTime;
  initFPSCounter;
end;

procedure afterInit;
var
  a: word;
  enemy: TEnemy;
begin
  hideCursor;

  { Initialise game state here }
  gameTime := 0.0;

  writeLog('afterInit after gameTime');
  
  enemies := TEnemyList.create;
  enemies.FreeObjects := true;

  for a:=0 to 9 do begin
    enemy := TEnemy.create;

    enemy.active := true;
    enemy.x := random(vgaWidth - 50);
    enemy.y := random(vgaHeight - 50);
    enemy.health := 100;
    enemy.enemyType := 1;

    enemies.add(enemy)
  end;

  { Remove 1 enemy for an example }
  enemies[1].free;
  enemies.delete(1);

  writeLog('enemies[0]');
  writeLogI32(enemies[0].x);
  writeLogI32(enemies[0].y);
  writeLogI32(enemies[0].health);
  writeLogI32(enemies[0].enemyType);

  writeLog('afterInit end');
end;

procedure update;
begin
  updateDeltaTime;
  incrementFPS;

  updateMouse;

  { Your update logic here }
  if lastEsc <> isKeyDown(SC_ESC) then begin
    lastEsc := isKeyDown(SC_ESC);

    if lastEsc then begin
      writeLog('ESC is pressed!');
      signalDone
    end;
  end;

  gameTime := gameTime + dt
end;

procedure draw;
var
  a: integer;
  s: string;
  w: word;
begin
  cls($FF6495ED);

  for a:=0 to enemies.count-1 do
    spr(imgDosuEXE[0], enemies[a].x, enemies[a].y);

  s := 'Hello world!';
  w := measureDefault(s);
  printDefault(s, (vgaWidth - w) div 2, 120);

  drawMouse;
  drawFPS;

  vgaFlush
end;

exports
  { Main game procedures }
  init,
  afterInit,
  update,
  draw;

begin
{ Starting point is intentionally left empty }
end.

