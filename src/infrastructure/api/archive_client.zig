const std = @import("std");
const domain = @import("../../domain/mod.zig");
const dto = @import("dto.zig");
const http_client = @import("http_client.zig");
const url_encoder = @import("url_encoder.zig");

const Allocator = std.mem.Allocator;

pub const SearchParams = struct {
    console: domain.Console,
    query: []const u8,
};

pub fn search(allocator: Allocator, client: *std.http.Client, params: SearchParams) ![]domain.SearchResult {
    const encoded_query = try url_encoder.encodeQuery(allocator, params.query);
    defer allocator.free(encoded_query);

    const url = try std.fmt.allocPrint(
        allocator,
        "https://archive.org/advancedsearch.php?q={s}+subject%3A%28{s}%29+mediatype%3A%28software%29&output=json&rows=20&fl=identifier%2Ctitle",
        .{ encoded_query, params.console.searchSubject() },
    );
    defer allocator.free(url);

    const body = try http_client.get(allocator, client, .{ .url = url, .raw_uri = true });
    defer allocator.free(body);
    if (body.len == 0) return &.{};

    const parsed = try std.json.parseFromSlice(dto.SearchResponseDto, allocator, body, .{
        .ignore_unknown_fields = true,
    });
    defer parsed.deinit();

    const docs = parsed.value.response.docs;
    if (docs.len == 0) return &.{};

    const results = try allocator.alloc(domain.SearchResult, docs.len);
    for (docs, 0..) |doc, i| {
        results[i] = .{
            .identifier = try allocator.dupe(u8, doc.identifier),
            .title = try allocator.dupe(u8, doc.title orelse doc.identifier),
        };
    }

    return results;
}

pub fn getFiles(allocator: Allocator, client: *std.http.Client, identifier: []const u8) ![]domain.GameFile {
    const url = try std.fmt.allocPrint(allocator, "https://archive.org/metadata/{s}/files", .{identifier});
    defer allocator.free(url);

    const body = try http_client.get(allocator, client, .{ .url = url });
    defer allocator.free(body);

    const parsed = try std.json.parseFromSlice(dto.MetadataResponseDto, allocator, body, .{
        .ignore_unknown_fields = true,
    });
    defer parsed.deinit();

    var file_list: std.ArrayList(domain.GameFile) = .empty;
    defer file_list.deinit(allocator);

    for (parsed.value.result) |file| {
        if (domain.isRomFile(file.name)) {
            const size: ?u64 = if (file.size) |s| std.fmt.parseInt(u64, s, 10) catch null else null;
            try file_list.append(allocator, .{
                .name = try allocator.dupe(u8, file.name),
                .size = size,
            });
        }
    }

    return try file_list.toOwnedSlice(allocator);
}

pub fn buildDownloadUrl(allocator: Allocator, identifier: []const u8, filename: []const u8) ![]const u8 {
    const encoded = try url_encoder.encodePath(allocator, filename);
    defer allocator.free(encoded);
    return try std.fmt.allocPrint(allocator, "https://archive.org/download/{s}/{s}", .{ identifier, encoded });
}
