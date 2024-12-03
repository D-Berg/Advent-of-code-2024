const std = @import("std");
const print = std.debug.print;
const log = std.log;
const Timer = std.time.Timer;

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


        const n_runs = 10000;
        var total_time: u64 = 0;
        var result: u32 = undefined;

        var timer = try Timer.start();
        for (0..n_runs) |_| {

            result = try runProgram(input);
            total_time += timer.lap();

        }
        const average_time = total_time / std.time.ns_per_us / n_runs;

        std.debug.print("result = {}, time: {} μs\n", .{result, average_time});

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
    const mul_window_len = 4;
    const do_window_len = 4;
    const dont_window_len = 7;
    const max_num_len = 3;

    var result: u32 = 0;

    var enabled: bool = true;

    parser: while (i < input.len - dont_window_len) : (i += 1){

        const mul_window = input[i..(i + mul_window_len)];

        if (std.mem.eql(u8, mul_window, "mul(") and enabled) {
            log.debug("window = {s}", .{mul_window});

            i += mul_window_len; // jump where digits should be

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

            continue :parser;
        }

        const do_window = input[i..(i + do_window_len)];
        if (std.mem.eql(u8, do_window, "do()") and !enabled) {
            enabled = true;
            log.debug("enabled parsing", .{});
            continue :parser;
        }

        const dont_window = input[i..(i + dont_window_len)];
        if (std.mem.eql(u8, dont_window, "don't()") and enabled) {
            enabled = false;
            log.debug("disabled parsing", .{});
            continue :parser;
        }

    }


    return result;

}


test "example input" {
    // std.testing.log_level = .debug;

    const input = "xmul(2,4)&mul[3,7]!^don't()_mul(5,5)+mul(32,64](mul(11,8)undo()?mul(8,5))";
    const answer = 48;

    const result = try runProgram(input);

    std.testing.expect(result == answer) catch |err| {
        print("expected {}, got {}\n", .{answer, result});
        return err;
    };


}

