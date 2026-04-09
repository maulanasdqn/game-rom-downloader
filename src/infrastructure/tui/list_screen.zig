const terminal = @import("terminal.zig");
const input = @import("input.zig");

const MAX_VISIBLE: usize = 15;

pub fn render(term: *terminal.Terminal, title: []const u8, items: []const []const u8) !usize {
    if (items.len == 0) return error.NoResults;

    var selected: usize = 0;
    var scroll_offset: usize = 0;

    while (true) {
        term.clearScreen();
        term.print("\x1b[1;36m {s} \x1b[0m\n\n", .{title});

        const visible_count = @min(items.len, MAX_VISIBLE);
        const end = @min(scroll_offset + visible_count, items.len);

        for (scroll_offset..end) |i| {
            if (i == selected) {
                term.print("  \x1b[7m > {s} \x1b[0m\n", .{items[i]});
            } else {
                term.print("    {s}\n", .{items[i]});
            }
        }

        if (items.len > MAX_VISIBLE) {
            term.print("\n \x1b[90m Showing {d}-{d} of {d}\x1b[0m\n", .{ scroll_offset + 1, end, items.len });
        }

        term.print("\n \x1b[90m[Up/Down] Navigate  [Enter] Select  [Esc] Back\x1b[0m\n", .{});
        term.flush();

        const key = try input.readKey(term);
        switch (key.key) {
            .up => if (selected > 0) {
                selected -= 1;
                if (selected < scroll_offset) scroll_offset = selected;
            },
            .down => if (selected < items.len - 1) {
                selected += 1;
                if (selected >= scroll_offset + MAX_VISIBLE) scroll_offset = selected - MAX_VISIBLE + 1;
            },
            .enter => return selected,
            .escape => return error.UserCancelled,
            else => {},
        }
    }
}
