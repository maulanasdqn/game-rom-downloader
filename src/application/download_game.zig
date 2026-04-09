const std = @import("std");
const domain = @import("../domain/mod.zig");
const infra = @import("../infrastructure/mod.zig");

pub const Input = struct {
    allocator: std.mem.Allocator,
    client: *std.http.Client,
    identifier: []const u8,
    title: []const u8,
    filename: []const u8,
    save_dir: []const u8,
    console: domain.Console,
    term: *infra.tui.Terminal,
};

pub fn execute(input: Input) !void {
    const url = try resolveUrl(input);
    defer input.allocator.free(url);

    try infra.download.execute(input.allocator, input.client, .{
        .url = url,
        .save_dir = input.save_dir,
        .filename = input.filename,
    }, input.term);
}

fn resolveUrl(input: Input) ![]const u8 {
    if (!isRomsfunUrl(input.identifier)) {
        return try infra.api.archive_client.buildDownloadUrl(
            input.allocator,
            input.identifier,
            input.filename,
        );
    }

    return try resolveViaArchive(input);
}

fn resolveViaArchive(input: Input) ![]const u8 {
    const clean_title = stripRomsfunTag(input.title);

    const results = infra.api.archive_client.search(input.allocator, input.client, .{
        .console = input.console,
        .query = clean_title,
    }) catch return error.NoResults;
    defer domain.SearchResult.freeSlice(results, input.allocator);

    if (results.len == 0) return error.NoResults;

    const files = infra.api.archive_client.getFiles(
        input.allocator,
        input.client,
        results[0].identifier,
    ) catch return error.NoResults;
    defer domain.GameFile.freeSlice(files, input.allocator);

    if (files.len == 0) return error.NoResults;

    return try infra.api.archive_client.buildDownloadUrl(
        input.allocator,
        results[0].identifier,
        files[0].name,
    );
}

fn stripRomsfunTag(title: []const u8) []const u8 {
    if (std.mem.indexOf(u8, title, " [romsfun]")) |idx| {
        return std.mem.trimRight(u8, title[0..idx], " ");
    }
    return title;
}

fn isRomsfunUrl(identifier: []const u8) bool {
    return std.mem.startsWith(u8, identifier, "https://romsfun.com/");
}
