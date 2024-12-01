const std = @import("std");
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;
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

        var column1 = ArrayList(u32).init(allocator);
        defer column1.deinit();

        var column2 = AutoHashMap(u32, u32).init(allocator);
        defer column2.deinit();

        while (iterator.next()) |line| {

            var columns_iterator = std.mem.splitAny(u8, line, " ");
            
            var list_idx: usize = 0;

            while (columns_iterator.next()) |col| {

                if (col.len > 0) {

                    const numb = try std.fmt.parseInt(u32, col, 10);

                    if (list_idx == 0) try column1.append(numb);
                    if (list_idx == 1) {
                        if (column2.getPtr(numb)) |count| {
                            count.* += 1;
                        } else {
                            try column2.put(numb, 1);
                        }
                    }
                    
                    list_idx += 1;
                }
            }

        }

        var similarity: u32 = 0;
        for (column1.items) |left| {
            if (column2.get(left)) |right| similarity += left * right;
        }

        print("similarity = {}\n", .{similarity});

    } else {

        @panic("You need to supply a filename");

    }




}
