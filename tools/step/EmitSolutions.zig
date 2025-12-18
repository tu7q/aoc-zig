//! Build step for creating solution imports.

const EmitSolutions = @This();

step: Build.Step,

pub fn create(b: *Build) *EmitSolutions {
    const self = b.allocator.create(EmitSolutions) catch @panic("OOM");
    self.* = .{
        .step = .init(.{
            .id = .custom,
            .name = "generate imports",
            .owner = b,
            .makeFn = make,
        }),
    };

    return self;
}
fn make(step: *Build.Step, _: Build.Step.MakeOptions) anyerror!void {
    const self: *EmitSolutions = @fieldParentPtr("step", step);
    const b = step.owner;

    const root_dir = b.build_root.handle;
    const src_dir = try root_dir.openDir("src", .{});

    const imports_file = try src_dir.createFile("solutions.zig", .{});
    var fwriter = imports_file.writer(&.{});
    const writer = &fwriter.interface;

    try self.write_imports(writer);
}

fn write_imports(self: *EmitSolutions, writer: *std.Io.Writer) !void {
    const b = self.step.owner;

    const root_dir = b.build_root.handle;
    const src_dir = try root_dir.openDir("src", .{ .iterate = true });

    try writer.print("pub const all: []const AocSolution = &.{{\n", .{});

    var src_it = src_dir.iterate();
    while (try src_it.next()) |src_entry| {
        if (src_entry.kind != .directory) continue;

        const year_dir = try src_dir.openDir(src_entry.name, .{ .iterate = true });
        var year_it = year_dir.iterate();

        while (try year_it.next()) |year_entry| {
            if (year_entry.kind != .file) continue;

            if (!std.mem.startsWith(u8, year_entry.name, "day")) continue;
            if (!std.mem.endsWith(u8, year_entry.name, ".zig")) continue;

            try writer.print(
                "\t.generateBindings(AocProblem.fromFilePath(\"{s}/{s}\") catch unreachable, @import(\"{s}/{s}\")),\n",
                .{
                    src_entry.name,
                    year_entry.name,
                    src_entry.name,
                    year_entry.name,
                },
            );
        }
    }

    try writer.print(
        \\}};
        \\const aoc = @import("tools").aoc;
        \\const AocSolution = aoc.Solution;
        \\const AocProblem = aoc.Problem;
        \\
    , .{});
}

const std = @import("std");
const Build = std.Build;
