const std = @import("std");
const domain = @import("../domain/mod.zig");
const infra = @import("../infrastructure/mod.zig");

pub const Input = struct {
    allocator: std.mem.Allocator,
    client: *std.http.Client,
    identifier: []const u8,
    title: []const u8,
};

pub fn execute(input: Input) ![]domain.GameFile {
    if (isRomsfunUrl(input.identifier)) {
        return try romsfunSingleFile(input.allocator, input.title);
    }

    return try infra.api.archive_client.getFiles(input.allocator, input.client, input.identifier);
}

fn romsfunSingleFile(allocator: std.mem.Allocator, title: []const u8) ![]domain.GameFile {
    const files = try allocator.alloc(domain.GameFile, 1);
    files[0] = .{
        .name = try std.fmt.allocPrint(allocator, "{s}.zip", .{title}),
        .size = null,
    };
    return files;
}

fn isRomsfunUrl(identifier: []const u8) bool {
    return std.mem.startsWith(u8, identifier, "https://romsfun.com/");
}
