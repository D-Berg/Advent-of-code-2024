const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const print = std.debug.print;
const log = std.log;


const WORD = "MAS";

const Direction = enum {
    north,
    northWest,
    northEast,

    east,
    west,

    south,
    southWest,
    southEast,
    
};

const directions = [2]Direction {.northWest, .northEast};
const opposite_directions = [2]Direction {.southEast, .southWest};

const Puzzle = struct {
    allocator: Allocator,
    data: ArrayList([]const u8),
    n_rows: usize,
    n_cols: usize,
    
    const Position = struct {
        x: usize,
        y: usize,
        max_x: usize,
        max_y: usize,

        fn moveDir(pos: *Position, dir: Direction) !void {

            switch (dir) {

                .north => {
                    if (pos.x == 0) return error.Underflow;
                    pos.x -= 1;
                },
                .northWest => { 
                    if (pos.x == 0) return error.Underflow;
                    if (pos.y == 0) return error.Underflow;
                    pos.x -= 1; pos.y -= 1; 
                },
                .northEast => { 
                    if (pos.x == 0) return error.Underflow;
                    if (pos.y == pos.max_x - 1) return error.Overflow;
                    pos.x -= 1; pos.y += 1; 
                },

                .east => {
                    if (pos.y == pos.max_x - 1) return error.Overflow;
                    pos.y += 1;
                },
                .west => {
                    if (pos.y == 0) return error.Underflow;
                    pos.y -= 1;
                },
                
                .south => {
                    if (pos.x == pos.max_x - 1) return error.Overflow;
                    pos.x += 1;
                },
                .southWest => {
                    if (pos.x == pos.max_x - 1) return error.Overflow;
                    if (pos.y == 0) return error.Underflow;
                    pos.x += 1; pos.y -= 1;
                },
                .southEast => {
                    if (pos.x == pos.max_x - 1) return error.Overflow;
                    if (pos.y == pos.max_y - 1) return error.Overflow;
                    pos.x += 1; pos.y += 1;
                },
                
        

            }

        }
    };

    fn init(allocator: Allocator, input: []const u8) !Puzzle {

        var data = ArrayList([]const u8).init(allocator);
        
        var iterator = std.mem.tokenizeAny(u8, input, "\n");

        while (iterator.next()) |line| {
            try data.append(line);
        }

        return Puzzle {
            .allocator = allocator,
            .data = data,
            .n_rows = data.items.len,
            .n_cols = data.items[0].len
        };
        
    }

    fn deinit(self: *const Puzzle) void {
        self.data.deinit();
    }

    pub fn format(self: *const Puzzle, comptime fmt: []const u8, _: std.fmt.FormatOptions, writer: std.io.AnyWriter) !void {
        if (fmt.len != 0) std.fmt.invalidFmtError(fmt, self);
        for (self.data.items) |row| try writer.print("{s}\n", .{row});
    }

    fn get(self: *const Puzzle, pos: Position) u8 {
        return self.data.items[pos.x][pos.y];
    }


    fn isWordInDirection(self: *const Puzzle, start_pos: Position, dir: Direction, word: []const u8) bool {


        var pos = start_pos;

        log.debug("checking direction {s} for {s}, starting at pos({}, {})", .{@tagName(dir), word, pos.x, pos.y});
        for (0..word.len) |w_idx| {


            const char = self.get(pos);

            log.debug("pos({}, {}): char: {c}", .{pos.x, pos.y, char});
            
            if (char != word[w_idx]) {
                log.debug("couldnt find word: char didnt match", .{});
                return false;
            }

            if (w_idx < word.len - 1) {
                pos.moveDir(dir) catch {
                    log.debug("couldnt find word: pos is out of bounds", .{});
                    return false;
                };
            }

        }

        log.debug("found word at pos({}, {}) in dir {s}", .{start_pos.x, start_pos.y, @tagName(dir)});
        return true;

    }

    fn getCountOf(self: *const Puzzle, word: []const u8) !u32 {

        if (word.len == 0) return error.SearchWordTooShort;
        if ((word.len - 1) % 2 != 0) return error.NotAnUneverLength;

        const m_idx = (word.len - 1) / 2;

        const r_word = try self.allocator.alloc(u8, word.len);
        defer self.allocator.free(r_word);
        
        @memcpy(r_word[0..], word[0..]);

        std.mem.reverse(u8, r_word);

        var count: u32 = 0;
        var curr_pos: Position = .{ 
            .x = 0, .y = 0, 
            .max_x = self.n_rows, 
            .max_y = self.n_cols 
        };

        for (0..self.n_rows) |x| {

            char_loop: for (0..self.data.items[x].len) |y| {
                
                curr_pos.x = x; curr_pos.y = y;

                const char = self.get(curr_pos);

                if (char == word[m_idx]) {

                    log.debug("found start char: {c} at pos({}, {})", .{
                        char, curr_pos.x, curr_pos.y
                    });


                    for (directions, opposite_directions) |dir, odir| {
                        var corner = curr_pos;
                        corner.moveDir(odir) catch continue :char_loop;

                        // check corner for either the word or the reverse word
                        const diag = self.isWordInDirection(corner, dir, word) or self.isWordInDirection(corner, dir, r_word);
                        if (diag == false) {
                            log.debug("diag {s} didnt contain word", .{@tagName(dir)});
                            continue :char_loop;
                        }
                    }

                    log.debug("found Cross at pos({}, {})", .{curr_pos.x, curr_pos.y});
                    count += 1;

                }
        

            }
        

        }

        return count;

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

        const count = puzzle.getCountOf(WORD);

        print("{s} appears: {any} times\n", .{WORD, count});

    }


}


test "example input" {

    std.testing.log_level = .debug;

    const allocator = std.testing.allocator;

    const answer = 9;
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

    const result = puzzle.getCountOf(WORD);

    try std.testing.expectEqual(answer, result);

}

