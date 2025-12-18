//! Useful definitions for uniquely identifying aoc problems
//! And provides an interface for solutions.

// A more detailed error system is probably unecessary
const ParseError = error{
    InvalidFormat,
};

pub const Problem = struct {
    year: usize,
    day: usize,

    pub fn format(problem: Problem, w: *std.Io.Writer) std.Io.Writer.Error!void {
        try w.print("{d}/{d}", .{ problem.day, problem.year });
    }

    /// Check if a pair of year and day is a valid Problem.
    pub fn canExist(problem: Problem) bool {
        // The first Advent Of Code was held in 2015.
        if (problem.year < 2015) return false;
        // The first day in December is the first. (not zero)
        if (problem.day == 0) return false;
        // From 2015-2024 there was one problem (2 parts each) for each year.
        if (problem.year < 2025 and problem.day > 25) return false;
        // From 2025-???? there has only been 12 problems each year.
        if (problem.year >= 2025 and problem.day > 12) return false;
        // You're not a time traveller.
        if (problem.year > date.currentYear()) return false;
        return true;
    }

    /// Given a string formatted like {dd}/{yyyy}
    /// Determines the problem year and day.
    pub fn parse(str: []const u8) ParseError!Problem {
        var it = std.mem.splitScalar(u8, str, '/');

        const lhs = it.next() orelse return error.InvalidFormat;
        const rhs = it.next() orelse return error.InvalidFormat;

        const day: usize = std.fmt.parseInt(usize, lhs, 10) catch return error.InvalidFormat;
        const year: usize = std.fmt.parseInt(usize, rhs, 10) catch return error.InvalidFormat;

        return .{ .day = day, .year = year };
    }

    /// Given a path formatted like {yyyy}/day{dd}.zig
    /// Determines the problem year and day.
    pub fn fromFilePath(path: []const u8) ParseError!Problem {
        const path_no_suffix = try expectSuffix(path, ".zig");
        var it = std.mem.splitSequence(u8, path_no_suffix, "/day");
        const lhs = it.next() orelse return error.InvalidFormat;
        const rhs = it.next() orelse return error.InvalidFormat;

        const year: usize = std.fmt.parseInt(usize, lhs, 10) catch return error.InvalidFormat;
        const day: usize = std.fmt.parseInt(usize, rhs, 10) catch return error.InvalidFormat;

        return .{ .day = day, .year = year };
    }
};

/// If `str` ends with `suffix` returns the str with suffix chopped off from the end.
/// Otherwise an error is returned.
pub fn expectSuffix(str: []const u8, suffix: []const u8) ParseError![]const u8 {
    if (!std.mem.endsWith(u8, str, suffix))
        return error.InvalidFormat;
    return str[0 .. str.len - suffix.len];
}

/// AOC solution interface.
/// Have decided against parsing into a context
/// Because it requires some more bindings magic than I can be bothered with.
pub const Solution = struct {
    problem: Problem,

    part_one_fn: ?*const fn (gpa: Allocator, src: []const u8) anyerror!usize,
    part_two_fn: ?*const fn (gpa: Allocator, src: []const u8) anyerror!usize,

    // Automatically generate interface from a concrete solution.
    pub fn generateBindings(problem: Problem, s: type) Solution {
        const part_one_fn = if (@hasDecl(s, "part_one")) s.part_one else null;
        const part_two_fn = if (@hasDecl(s, "part_two")) s.part_two else null;

        return .{
            .problem = problem,
            .part_one_fn = part_one_fn,
            .part_two_fn = part_two_fn,
        };
    }

    pub inline fn part_one(self: Solution, gpa: Allocator, src: []const u8) !usize {
        if (self.part_one_fn) |part_one_fn|
            return part_one_fn(gpa, src);
        return error.NotImplemented;
    }

    pub inline fn part_two(self: Solution, gpa: Allocator, src: []const u8) !usize {
        if (self.part_two_fn) |part_two_fn|
            return part_two_fn(gpa, src);
        return error.NotImplemented;
    }
};

const date = @import("date.zig");

const std = @import("std");
const Allocator = std.mem.Allocator;
