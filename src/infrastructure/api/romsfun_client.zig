const std = @import("std");
const domain = @import("../../domain/mod.zig");
const http_client = @import("http_client.zig");
const url_encoder = @import("url_encoder.zig");
const parser = @import("romsfun_parser.zig");

const Allocator = std.mem.Allocator;

const USER_AGENT = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36";

pub const SearchParams = struct {
    console: domain.Console,
    query: []const u8,
};

pub fn search(allocator: Allocator, client: *std.http.Client, params: SearchParams) ![]domain.SearchResult {
    const encoded = try url_encoder.encodeQuery(allocator, params.query);
    defer allocator.free(encoded);

    const url = try std.fmt.allocPrint(allocator, "https://romsfun.com/?s={s}", .{encoded});
    defer allocator.free(url);

    const html = try fetchWithUserAgent(allocator, client, url);
    defer allocator.free(html);

    const games = try parser.parseSearchResults(allocator, html, params.console);
    defer {
        for (games) |g| { allocator.free(g.title); allocator.free(g.url); }
        allocator.free(games);
    }

    if (games.len == 0) return &.{};

    const results = try allocator.alloc(domain.SearchResult, games.len);
    for (games, 0..) |game, i| {
        results[i] = .{
            .identifier = try allocator.dupe(u8, game.url),
            .title = try std.fmt.allocPrint(allocator, "{s} [romsfun]", .{game.title}),
        };
    }

    return results;
}

pub fn resolveDownloadUrl(allocator: Allocator, client: *std.http.Client, game_page_url: []const u8) ![]const u8 {
    const game_html = try fetchWithUserAgent(allocator, client, game_page_url);
    defer allocator.free(game_html);

    const download_page_url = try parser.parseDownloadPageUrl(allocator, game_html);
    defer allocator.free(download_page_url);

    const link1_url = try std.fmt.allocPrint(allocator, "{s}/1", .{download_page_url});
    defer allocator.free(link1_url);

    const dl_html = try fetchWithUserAgent(allocator, client, link1_url);
    defer allocator.free(dl_html);

    return try parser.parseDirectDownloadUrl(allocator, dl_html);
}

fn fetchWithUserAgent(allocator: Allocator, client: *std.http.Client, url: []const u8) ![]u8 {
    const Writer = std.Io.Writer;
    var aw: Writer.Allocating = .init(allocator);
    defer aw.deinit();

    const result = try client.fetch(.{
        .location = .{ .url = url },
        .method = .GET,
        .response_writer = &aw.writer,
        .extra_headers = &.{
            .{ .name = "User-Agent", .value = USER_AGENT },
        },
    });

    if (result.status != .ok) return error.HttpRequestFailed;

    const data = aw.writer.buffer[0..aw.writer.end];
    return try allocator.dupe(u8, data);
}
