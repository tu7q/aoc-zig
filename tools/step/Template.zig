//! Describes how the template step works.

const Template = @This();

step: Build.Step,

year: usize,
day: usize,

pub fn create(b: *Build, options: aoc.Problem) *Template {
    const self = b.allocator.create(Template) catch @panic("OOM");
    self.* = .{
        .step = .init(.{
            .id = .custom,
            .name = "template",
            .owner = b,
            .makeFn = make,
        }),
        .year = options.year,
        .day = options.day,
    };
    return self;
}

fn make(step: *Build.Step, _: Build.Step.MakeOptions) anyerror!void {
    const self: *Template = @fieldParentPtr("step", step);

    const b = step.owner;
    const gpa = b.allocator;

    const dir_path = std.fmt.allocPrint(gpa, "src/{d}", .{self.year}) catch @panic("OOM");
    const filename = std.fmt.allocPrint(gpa, "day{d:02}.zig", .{self.day}) catch @panic("OOM");

    const root = b.build_root.handle;
    const dir = try root.makeOpenPath(dir_path, .{});

    const file = dir.createFile(filename, .{
        .exclusive = true,
    }) catch return error.FailedToCreateTemplate;

    var file_writer = file.writer(&.{});
    const writer = &file_writer.interface;

    try self.writeContent(writer);
}

pub fn writeContent(self: *Template, writer: *std.Io.Writer) !void {
    _ = self;

    try writer.writeAll(
        \\pub fn part_one(gpa: Allocator, src: []const u8) !usize {
        \\    _ = gpa;
        \\    _ = src;
        \\    return error.NotImplemented;
        \\}
        \\
        \\pub fn part_two(gpa: Allocator, src: []const u8) !usize {
        \\    _ = gpa;
        \\    _ = src;
        \\    return error.NotImplemented;  
        \\}
        \\
        \\const std = @import("std");
        \\const Allocator = std.mem.Allocator;
        \\
        \\test {
        \\    const al = std.testing.allocator;
        \\    const src: []const u8 = 
        \\        \\
        \\    ;
        \\    try std.testing.expectError(error.NotImplemented, part_one(al, src));
        \\    try std.testing.expectError(error.NotImplemented, part_two(al, src));
        \\}
    );
}

const aoc = @import("../aoc.zig");
const std = @import("std");
const Build = std.Build;
