pub const Template = @import("step/Template.zig");
pub const EmitSolutions = @import("step/EmitSolutions.zig");

pub fn aocOption(b: *Build) ?aoc.Problem {
    const m_year = b.option(usize, "year", "advent of code year for template");
    const m_day = b.option(usize, "day", "advent of code day for template");

    if (m_year == null and m_day == null) return null;
    if ((m_year != null) != (m_day != null)) {
        if (m_year) |year|
            std.log.err("year: {d} specified, must also specify day.", .{year});
        if (m_day) |day|
            std.log.err("day: {d} specified, must also specify day.", .{day});
        b.invalid_user_input = true;
        return null;
    }

    return .{
        .day = m_day.?,
        .year = m_year.?,
    };
}

const aoc = @import("aoc.zig");
const std = @import("std");
const Build = std.Build;
