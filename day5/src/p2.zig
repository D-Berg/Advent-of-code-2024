const std = @import("std");
const Allocator = std.mem.Allocator;
const AutoHashMap = std.AutoHashMap;
const ArrayList = std.ArrayList;
const ArrayHashMap = std.ArrayHashMap;
const indexOfScalar = std.mem.indexOfScalar;
const tokenizeSequence = std.mem.tokenizeSequence;
const print = std.debug.print;
const log = std.log;


/// Before: list of numbers that should be before key
/// After: list of numbers that should be after key
/// (naming variables is hard...)
const Order = struct {
    allocator: Allocator,
    before: AutoHashMap(u32, ArrayList(u32)),
    after: AutoHashMap(u32, ArrayList(u32)),

    fn init(allocator: Allocator) Order {
        return .{
            .allocator = allocator,
            .before = AutoHashMap(u32, ArrayList(u32)).init(allocator),
            .after = AutoHashMap(u32, ArrayList(u32)).init(allocator),
        };
    }

    fn deinit(self: *Order) void {
        var before_iterator = self.before.valueIterator();
        while (before_iterator.next()) |values| values.deinit();
        self.before.deinit();

        var after_iterator = self.after.valueIterator();
        while (after_iterator.next()) |values| values.deinit();
        self.after.deinit();
    }

    fn put(self: *Order, before: u32, after: u32) !void {

        if (self.before.getPtr(before)) |values| {
            try values.append(after);
        } else {
            var values = ArrayList(u32).init(self.allocator);
            try values.append(after);

            try self.before.put(before, values);
        }

        
        if (self.after.getPtr(after)) |values| {
            try values.append(before);
        } else {
            var values = ArrayList(u32).init(self.allocator);
            try values.append(before);

            try self.after.put(after, values);
        }


    }

    /// Get the pages that should come before page
    fn getPagesBefore(self: *const Order, page: u32) ?[]const u32 {
        if (self.before.get(page)) |pages| {
            return pages.items;
        } else {
            return null;
        }

    }

    fn getPagesAfter(self: *const Order, page: u32) ?[]const u32 {

        if (self.after.get(page)) |pages| {
            return pages.items;
        } else {
            return null;
        }

    }

    fn isUpdateCorrect(self: *const Order, pages: []const u32) bool {

        for (pages, 0..) |curr_page, idx| {


            if (self.getPagesBefore(curr_page)) |pages_before| {
                log.debug("page {}, must be before {any}", .{
                    curr_page, pages_before
                });

                const pages_after_current_page = pages[(idx + 1)..];

                
                for (pages_after_current_page) |a_page| {
                    // for each page after current pages, find it
                    // in pages that curr page must be before.


                    if (indexOfScalar(u32, pages_before, a_page) == null) {
                        log.debug("couldnt find page {} in pages {any} that should come after", .{
                            a_page, pages_before
                        });

                        return false;

                    }
                }
                
            }

            if (self.getPagesAfter(curr_page)) |pages_after| {

                log.debug("page {} must be after {any}", .{curr_page, pages_after});
                const pages_before_current_page = pages[0..idx];

                
                for (pages_before_current_page) |b_page| {
                    // for each page after current pages, find it
                    // in pages that curr page must be before.


                    if (indexOfScalar(u32, pages_after, b_page) == null) {
                        log.debug("couldnt find page {} in pages {any} that should come before", .{
                            b_page, pages_after
                        });

                        return false;

                    }
                }

            }

            

        
        }

        return true;

    }


};


fn getSumOfMiddlePages(allocator: Allocator, input: []const u8) !u32 {

    var sum: u32 = 0;

    var section_iterator = tokenizeSequence(u8, input, "\n\n");

    const ordering_input = section_iterator.next() orelse 
        return error.WrongInputFormat;
    const update_input = section_iterator.next() orelse 
        return error.WrongInputFormat;

    var ordering = Order.init(allocator);
    defer ordering.deinit();

    var ordering_iterator = tokenizeSequence(u8, ordering_input, "\n");

    // parse ordering
    while (ordering_iterator.next()) |line| {

        var page_iterator = tokenizeSequence(u8, line, "|");
        const num1_str = page_iterator.next() orelse return error.WrongPageFormat;
        const num2_str = page_iterator.next() orelse return error.WrongPageFormat;

        const before = try std.fmt.parseInt(u32, num1_str, 10);
        const after = try std.fmt.parseInt(u32, num2_str, 10);

        try ordering.put(before, after);

    }

    var update_iterator = tokenizeSequence(u8, update_input, "\n");

    while (update_iterator.next()) |line| {

        var page_iterator = tokenizeSequence(u8, line, ",");

        var update = ArrayList(u32).init(allocator);
        defer update.deinit();

        while (page_iterator.next()) |page_str| {
            const page = try std.fmt.parseInt(u32, page_str, 10);
            try update.append(page);
        }

        log.debug("checking update: {s}", .{line});
        if (ordering.isUpdateCorrect(update.items)) {
            log.debug("update {s} has correct order", .{line});

            const m_idx = (update.items.len - 1) / 2;
            
            sum += update.items[m_idx];

        } else {
            log.debug("update {s} has incorrect order", .{line});
        }




    }

    return sum;


}

pub fn main() !void {

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};  
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len == 2) {
        const path = args[1];

        const file = try std.fs.cwd().openFile(path, .{});
        defer file.close();

        const file_stat = try file.stat();

        const input = try file.readToEndAlloc(allocator, file_stat.size);
        defer allocator.free(input);

        const result = try getSumOfMiddlePages(allocator, input);

        print("Sum of correct middle pages: {}\n", .{result});

    }

}


test "example input" {

    std.testing.log_level = .debug;

    const allocator = std.testing.allocator;

    const input = 
        \\47|53
        \\97|13
        \\97|61
        \\97|47
        \\75|29
        \\61|13
        \\75|53
        \\29|13
        \\97|29
        \\53|29
        \\61|53
        \\97|53
        \\61|29
        \\47|13
        \\75|47
        \\97|75
        \\47|61
        \\75|61
        \\47|29
        \\75|13
        \\53|13
        \\
        \\75,47,61,53,29
        \\97,61,53,29,13
        \\75,29,13
        \\75,97,47,61,53
        \\61,13,29
        \\97,13,75,29,47
    ;

    const answer = 143;

    const result = try getSumOfMiddlePages(allocator, input);

    try std.testing.expectEqual(answer, result);
}
