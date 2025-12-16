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

const Range = struct { start: u64, end: u64 };

pub fn part1(input: []const u8) ![:0]const u8 {
    // Split into two sections
    var sections = splitSeq(u8, input, "\n\n");
    const ranges_section = sections.next() orelse return error.InvalidInput;
    const numbers_section = sections.next() orelse return error.InvalidInput;

    // Set up new range array
    const allocator = std.heap.page_allocator;
    var rangesList = std.array_list.Managed(Range).init(allocator);
    defer {
        rangesList.deinit();
    }

    // Parse ranges section
    var ranges_lines = tokenizeSca(u8, ranges_section, '\n');
    while (ranges_lines.next()) |line| {
        var parts = splitSca(u8, line, '-');
        const start = try parseInt(u64, parts.next().?, 10);
        const end = try parseInt(u64, parts.next().?, 10);

        try rangesList.append(.{ .end = end, .start = start });
    }
    var amo_in_range: u64 = 0;
    // Parse numbers section
    var numbers_lines = tokenizeSca(u8, numbers_section, '\n');
    while (numbers_lines.next()) |number_line| {
        const num = try parseInt(u64, number_line, 10);

        // Check if in any range
        for (rangesList.items) |range| {
            if (num >= range.start and num <= range.end) {
                amo_in_range += 1;

                break;
            }
        }
    }

    print("Part 1 result: {d}\n", .{amo_in_range});
    return intToStr(amo_in_range);
}

pub fn part2(input: []const u8) ![:0]const u8 {
    // Results
    var rangeLength: u64 = 0;

    // Split into two sections
    var sections = splitSeq(u8, input, "\n\n");
    const ranges_section = sections.next() orelse return error.InvalidInput;

    // Set up new range array
    const allocator = std.heap.page_allocator;
    var rangesList = std.array_list.Managed(Range).init(allocator);
    defer {
        rangesList.deinit();
    }

    // Parse ranges section
    var ranges_lines = tokenizeSca(u8, ranges_section, '\n');

    // Already keep track of lowest ind
    var lowestInd: ?struct { val: u64, ind: u16 } = null;
    var highestInd: ?struct { val: u64, ind: u16 } = null;

    while (ranges_lines.next()) |line| {
        var parts = splitSca(u8, line, '-');
        const start = try parseInt(u64, parts.next().?, 10);
        const end = try parseInt(u64, parts.next().?, 10);

        if (lowestInd == null or start < lowestInd.?.val) {
            lowestInd = .{ .ind = @intCast(rangesList.items.len), .val = start };
        } else if (highestInd == null or end > highestInd.?.val) {
            highestInd = .{ .ind = @intCast(rangesList.items.len), .val = end };
        }

        try rangesList.append(.{ .end = end, .start = start });
    }

    // Keep a copy of the ranges to gradually decrease search radius
    var rangesListRemaining = std.array_list.Managed(Range).init(allocator);
    defer rangesListRemaining.deinit();
    try rangesListRemaining.appendSlice(rangesList.items);
    // Remove first starting range already
    _ = rangesListRemaining.swapRemove(lowestInd.?.ind);

    var curr_range = rangesList.items[lowestInd.?.ind];
    // Traverse through ranges

    traverse: while (true) {
        // std.debug.print("Current rangeLength: {}\n", .{rangeLength});
        for (rangesListRemaining.items, 0..) |range, i| {
            // Ranges are overlapping, with the new range having a higher "end" value
            if (range.start <= curr_range.end and curr_range.end < range.end) {
                // std.debug.print("Extending range: curr_range.start={} curr_range.end={}, range.start={}, range.end={}\n", .{ curr_range.start, curr_range.end, range.start, range.end });

                curr_range = .{ .start = if (range.start > curr_range.start) curr_range.start else range.start, .end = range.end };

                _ = rangesListRemaining.swapRemove(i);

                continue :traverse;
            }
            // If we have a range, that is not extending our chain of ranges, remove.
            else if (range.start <= curr_range.end and curr_range.end >= range.end) {
                // std.debug.print("Range fully contained: curr_range.end={}, range.start={}, range.end={}\n", .{ curr_range.end, range.start, range.end });
                _ = rangesListRemaining.swapRemove(i);
                continue :traverse;
            }
        }

        // Add range length to our total collected range, as we are either at the max, or finding a new non-adjacent range
        rangeLength += curr_range.end + 1 - curr_range.start;

        // If we reached the highest value of all ranges, end!
        if (curr_range.end == highestInd.?.val) {
            break;
        }

        // Find the next-highest value in all remaining ranges
        var closestNextRange: ?struct { diff: u64, ind: u16 } = null;

        for (rangesListRemaining.items, 0..) |range, i| {
            const diff: u64 = range.start - curr_range.end;

            if (closestNextRange == null or diff < closestNextRange.?.diff) {
                closestNextRange = .{ .diff = diff, .ind = @intCast(i) };
            }
        }

        curr_range = rangesListRemaining.items[closestNextRange.?.ind];
        _ = rangesListRemaining.swapRemove(closestNextRange.?.ind);
    }

    print("Part 1 result: {d}\n", .{rangeLength});
    return intToStr(rangeLength);
}

// Input: Pass in list of ranges, then the index of the initial start range,
// Output: Get amount of values in consecutive range, potentially next
// fn getConsecutiveRangeLen()

fn copyArray(comptime T: type, allocator: std.mem.Allocator, dest: *std.array_list.Managed(std.array_list.Managed(T)), source: *const std.array_list.Managed(std.array_list.Managed(T))) !void {
    // Free existing dest contents
    for (dest.items) |row| {
        row.deinit();
    }
    dest.clearRetainingCapacity();

    // Deep copy from source to dest
    for (source.items) |row| {
        var row_copy = std.array_list.Managed(T).init(allocator);
        try row_copy.appendSlice(row.items);
        try dest.append(row_copy);
    }
}

// Useful stdlib functions
fn intToStr(sum: anytype) [:0]const u8 {
    var buf: [20]u8 = undefined;
    return std.fmt.bufPrintZ(&buf, "{d}", .{sum}) catch unreachable;
}
