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

        std.debug.print("result = {}\n", .{try runProgram(input)});

    }

}


fn isDigit(char: u8) bool {

    if (char >= '0' and char <= '9') {
        return true;
    } else {
        return false;
    }

}


fn runProgram(input: []const u8) !u32 {

    var i: usize = 0;
    const window_len = 4;
    const max_num_len = 3;

    var result: u32 = 0;

    parser: while (i < input.len - window_len) : (i += 1){

        const window = input[i..(i + window_len)];

        if (std.mem.eql(u8, window, "mul(")) {
            log.debug("window = {s}", .{window});

            i += window_len; // jump where digits should be

            var num_buffer: [max_num_len]u8 = undefined;

            var num_idx: usize = 0;
            while (isDigit(input[i]) and num_idx < max_num_len) : ({i += 1; num_idx += 1;}) {

                num_buffer[num_idx] = input[i];

            }


            if (input[i] != ',') {
                log.debug("first number wasn't followed by ','", .{});
                continue :parser;
            }

            const num1_str = num_buffer[0..num_idx];

            const num1 = try std.fmt.parseInt(u32, num1_str, 10);
            log.debug("num1 = {}", .{num1});

            i += 1;


            num_idx = 0;
            while (isDigit(input[i]) and num_idx < max_num_len) : ({i += 1; num_idx += 1;}) {

                num_buffer[num_idx] = input[i];

            }


            if (input[i] != ')') {
                log.debug("second num wasn't followed by ')'", .{});
                continue :parser;
            }

            const num2_str = num_buffer[0..num_idx];
            const num2 = try std.fmt.parseInt(u32, num2_str, 10);

            log.debug("num2 = {}", .{num2});

            result += num1 * num2;
        }

    }

    return result;

}


test "example input" {
    // std.testing.log_level = .debug;

    const input = "xmul(2,4)%&mul[3,7]!@^do_not_mul(5,5)+mul(32,64]then(mul(11,8)mul(8,5))";
    const answer = 48;

    const result = try runProgram(input);

    std.testing.expect(result == answer) catch {

        print("expected {}, got {}\n", .{answer, result});

    };

}

