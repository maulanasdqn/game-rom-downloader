const std = @import("std");
const terminal = @import("terminal.zig");
const input = @import("input.zig");

pub const TextInputOpts = struct {
    title: []const u8,
    prompt: []const u8 = "",
    prefill: []const u8 = "",
};

pub fn render(term: *terminal.Terminal, allocator: std.mem.Allocator, opts: TextInputOpts) ![]u8 {
    var buf: std.ArrayList(u8) = .empty;
    defer buf.deinit(allocator);

    if (opts.prefill.len > 0) try buf.appendSlice(allocator, opts.prefill);

    term.showCursor();
    defer term.hideCursor();

    while (true) {
        term.clearScreen();
        term.print("\x1b[1;36m Game ROM Downloader \x1b[0m\n\n", .{});
        term.print(" {s}\n\n", .{opts.title});
        term.print("  {s}{s}\x1b[K", .{ opts.prompt, buf.items });
        term.print("\n\n \x1b[90m[Enter] Confirm  [Esc] Cancel\x1b[0m\n", .{});
        term.flush();

        const key = try input.readKey(term);
        switch (key.key) {
            .enter => {
                if (buf.items.len == 0) continue;
                return try allocator.dupe(u8, buf.items);
            },
            .backspace => if (buf.items.len > 0) { _ = buf.pop(); },
            .escape => return error.UserCancelled,
            .char => try buf.append(allocator, key.char),
            else => {},
        }
    }
}
