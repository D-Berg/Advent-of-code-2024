const std = @import("std");
const print = std.debug.print;
const log = std.log;

const Direction = enum {
    increasing,
    decreasing,
};

fn isSafe(line: []const u8) !bool {

    var i: usize = 0;
    var overall_dir: Direction = undefined;

    var number_iterator = std.mem.split(u8, line, " ");

    while (number_iterator.next()) |n1_str| : (i += 1) {

        const n1 = try std.fmt.parseInt(i32, n1_str, 10);
        var n2: i32 = undefined;

        if (number_iterator.peek()) |n2_str|{
            n2 = try std.fmt.parseInt(i32, n2_str, 10);
        } else {
            break; // checked all pairs
        }


        const diff = n2 - n1;
        if (diff == 0) {
            log.debug("dir is stale", .{});
            return false;
        }

        const current_dir = getDirection(diff);

        log.debug("i = {} | n1 = {}, n2 = {}, diff = {}, dir = {s}", .{
            i, n1, n2, diff, @tagName(current_dir)
        });


        if (i == 0) {
            overall_dir = current_dir;
        } else {

            if (current_dir != overall_dir) {
                log.debug("directions don't match for n1 = {}, n2 = {}, overall_dir = {s}, current_dir = {s}", .{
                    n1, n2, @tagName(overall_dir), @tagName(current_dir)
                });
                return false;
            }

        }

        const abs_diff = @abs(diff);
        log.debug("abs diff = {}", .{abs_diff});
        if (abs_diff < 1 or abs_diff > 3) return false;

    }

    return true;

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

            log.debug("line = {s}", .{line});

            const is_safe = try isSafe(line);

            log.debug("is_safe = {}", .{is_safe});

            if (is_safe) n_safe += 1;

        }

        print("Number of safe reports: {}\n", .{n_safe});


    } else {
        @panic("You need to supply input filename");
    }

}

