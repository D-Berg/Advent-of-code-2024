const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const print = std.debug.print;
const log = std.log;

const Puzzle = struct {
    data: ArrayList(ArrayList(u8)),
    n_rows: usize,
    n_cols: usize,
    
    const Position = struct {
        x: usize,
        y: usize
    };

    fn init(allocator: Allocator, input: []const u8) !Puzzle {

        var data = ArrayList(ArrayList(u8)).init(allocator);
        
        var iterator = std.mem.tokenizeAny(u8, input, "\n");

        while (iterator.next()) |line| {
            var row = ArrayList(u8).init(allocator);

            for (line) |char| try row.append(char);

            try data.append(row);
        }

        return Puzzle {
            .data = data,
            .n_rows = data.items.len,
            .n_cols = data.items[0].items.len
        };
        
    }

    fn deinit(self: *const Puzzle) void {
        for (self.data.items) |row| row.deinit();
        self.data.deinit();
    }

    pub fn format(self: *const Puzzle, comptime fmt: []const u8, _: std.fmt.FormatOptions, writer: std.io.AnyWriter) !void {
        if (fmt.len != 0) std.fmt.invalidFmtError(fmt, self);
        for (self.data.items) |row| try writer.print("{s}\n", .{row.items});
    }


};

pub fn main() !void {

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();


    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len == 2) {

        const file_name = args[1];


        const file = try std.fs.cwd().openFile(file_name, .{});
        defer file.close();

        const file_stat = try file.stat();

        const input = try file.readToEndAlloc(allocator, file_stat.size);
        defer allocator.free(input);

        const puzzle = try Puzzle.init(allocator, input);
        defer puzzle.deinit();

    }


}


test "example input" {
    const allocator = std.testing.allocator;

    const input = 
        \\MMMSXXMASM
        \\MSAMXMSMSA
        \\AMXSXMAAMM
        \\MSAMASMSMX
        \\XMASAMXAMM
        \\XXAMMXXAMA
        \\SMSMSASXSS
        \\SAXAMASAAA
        \\MAMMMXMMMM
        \\MXMXAXMASX
    ;

    const puzzle = try Puzzle.init(allocator, input);
    defer puzzle.deinit();

    print("{}", .{puzzle});

}
