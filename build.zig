const aoc = @import("tools/aoc.zig");
const custom_step = @import("tools/step.zig");
const std = @import("std");

const Build = std.Build;
const Step = Build.Step;

pub fn build(b: *Build) void {
    const template_options = custom_step.aocOption(b);

    var top_template_step = b.step("template", "Generates template files");
    if (template_options) |options| {
        const template_step: *custom_step.Template = .create(b, options);
        top_template_step.dependOn(&template_step.step);
    } else {
        top_template_step.makeFn = unavailable("step 'template' requires options -Dyear=... and -Dday=... to be set", .{});
    }

    const emit_solutions: *custom_step.EmitSolutions = .create(b);

    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const tools = b.addModule("tools", .{
        .root_source_file = b.path("tools/root.zig"),
        .optimize = optimize,
        .target = target,
    });

    const exe = b.addExecutable(.{
        .name = "AocRunner",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    exe.root_module.addImport("tools", tools);

    b.installArtifact(exe);
    exe.step.dependOn(&emit_solutions.step);

    const clap = b.dependency("clap", .{});
    exe.root_module.addImport("clap", clap.module("clap"));

    const run_exe = b.addRunArtifact(exe);
    if (b.args) |args| {
        run_exe.addArgs(args);
    }
    const run_step = b.step("run", "Run the aoc runner");
    run_step.dependOn(&run_exe.step);

    const install_docs = b.addInstallDirectory(.{
        .source_dir = exe.getEmittedDocs(),
        .install_dir = .prefix,
        .install_subdir = "docs",
    });

    const docs_step = b.step("docs", "Install docs into zig-out/docs");
    docs_step.dependOn(&install_docs.step);
}

pub fn unavailable(comptime fmt: []const u8, args: anytype) fn (*Step, Step.MakeOptions) anyerror!void {
    return struct {
        pub fn inner(_: *Step, _: Step.MakeOptions) anyerror!void {
            std.log.err(fmt, args);
            return error.Unavailable;
        }
    }.inner;
}
