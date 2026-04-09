const std = @import("std");

const Writer = std.Io.Writer;

pub const HttpGetOpts = struct {
    url: []const u8,
    raw_uri: bool = false,
};

pub fn get(allocator: std.mem.Allocator, client: *std.http.Client, opts: HttpGetOpts) ![]u8 {
    var aw: Writer.Allocating = .init(allocator);
    defer aw.deinit();

    const result = try client.fetch(.{
        .location = .{ .url = opts.url },
        .method = .GET,
        .response_writer = &aw.writer,
        .raw_uri = opts.raw_uri,
    });

    if (result.status != .ok) return error.HttpRequestFailed;

    const data = aw.writer.buffer[0..aw.writer.end];
    return try allocator.dupe(u8, data);
}
