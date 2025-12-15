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
    var res: u64 = 0;

    var lines = tokenizeSca(u8, input, ',');
    while (lines.next()) |line| {
        const dash_index = indexOf(u8, line, '-') orelse continue;
        const start_str = line[0..dash_index];
        const end_str = line[dash_index + 1 ..];

        const start = parseInt(u64, start_str, 10) catch unreachable;
        const end = parseInt(u64, end_str, 10) catch unreachable;

        // first half
        const first_half = get_half(start);

        // second-half
        var sec_half = get_half(end);

        // Multiply second half by 10, if first half is smaller
        if (first_half > sec_half) {
            sec_half *= 10;
        }

        // We are starting with the lower boundary
        const initial_remaining_len = start_str.len - (start_str.len / 2);

        print("Line: {s}\n", .{line});
        print("  start: {d}, end: {d}\n", .{ start, end });
        print("  first_half: {d}, sec_half: {d}\n", .{ first_half, sec_half });
        print("  initial_remaining_len: {d}\n", .{initial_remaining_len});

        for (first_half..sec_half + 1) |i| {
            const curr_num_comb_len = getIntLength(i) + @as(u16, @intCast(initial_remaining_len));

            if (curr_num_comb_len % 2 == 0) {
                // even
                const mirrorNum = composeMirrorNumEven(i);

                if (i == first_half and mirrorNum < start or i == sec_half and mirrorNum > end) {
                    continue;
                }

                res += composeMirrorNumEven(i);
            }
            // else {
            //     // odd
            //     const midNum_s = start_str[start_str.len / 2] - '0';
            //     const midNum_e = end_str[end_str.len / 2] - '0';
            //     const start_ind = if (i == first_half) midNum_s else 0;
            //     const end_ind = if (i == sec_half) midNum_e else 10;

            //     print("  curr_num_comb_len: {d}\n", .{curr_num_comb_len});
            //     print("  midNum_s: {d}, midNum_e: {d}\n", .{ midNum_s, midNum_e });
            //     print("  start_ind: {d}, end_ind: {d}\n", .{ start_ind, end_ind });

            //     for (start_ind..end_ind + 1) |x| {
            //         const compNum = composeMirrorNumOdd(i, x);

            //         if (compNum <= end and compNum >= start) {
            //             res += compNum;
            //         }
            //     }
            // }
        }
    }

    print("Part 1 result: {d}\n", .{res});
    return intToStr(res);
}

pub fn part2(input: []const u8) [:0]const u8 {
    var res: u64 = 0;

    var lines = tokenizeSca(u8, input, ',');
    while (lines.next()) |line| {
        const dash_index = indexOf(u8, line, '-') orelse continue;
        const start_str = line[0..dash_index];
        const end_str = line[dash_index + 1 ..];

        const start = parseInt(u64, start_str, 10) catch unreachable;
        const end = parseInt(u64, end_str, 10) catch unreachable;

        const startLen = start_str.len;
        const endLen = end_str.len;

        // Iterate over each possible total digit length
        for (startLen..endLen + 1) |totalLen| {

            // Get all valid pattern lengths (divisors of totalLen that are <= totalLen/2)
            var pattern_buf: [32]u16 = undefined;
            const patternLengths = calcPatternLengths(totalLen, &pattern_buf);

            for (patternLengths) |patternLen| {
                const pLen: usize = @intCast(patternLen);
                const repetitions = totalLen / pLen;

                const multiplier = calcMultiplier(pLen, repetitions);

                // Base number bounds (to avoid leading zeros)
                // Minimum: 10^(pLen-1) for pLen > 1, else 1
                // Maximum: 10^pLen - 1
                const baseMin = if (pLen == 1) 1 else pow10(pLen - 1);
                const baseMax = pow10(pLen) - 1;

                for (baseMin..baseMax + 1) |base| {
                    const composedNum = base * multiplier;

                    // TODO: Add your boundary check logic here
                    // Hint: When should you skip this composedNum?
                    if (composedNum >= start and composedNum <= end and !hasSmallerPattern(base, pLen)) {
                        res += composedNum;
                    }
                }
            }
        }
    }

    print("Part 2 result: {d}\n", .{res});
    return intToStr(res);
}

fn hasSmallerPattern(base: usize, pLen: usize) bool {
    for (1..pLen) |x| {
        if (pLen % x == 0) {
            const smallerMult = calcMultiplier(x, pLen / x);

            if (base % smallerMult == 0) {
                return true;
            }
        }
    }

    return false;
}

// Returns valid pattern lengths (divisors of totalLen, from 1 to totalLen/2)
fn calcPatternLengths(totalLen: usize, result_buf: []u16) []u16 {
    var count: usize = 0;

    for (1..totalLen / 2 + 1) |x| {
        if (totalLen % x == 0) {
            result_buf[count] = @intCast(x);
            count += 1;
        }
    }

    return result_buf[0..count];
}

// For pattern length d repeated n times: 1 + 10^d + 10^(2d) + ... + 10^((n-1)*d)
// Formula: (10^(d*n) - 1) / (10^d - 1)
fn calcMultiplier(patternLen: usize, repetitions: usize) u64 {
    var mult: u64 = 0;
    var power: u64 = 1;

    for (0..repetitions) |_| {
        mult += power;
        power *= pow10(patternLen);
    }

    return mult;
}

// Helper: compute 10^exp
fn pow10(exp: usize) u64 {
    var result: u64 = 1;
    for (0..exp) |_| {
        result *= 10;
    }
    return result;
}

fn composeMirrorNumOdd(i: usize, x: usize) u64 {
    var buf: [50]u8 = undefined;
    const composed_str = std.fmt.bufPrint(&buf, "{d}{d}{d}", .{ i, x, i }) catch unreachable;
    return parseInt(u64, composed_str, 10) catch unreachable;
}

fn composeMirrorNumEven(i: usize) u64 {
    var buf: [50]u8 = undefined;
    const composed_str = std.fmt.bufPrint(&buf, "{d}{d}", .{ i, i }) catch unreachable;
    return parseInt(u64, composed_str, 10) catch unreachable;
}

pub fn getIntLength(input: usize) u16 {
    var buf: [20]u8 = undefined;
    const str = std.fmt.bufPrint(&buf, "{d}", .{input}) catch unreachable;
    return @intCast(str.len);
}

pub fn get_half(input: u64) u64 {
    var buf: [20]u8 = undefined;
    const str = std.fmt.bufPrint(&buf, "{d}", .{input}) catch unreachable;
    if (str.len == 1) {
        return 1;
    }
    const half_len = str.len / 2;
    const first_half_str = str[0..half_len];
    return parseInt(u64, first_half_str, 10) catch unreachable;
}

// pub fn part2(input: []const u8) [:0]const u8 {
//     _ = input; // autofix
//     // var res: i16 = 0;

//     // var lines = tokenizeSca(u8, input, '\n');
//     // while (lines.next()) |line| {

//     // }

//     // print("Part 1 result: {d}\n", .{res});
//     // return intToStr(res);
// }

// Useful stdlib functions
fn intToStr(sum: anytype) [:0]const u8 {
    var buf: [20]u8 = undefined;
    return std.fmt.bufPrintZ(&buf, "{d}", .{sum}) catch unreachable;
}
