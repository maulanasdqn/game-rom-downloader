const std = @import("std");
const domain = @import("../../domain/mod.zig");

const Allocator = std.mem.Allocator;

pub const ParsedGame = struct {
    title: []const u8,
    url: []const u8,
};

pub fn parseSearchResults(allocator: Allocator, html: []const u8, console: domain.Console) ![]ParsedGame {
    const platform = switch (console) {
        .ps1 => "/roms/playstation/",
        .ps2 => "/roms/playstation-2/",
    };

    var results: std.ArrayList(ParsedGame) = .empty;
    defer results.deinit(allocator);

    var pos: usize = 0;
    while (pos < html.len) {
        const href_start = std.mem.indexOfPos(u8, html, pos, "href=\"https://romsfun.com") orelse break;
        const url_start = href_start + 6;
        const url_end = std.mem.indexOfPos(u8, html, url_start, "\"") orelse break;
        const url = html[url_start..url_end];

        pos = url_end + 1;

        if (std.mem.indexOf(u8, url, platform) == null) continue;
        if (!std.mem.endsWith(u8, url, ".html")) continue;

        const title = extractTitle(html, pos) orelse continue;

        const is_dup = for (results.items) |r| {
            if (std.mem.eql(u8, r.url, url)) break true;
        } else false;

        if (!is_dup) {
            try results.append(allocator, .{
                .title = try allocator.dupe(u8, title),
                .url = try allocator.dupe(u8, url),
            });
        }
    }

    return try results.toOwnedSlice(allocator);
}

fn extractTitle(html: []const u8, from: usize) ?[]const u8 {
    const search_range = @min(from + 500, html.len);
    const chunk = html[from..search_range];

    if (std.mem.indexOf(u8, chunk, ">")) |gt| {
        const start = gt + 1;
        if (std.mem.indexOfPos(u8, chunk, start, "<")) |lt| {
            const title = std.mem.trim(u8, chunk[start..lt], " \t\n\r");
            if (title.len > 2) return title;
        }
    }
    return null;
}

pub fn parseDownloadPageUrl(allocator: Allocator, html: []const u8) ![]const u8 {
    const marker = "href=\"https://romsfun.com/download/";
    const start = std.mem.indexOf(u8, html, marker) orelse return error.NoResults;
    const url_start = start + 6;
    const url_end = std.mem.indexOfPos(u8, html, url_start, "\"") orelse return error.NoResults;
    return try allocator.dupe(u8, html[url_start..url_end]);
}

pub fn parseDirectDownloadUrl(allocator: Allocator, html: []const u8) ![]const u8 {
    const marker = "sto.romsfast.com/";
    const start = std.mem.indexOf(u8, html, marker) orelse return error.NoResults;

    const prefix_start = start - 8;
    const url_start = if (prefix_start < html.len and std.mem.startsWith(u8, html[prefix_start..], "https://"))
        prefix_start
    else blk: {
        const https = std.mem.lastIndexOf(u8, html[0..start], "https://") orelse return error.NoResults;
        break :blk https;
    };

    const url_end = std.mem.indexOfAny(u8, html[url_start..], "\"' <>") orelse return error.NoResults;
    return try allocator.dupe(u8, html[url_start .. url_start + url_end]);
}
