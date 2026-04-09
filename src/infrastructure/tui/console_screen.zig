const domain = @import("../../domain/mod.zig");
const terminal = @import("terminal.zig");
const input = @import("input.zig");

pub fn render(term: *terminal.Terminal) !domain.Console {
    var selected: usize = 0;
    const consoles = [_]domain.Console{ .ps1, .ps2 };

    while (true) {
        term.clearScreen();
        term.print("\x1b[1;36m Game ROM Downloader \x1b[0m\n\n", .{});
        term.print(" Select console:\n\n", .{});

        for (consoles, 0..) |c, i| {
            if (i == selected) {
                term.print("  \x1b[7m > {s} \x1b[0m\n", .{c.displayName()});
            } else {
                term.print("    {s}\n", .{c.displayName()});
            }
        }

        term.print("\n \x1b[90m[Up/Down] Navigate  [Enter] Select  [Esc] Quit\x1b[0m\n", .{});
        term.flush();

        const key = try input.readKey(term);
        switch (key.key) {
            .up => if (selected > 0) { selected -= 1; },
            .down => if (selected < consoles.len - 1) { selected += 1; },
            .enter => return consoles[selected],
            .escape => return error.UserCancelled,
            else => {},
        }
    }
}
