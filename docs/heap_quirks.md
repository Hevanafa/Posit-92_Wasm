# Heap Quirks

This document was made to track known quirks with the heap manager implementation at the time of writing

## About the `Classes` unit
14-08-2026

It hangs the engine, so simply don't use it as of now

## About `TFPGObjectList.Clear`
14-08-2026

In the context of this game engine (Posit-92 WASM), the method doesn't actually remove the elements from the list, but the SDL2 version actually **does**

So, the solution is to use a while-loop, something like this:
```pascal
type
  TEntityList = specialize TFPGObjectList<TEntity>;

var
  entities: TEntityList;
begin
  while entities.Count > 0 do
    entities.Delete(0);
end.
```
