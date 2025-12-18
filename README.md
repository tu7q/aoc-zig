# aoc.zig

Solutions for advent of code written in zig.

## Tools
Tools that can be invoked manually or are used during build.

### Main Runner
Ability to run a particular solution. Automatic download and caching of needed input.
```sh
zig build run -- <day>/<year>
```
Ability to provide custom input via `-s` or `--src`
```sh
zig build run -- <day>/<year> -s=/path/to/input
```
Ability to set which solution runs via the `-1` and `-2` flags
```sh
zig build run -- <day>/<year> -2 
```

### Templating
Ability to generate file from template.
```
zig build template -Dyear=<year> -Dday=<day>
```

### Import Generation
Automatically emits `src/solutions.zig` with updated solutions list.


## TODOS:
1. Multiple input validation on problems
2. Simple timing mechanism (/flag)
3. Visualization
4. Improved solution interface
5. Setting user-email for convenience of adventofcode.com admins
6. Code de-clutter
