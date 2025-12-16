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

pub fn part1(input: []const u8) ![:0]const u8 {
    var amo: i32 = 0;

    var lines = tokenizeSca(u8, input, '\n');
    // Example: Building a 2D array with unknown dimensions
    // Option 1: Using ArrayList of ArrayLists (most flexible)
    const allocator = std.heap.page_allocator;
    var grid = std.array_list.Managed(std.array_list.Managed(u8)).init(allocator);
    defer {
        for (grid.items) |row| {
            row.deinit();
        }
        grid.deinit();
    }

    while (lines.next()) |line| {
        // Add a row to the grid
        var row = std.array_list.Managed(u8).init(allocator);
        for (line) |char| {
            try row.append(char);
        }

        try grid.append(row);
    }

    // Access: grid.items[y].items[x]
    // Width: grid.items[0].items.len (if grid has at least one row)
    // Height: grid.items.len
    // Print grid dimensions
    const height = grid.items.len;
    const width = if (height > 0) grid.items[0].items.len else 0;
    print("Grid dimensions - Height: {d}, Width: {d}\n", .{ height, width });

    for (0..width) |x| {
        for (0..height) |y| {
            if (grid.items[y].items[x] == '@') {
                const squaresAmo = checkAdjacentSquares(&grid, .{ .x = x, .y = y });

                if (squaresAmo < 4) {
                    amo += 1;
                }
            }
        }
    }

    print("Part 1 result: {d}\n", .{amo});
    return intToStr(amo);
}

pub fn part2(input: []const u8) ![:0]const u8 {
    var amo: i32 = 0;

    var lines = tokenizeSca(u8, input, '\n');

    const allocator = std.heap.page_allocator;
    var grid = std.array_list.Managed(std.array_list.Managed(u8)).init(allocator);
    defer {
        for (grid.items) |row| {
            row.deinit();
        }
        grid.deinit();
    }

    while (lines.next()) |line| {
        // Add a row to the grid
        var row = std.array_list.Managed(u8).init(allocator);
        for (line) |char| {
            try row.append(char);
        }

        try grid.append(row);
    }

    // Copy grid so we can edit it for next run and remove paperrolls!
    var grid_copy = std.array_list.Managed(std.array_list.Managed(u8)).init(allocator);
    defer {
        for (grid_copy.items) |row| {
            row.deinit();
        }
        grid_copy.deinit();
    }
    try copyArray(u8, allocator, &grid_copy, &grid);

    const height = grid.items.len;
    const width = if (height > 0) grid.items[0].items.len else 0;
    print("Grid dimensions - Height: {d}, Width: {d}\n", .{ height, width });

    while (true) {
        var run_amo: u16 = 0;
        for (0..width) |x| {
            for (0..height) |y| {
                if (grid.items[y].items[x] == '@') {
                    const squaresAmo = checkAdjacentSquares(&grid, .{ .x = x, .y = y });

                    if (squaresAmo < 4) {
                        // Remove paper roll at position if we can!
                        grid_copy.items[y].items[x] = '.';

                        run_amo += 1;
                    }
                }
            }
        }

        if (run_amo == 0) {
            break;
        } else {
            amo += run_amo;

            // Copy grid_copy to grid over!
            try copyArray(u8, allocator, &grid, &grid_copy);
        }
    }

    print("Part 1 result: {d}\n", .{amo});
    return intToStr(amo);
}

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

pub fn checkAdjacentSquares(grid: *std.array_list.Managed(std.array_list.Managed(u8)), el_ind: struct { y: usize, x: usize }) u8 {
    const height = grid.items.len;
    const width = if (height > 0) grid.items[0].items.len else 0;

    // Square Corners
    const square_x_min = @max(el_ind.x, 1) - 1;
    const square_x_max = @min(el_ind.x + 2, width);

    const square_y_min = @max(el_ind.y, 1) - 1;
    const square_y_max = @min(el_ind.y + 2, height);

    var amo: u8 = 0;

    for (square_x_min..square_x_max) |x| {
        for (square_y_min..square_y_max) |y| {
            if (y == el_ind.y and x == el_ind.x) {
                continue;
            }

            if (grid.items[y].items[x] == '@') {
                amo += 1;
            }
        }
    }

    // // Debug Logs
    // print("Element at ({d}, {d}), Square boundaries: x=[{d}..{d}], y=[{d}..{d}], amo count: {d}\n", .{
    //     el_ind.x,
    //     el_ind.y,
    //     square_x_min,
    //     square_x_max,
    //     square_y_min,
    //     square_y_max,
    //     amo,
    // });

    return amo;
}

// Useful stdlib functions
fn intToStr(sum: anytype) [:0]const u8 {
    var buf: [20]u8 = undefined;
    return std.fmt.bufPrintZ(&buf, "{d}", .{sum}) catch unreachable;
}
