const std = @import("std");
const tui = @import("../tui/mod.zig");

pub const DownloadParams = struct {
    url: []const u8,
    save_dir: []const u8,
    filename: []const u8,
};

pub fn execute(allocator: std.mem.Allocator, client: *std.http.Client, params: DownloadParams, term: *tui.Terminal) !void {
    const uri = try std.Uri.parse(params.url);

    var req = try client.request(.GET, uri, .{
        .extra_headers = &.{
            .{ .name = "User-Agent", .value = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36" },
        },
    });
    defer req.deinit();
    try req.sendBodiless();

    var redirect_buf: [8192]u8 = undefined;
    var response = try req.receiveHead(&redirect_buf);

    if (response.head.status != .ok) {
        std.debug.print("Download HTTP status: {}\n", .{response.head.status});
        std.debug.print("Download URL: {s}\n", .{params.url});
        return error.HttpRequestFailed;
    }

    const total_size = response.head.content_length;

    std.fs.cwd().makePath(params.save_dir) catch {};

    const full_path = try std.fmt.allocPrint(allocator, "{s}/{s}", .{ params.save_dir, params.filename });
    defer allocator.free(full_path);

    const file = try std.fs.cwd().createFile(full_path, .{});
    defer file.close();

    var transfer_buf: [64]u8 = undefined;
    const body_reader = response.reader(&transfer_buf);

    var downloaded: u64 = 0;
    const start_time = std.time.nanoTimestamp();
    var last_progress_time: i128 = start_time;

    var file_buf: [65536]u8 = undefined;
    var file_writer = file.writer(&file_buf);
    const fw = &file_writer.interface;

    while (true) {
        const n = body_reader.stream(fw, .limited(32768)) catch |err| switch (err) {
            error.EndOfStream => break,
            else => |e| return e,
        };
        downloaded += n;

        const now = std.time.nanoTimestamp();
        if (now - last_progress_time >= 100_000_000 or n == 0) {
            tui.progress_screen.render(term, .{
                .filename = params.filename,
                .downloaded = downloaded,
                .total = total_size,
                .speed_bps = calcSpeed(downloaded, now - start_time),
            });
            last_progress_time = now;
        }
    }

    try fw.flush();

    tui.progress_screen.render(term, .{
        .filename = params.filename,
        .downloaded = downloaded,
        .total = total_size,
        .speed_bps = calcSpeed(downloaded, std.time.nanoTimestamp() - start_time),
    });
}

fn calcSpeed(bytes: u64, elapsed_ns: i128) u64 {
    const elapsed_s: f64 = @as(f64, @floatFromInt(elapsed_ns)) / 1_000_000_000.0;
    if (elapsed_s < 0.01) return 0;
    return @intFromFloat(@as(f64, @floatFromInt(bytes)) / elapsed_s);
}
