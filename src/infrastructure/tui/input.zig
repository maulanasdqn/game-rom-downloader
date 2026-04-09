const terminal = @import("terminal.zig");

pub const Key = enum { up, down, left, right, enter, escape, backspace, char };

pub const KeyEvent = struct {
    key: Key,
    char: u8 = 0,
};

pub fn readKey(term: *terminal.Terminal) !KeyEvent {
    var buf: [4]u8 = undefined;
    var bytes_read: u32 = 0;

    const h = term.stdin_handle orelse return error.StdinNotAvailable;

    if (terminal.ReadConsoleA(h, &buf, 1, &bytes_read, null) == 0) return error.ReadFailed;
    if (bytes_read == 0) return error.ReadFailed;

    const c = buf[0];

    if (c == 0x1b) {
        if (terminal.ReadConsoleA(h, &buf, 1, &bytes_read, null) == 0 or bytes_read == 0) return .{ .key = .escape };
        if (buf[0] == '[') {
            if (terminal.ReadConsoleA(h, &buf, 1, &bytes_read, null) == 0 or bytes_read == 0) return .{ .key = .escape };
            return switch (buf[0]) {
                'A' => .{ .key = .up },
                'B' => .{ .key = .down },
                'C' => .{ .key = .right },
                'D' => .{ .key = .left },
                else => .{ .key = .escape },
            };
        }
        return .{ .key = .escape };
    }

    if (c == '\r' or c == '\n') return .{ .key = .enter };
    if (c == 0x7f or c == 0x08) return .{ .key = .backspace };
    if (c >= 0x20 and c < 0x7f) return .{ .key = .char, .char = c };
    if (c == 0x03) return error.UserInterrupt;

    return .{ .key = .escape };
}
