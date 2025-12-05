const std = @import("std");
const tokenizeAny = std.mem.tokenizeAny;
const tokenizeSeq = std.mem.tokenizeSequence;
const tokenizeSca = std.mem.tokenizeScalar;
const splitAny = std.mem.splitAny;
const splitSeq = std.mem.splitSequence;
const splitSca = std.mem.splitScalar;
const indexOf = std.mem.indexOfScalar;
const indexOfAny = std.mem.indexOfAny;
const indexOfStr = std.mem.indexOfPosLinear;
const lastIndexOf = std.mem.lastIndexOfScalar;
const lastIndexOfAny = std.mem.lastIndexOfAny;
const lastIndexOfStr = std.mem.lastIndexOfLinear;
const trim = std.mem.trim;
const sliceMin = std.mem.min;
const sliceMax = std.mem.max;
const parseInt = std.fmt.parseInt;
const parseFloat = std.fmt.parseFloat;
const print = std.debug.print;
const assert = std.debug.assert;
const sort = std.sort.block;
const asc = std.sort.asc;
const desc = std.sort.desc;

pub fn part1(input: []const u8) [:0]const u8 {
    var sum: i32 = 50;
    var count: i16 = 0;

    var lines = tokenizeSca(u8, input, '\n');
    while (lines.next()) |line| {
        const amo = parseInt(u16, line[1..], 10) catch unreachable;

        if (line[0] == 'L') {
            sum -= amo;
        } else {
            sum += amo;
        }

        if (@mod(@abs(sum), 100) == 0 and amo != 0) {
            count += 1;
        }
    }

    print("Part 1 result (positive): {d}\n", .{count});
    return intToStr(count);
}

pub fn part2(input: []const u8) [:0]const u8 {
    var sum: i32 = 50;
    var prev_sum: i32 = 50;
    var count: i16 = 0;

    var lines = tokenizeSca(u8, input, '\n');
    while (lines.next()) |line| {
        var amo = parseInt(u16, line[1..], 10) catch unreachable;

        // Removing already foreseeable zero crossings
        const revolutions = @divFloor(amo, 100);

        if (revolutions > 0) {
            count += @intCast(revolutions);
            amo = @intCast(@mod(amo, 100));
        }

        if (line[0] == 'L') {
            sum -= amo;
        } else {
            sum += amo;
        }

        print("Line: {s}, Sum: {d}, Prev Sum: {d}, count: {d}\n", .{ line, sum, prev_sum, count });

        // Now checking zero crossing in between the case where the sum is between 0 - 99, and the amount added will be also between 0 - 99
        // This can happen from both sides of the number line - negative and positive
        // For this, we first check, whether we ended on zero (while the sums between runs being different, as that might lead to a double-count)
        // Then we check, whether there is a difference in amounts of 100's between both runs, so we can add that to the count
        // And lastly we check for crossings at the zero-number line, as that is not being covered by the other logic 
        if (@mod(@abs(sum), 100) == 0 and sum != prev_sum) {
            count += 1;
        } else if (@divFloor(@abs(sum), 100) != @divFloor(@abs(prev_sum), 100)) {
            count += @intCast(@abs(@divFloor(sum, 100) - @divFloor(prev_sum, 100)));
        } else if ((sum ^ prev_sum) < 0 and prev_sum != 0) {
            count += 1;
        }

        // Another normalization step to remove 100's out of the calculation
        const sign: i32 = if (sum < 0) -1 else 1;
        sum = sign * @as(i32, @intCast(@mod(@abs(sum), 100)));
        prev_sum = sum;
    }

    print("Part 2 result (positive): {d}\n", .{count});
    return intToStr(count);
}

// Useful stdlib functions
fn intToStr(sum: anytype) [:0]const u8 {
    var buf: [20]u8 = undefined;
    return std.fmt.bufPrintZ(&buf, "{d}", .{sum}) catch unreachable;
}
