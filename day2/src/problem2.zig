const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const print = std.debug.print;
const log = std.log;

const Direction = enum {
    increasing,
    decreasing,
};

fn getOverallDirection(numbers: []const i32) Direction {

    var i: usize = 0;
    var n_inc: u32 = 0;
    var n_dec: u32 = 0;

    while (i < numbers.len - 1) : (i += 1) {

        const dir = getDirection(numbers[i + 1] - numbers[i]);

        switch (dir) {
            .increasing => n_inc += 1,
            .decreasing => n_dec += 1,
        }
    }

    if (n_inc > n_dec) {
        return .increasing;
    } else {
        return .decreasing;
    }
}

/// issfirstTime: true if its the first time this function is called
fn isSafe(numbers: []const i32, isFirstTime: bool, allocator: Allocator) !bool {

    var i: usize = 0;
    var overall_dir: Direction = getOverallDirection(numbers);

    if (isFirstTime) log.debug("\nchecking numbers = {any}, dir = {s}", .{numbers, @tagName(overall_dir)});

    while (i < numbers.len - 1) : (i += 1) {

        const level_status = checkLevels(i, &overall_dir, numbers[i], numbers[i + 1]);

        if (level_status == .bad) {

            if (isFirstTime) {

                // Create subslice with first level removed
                const slice_1 = try allocator.alloc(i32, numbers.len - 1);
                defer allocator.free(slice_1);

                var dest_idx: usize = 0;
                for (numbers, 0..) |source_numb, source_idx| {
                    if (source_idx == i) continue;
                    slice_1[dest_idx] = source_numb; 
                    dest_idx += 1;
                } 

                log.debug("checking sub_slice1 = {any}", .{slice_1});
                if (try isSafe(slice_1, false, allocator)) {

                    return true;

                } else { // only check second subslice if 1st is unsafe
                    
                    // Create subslice with second level removed
                    const slice_2 = try allocator.alloc(i32, numbers.len - 1);
                    defer allocator.free(slice_2);

                    dest_idx = 0;
                    for (numbers, 0..) |source_numb, source_idx| {
                        if (source_idx == i + 1) continue;
                        slice_2[dest_idx] = source_numb; 
                        dest_idx += 1;
                    } 

                    log.debug("checking sub_slice2 = {any}", .{slice_2});
                    return try isSafe(slice_2, false, allocator);
                }
            }

            return false;
        }

    }

    return true;

}

const LevelStatus = enum {
    ok,
    bad
};

fn checkLevels(i: usize, overall_dir: *Direction, n1: i32, n2: i32) LevelStatus {

    const diff = n2 - n1;
    if (diff == 0) {
        log.debug("dir is stale", .{});
        return .bad;
    }

    const current_dir = getDirection(diff);

    log.debug("i = {} | n1 = {}, n2 = {}, diff = {}, dir = {s}", .{
        i, n1, n2, diff, @tagName(current_dir)
    });


    if (i == 0) {
        overall_dir.* = current_dir;
    } else {

        if (current_dir != overall_dir.*) {
            log.debug("directions don't match for n1 = {}, n2 = {}, overall_dir = {s}, current_dir = {s}", .{
                n1, n2, @tagName(overall_dir.*), @tagName(current_dir)
            });
            return .bad;
        }

    }

    const abs_diff = @abs(diff);
    log.debug("abs diff = {}", .{abs_diff});
    if (abs_diff < 1 or abs_diff > 3) return .bad;

    return .ok;

}

fn getDirection(diff: i32) Direction {
    if (diff > 0) {
        return .increasing;
    } else {
        return .decreasing;
    }
}


pub fn main() !void {


    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);


    if (args.len == 2) {

        const filename = args[1];

        const file = try std.fs.cwd().openFile(filename, .{});
        defer file.close();

        const file_stat = try file.stat();

        const input = try file.readToEndAlloc(allocator, file_stat.size);
        defer allocator.free(input);

        var line_iterator = std.mem.split(u8, input, "\n");

        var n_safe: u32 = 0;

        while (line_iterator.next()) |line| {

            if (line.len == 0) continue;


            var number_iterator = std.mem.split(u8, line, " ");

            var numbers = ArrayList(i32).init(allocator);
            defer numbers.deinit();

            // Gather numbers in an arraylist
            while (number_iterator.next()) |n_str| {
                try numbers.append(try std.fmt.parseInt(i32, n_str, 10));
            }

            const is_safe = try isSafe(numbers.items, true, allocator);

            log.debug("numbers = {any}, is_safe = {}", .{numbers.items, is_safe});

            if (is_safe) {

                n_safe += 1;
            }

        }

        print("Number of safe reports: {}\n", .{n_safe});


    } else {
        @panic("You need to supply input filename");
    }

}

