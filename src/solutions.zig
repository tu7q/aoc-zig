pub const all: []const AocSolution = &.{
	.generateBindings(AocProblem.fromFilePath("2015/day01.zig") catch unreachable, @import("2015/day01.zig")),
	.generateBindings(AocProblem.fromFilePath("2015/day02.zig") catch unreachable, @import("2015/day02.zig")),
	.generateBindings(AocProblem.fromFilePath("2015/day12.zig") catch unreachable, @import("2015/day12.zig")),
	.generateBindings(AocProblem.fromFilePath("2025/day12.zig") catch unreachable, @import("2025/day12.zig")),
};
const aoc = @import("tools").aoc;
const AocSolution = aoc.Solution;
const AocProblem = aoc.Problem;