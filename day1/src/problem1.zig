const std = @import("std");
const ArrayList = std.ArrayList;
const print = std.debug.print;

pub fn main() !void {

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len == 2) {

        const filename = args[1];

        print("{s}\n", .{filename});

        const input_file = try std.fs.cwd().openFile(filename, .{});
        defer input_file.close();

        const file_stat = try input_file.stat();

        const input = try input_file.readToEndAlloc(allocator, file_stat.size);
        defer allocator.free(input);

        var iterator = std.mem.split(u8, input, "\n");

        const column1 = ArrayList(i32).init(allocator);
        const column2 = ArrayList(i32).init(allocator);

        var lists: [2]ArrayList(i32) = .{column1, column2};
        defer {
            for (lists) |col| col.deinit();
        }

        while (iterator.next()) |line| {

            var columns_iterator = std.mem.splitAny(u8, line, " ");
            
            var list_idx: usize = 0;

            while (columns_iterator.next()) |col| {

                if (col.len > 0) {

                    const numb = try std.fmt.parseInt(i32, col, 10);

                    try lists[list_idx].append(numb);
                    
                    list_idx += 1;
                }
            }

        }

        for (lists) |col| {
            std.mem.sort(i32, col.items, {}, std.sort.asc(i32));
        }

        var distance: u32 = 0;
        for (lists[0].items, lists[1].items) |left, right| {
            distance += @abs(left - right);
        }

        print("distance = {}\n", .{distance});

    } else {

        @panic("You need to supply a filename");

    }




}

