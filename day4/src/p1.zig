const std = @import("std");
const print = std.debug.print;
const log = std.log;


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


    }


}


test "example input" {

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

    _ = input;

}
