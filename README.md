# Advent of Code 2024 (in Zig)

Zig version 0.13.0 is used and in order to run a problem,
go to the specific day's dir and run one of the following:

```
# debug version
zig build problem1 -- <path to input>
zig build problem2 -- <path to input>

# release version
zig build problem1 -Doptimize=ReleaseFast -- <path to input>
zig build problem2 -Doptimize=ReleaseFast -- <path to input>
```
