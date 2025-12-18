//! A helper file for handling date related logic.

/// Finds the current year from std.time.timestamp
/// Assumes current year > 1970.
/// Not leap-second precise. But should be sufficient.
pub fn currentYear() usize {
    // Writing this in 2025 and am not a time traveller.
    const total_seconds: u64 = @intCast(std.time.timestamp());

    var days_until_present: u64 = total_seconds / (24 * 60 * 60);
    var present_year: usize = 1970;
    while (days_until_present >= 365) {
        if (present_year % 400 == 0 or (present_year % 4 == 0 and present_year % 100 != 0)) {
            if (days_until_present < 366) break;
            days_until_present -= 366;
        } else {
            days_until_present -= 365;
        }

        present_year += 1;
    }

    return present_year;
}

const std = @import("std");
