# Heap Memory Update

This update was pushed on `v0.1.5_experimental` using the two-tier memory manager approach

This release introduces a proper memory manager for `wasm32-embedded` target, replacing the previous first-fit bump allocator

## Why this matters?

The previous bump allocator could not free memory properly, especially when using refcounted instances like `AnsiString` or classes, so I had to rely exclusively on `ShortString` and fixed-size records. This pretty much limited what FPC features that were safe to use

## The two tiers

**Tier 1** is a fixed pool of 512 KB divided into size-class buckets (16, 32, 64, up to 512 bytes). This handles small & frequent allocations like string headers and object metadata

The term "pool" here is like a whole room of shelves, and the term "bucket" is like a shelf or a rack with slots.  Each shelf has a different slot size, which can be filled with trays.  However, if you want to call them lockers instead of shelves, they're essentially the same: the occupied/free binary nature of a slot

**Tier 2** is a free-list occupying the remaining ~1MB. This tier handles larger allocations like bitmaps using `ImgRef`. This includes forward & backward coalescing logic to prevent fragmentation

## Memory Layout

The default is 2 MB

```text
0x000000..0x02FFFF   Pascal stack   (192KB)
0x030000..0x06E7FF   Video memory   (320x200x4, depending on vgaWidth and vgaHeight)
0x06E800..0x0EE7FF   Pool region    (512KB, two-tier tier 1)
0x0EE800..0x200000   Heap region    (~1MB, two-tier tier 2)
```

You can increase the stack size in `posit-92.ts`, in case the stack leaks into the (virtual) video memory

This leak can also happen if you try to include `SysUtils` and `FGL`, so the stack size must be grown to be at least 256 KB.  But this is still *tiny* for modern computers

## Verified Working

- `AnsiString` dynamic allocation and deallocation
- String formatting with `SysUtils.format`
- BMFont loader
- Free heap at runtime: ~997 KB
