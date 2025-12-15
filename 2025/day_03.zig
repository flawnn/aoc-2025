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
    var sum: i32 = 0;

    var lines = tokenizeSca(u8, input, '\n');

    while (lines.next()) |line| {
        const firstDigit = findLargestDigit(line[0 .. line.len - 1]);
        const secondDigit = findLargestDigit(line[firstDigit.index + 1 .. line.len]);
        print("Line: {s}, First: {d} (index: {d}), Second: {d} (index: {d})\n", .{ line, firstDigit.digit, firstDigit.index, secondDigit.digit, secondDigit.index });

        sum += firstDigit.digit * 10 + secondDigit.digit;
    }

    print("Part 1 result: {d}\n", .{sum});
    return intToStr(sum);
}

pub fn part2(input: []const u8) [:0]const u8 {
    var sum: u64 = 0;
    const len: u8 = 12;

    var lines = tokenizeSca(u8, input, '\n');

    while (lines.next()) |line| {
        var digits: [len]u8 = undefined;
        var start_ind: usize = 0;

        for (0..len) |i| {
            const r = len - 1 - i; // Convert to descending

            const highestDig = findLargestDigit(line[start_ind .. line.len - r]);

            print("Line: {s}, Highest: {d} (index: {d}), r: {d}\n", .{ line, highestDig.digit,start_ind + highestDig.index, r });

            start_ind = start_ind + highestDig.index + 1;
            digits[i] = highestDig.digit;
        }

        var num: u64 = 0;
        for (digits) |digit| {
            num = num * 10 + digit;
        }
        sum += num;
    }

    print("Part 1 result: {d}\n", .{sum});
    return intToStr(sum);
}

pub fn findLargestDigit(input: []const u8) struct { digit: u8, index: usize } {
    var largestDigit: u8 = 0;
    var largestIndex: usize = 0;

    for (input[0..input.len], 0..) |char, i| {
        const digit: u8 = char - '0';

        if (digit > largestDigit) {
            largestDigit = digit;
            largestIndex = i;
        }

        if (largestDigit == '9') {
            return .{ .digit = largestDigit, .index = largestIndex };
        }
    }

    return .{ .digit = largestDigit, .index = largestIndex };
}

// Useful stdlib functions
fn intToStr(sum: anytype) [:0]const u8 {
    var buf: [20]u8 = undefined;
    return std.fmt.bufPrintZ(&buf, "{d}", .{sum}) catch unreachable;
}
