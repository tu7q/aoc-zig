//! Main runner for Advent of Code
//! Responsible for determining which solution needs to run,
//! and fetching inputs from a local cache or the website.

pub fn main() !void {
    var da_impl: std.heap.DebugAllocator(.{}) = .init;
    defer _ = da_impl.deinit();
    const gpa = da_impl.allocator();

    const params = comptime clap.parseParamsComptime(
        \\-h, --help Display this help and quit
        \\-s, --src <str> Custom input source location
        \\-1 Enable part one
        \\-2 Enable part two
        \\<problem>
    );

    const parsers = comptime .{
        .str = clap.parsers.string,
        .usize = clap.parsers.int(usize, 0),
        .problem = aoc.Problem.parse,
    };

    var diag = clap.Diagnostic{};
    var res = clap.parse(clap.Help, &params, parsers, .{
        .diagnostic = &diag,
        .allocator = gpa,
    }) catch |err| {
        try diag.reportToFile(.stderr(), err);
        return err;
    };
    defer res.deinit();

    if (res.args.help != 0) {
        return clap.helpToFile(.stderr(), clap.Help, &params, .{});
    }

    const problem = res.positionals[0] orelse return;
    if (!problem.canExist()) {
        return std.log.err("problem {f} does not exist.", .{problem});
    }

    const solution = for (solutions.all) |solution| {
        if (solution.problem.day == problem.day and
            solution.problem.year == problem.year)
        {
            break solution;
        }
    } else return std.log.err("solution for problem {f} does not exist", .{problem});

    if (res.args.src) |filename| {
        std.debug.print("{s}\n", .{filename});
    }

    const input =
        if (res.args.src) |path|
            allocReadFilePath(gpa, path) catch |err|
                return std.log.err("Failed to read file: '{s}', {any}", .{ path, err })
        else
            fetchCacheInput(gpa, problem) catch |err|
                return std.log.err("Failed to fetch input: {any}", .{err});
    defer gpa.free(input);

    const parts: struct { bool, bool } = blk: {
        var parts: struct { bool, bool } = .{ false, false };
        if (res.args.@"1" != 0)
            parts[0] = true;
        if (res.args.@"2" != 0)
            parts[1] = true;
        if (!parts.@"0" and !parts.@"1")
            parts = .{ true, true };
        break :blk parts;
    };

    if (parts.@"0") {
        std.debug.print("part one result: {d}\n", .{
            try solution.part_one(gpa, input),
        });
    }

    if (parts.@"1") {
        std.debug.print("part two result: {d}\n", .{
            try solution.part_two(gpa, input),
        });
    }
}

pub fn allocReadFilePath(gpa: Allocator, path: []const u8) ![]const u8 {
    return std.fs.cwd().readFileAlloc(gpa, path, std.math.maxInt(usize));
}

pub fn writeFilePath(path: []const u8, bytes: []const u8) !void {
    const cwd = std.fs.cwd();
    if (std.fs.path.dirname(path)) |dir_path| {
        _ = cwd.makePath(dir_path) catch {};
    }

    const file = try cwd.createFile(path, .{ .exclusive = true });
    try file.writeAll(bytes);
}

pub fn fetchCacheInput(gpa: Allocator, problem: aoc.Problem) ![]const u8 {
    const filepath = try std.fmt.allocPrint(
        gpa,
        "input/{d}/day{d:02}.txt",
        .{ problem.year, problem.day },
    );
    defer gpa.free(filepath);

    if (allocReadFilePath(gpa, filepath)) |cached|
        return cached
    else |_| {}

    // Get the session token.
    const aoc_session_token = try std.process.getEnvVarOwned(gpa, "AOC_SESSION_TOKEN");
    defer gpa.free(aoc_session_token);

    const input = try fetchAocInput(gpa, problem, aoc_session_token);

    // Attempt to cache the input
    writeFilePath(filepath, input) catch {};

    return input;
}

pub fn fetchAocInput(gpa: Allocator, problem: aoc.Problem, aoc_session_token: []const u8) ![]const u8 {
    var http_client: std.http.Client = .{ .allocator = gpa };
    defer http_client.deinit();

    var response: std.Io.Writer.Allocating = .init(gpa);
    errdefer response.deinit();

    const url = try std.fmt.allocPrint(
        gpa,
        "https://adventofcode.com/{d}/day/{d}/input",
        .{ problem.year, problem.day },
    );
    defer gpa.free(url);

    const cookie = try std.fmt.allocPrint(gpa, "session={s}", .{aoc_session_token});
    defer gpa.free(cookie);

    const res = try http_client.fetch(.{
        .location = .{ .url = url },
        .method = .GET,
        .extra_headers = &.{.{
            .name = "Cookie",
            .value = cookie,
        }},
        .response_writer = &response.writer,
    });

    if (res.status != .ok) return error.FetchFailed;

    return try response.toOwnedSlice();
}

const aoc = @import("tools").aoc;
const solutions = @import("solutions.zig");
const clap = @import("clap");
const std = @import("std");
const fs = std.fs;
const Allocator = std.mem.Allocator;
