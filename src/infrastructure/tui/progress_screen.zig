const terminal = @import("terminal.zig");
const format = @import("format.zig");

pub const ProgressState = struct {
    filename: []const u8,
    downloaded: u64,
    total: ?u64,
    speed_bps: u64,
};

pub fn render(term: *terminal.Terminal, state: ProgressState) void {
    term.write("\x1b[3;1H\x1b[K");
    term.print(" Downloading: {s}", .{state.filename});
    term.write("\x1b[5;1H\x1b[K");

    if (state.total) |t| {
        const ratio: f64 = if (t > 0) @as(f64, @floatFromInt(state.downloaded)) / @as(f64, @floatFromInt(t)) else 0.0;
        const percent: u64 = @intFromFloat(@min(ratio * 100.0, 100.0));
        const bar_width: u64 = 30;
        const filled: u64 = @intFromFloat(@min(ratio * @as(f64, @floatFromInt(bar_width)), @as(f64, @floatFromInt(bar_width))));

        term.write(" [");
        var i: u64 = 0;
        while (i < bar_width) : (i += 1) {
            term.write(if (i < filled) "=" else "-");
        }
        term.print("] {d}%", .{percent});

        term.write("\x1b[6;1H\x1b[K");
        term.print(" {s} / {s} | {s}/s", .{
            format.size(state.downloaded).slice(),
            format.size(t).slice(),
            format.size(state.speed_bps).slice(),
        });
    } else {
        term.print(" {s} downloaded | {s}/s", .{
            format.size(state.downloaded).slice(),
            format.size(state.speed_bps).slice(),
        });
    }

    term.flush();
}
