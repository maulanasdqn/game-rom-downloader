const std = @import("std");
const domain = @import("../domain/mod.zig");
const infra = @import("../infrastructure/mod.zig");

pub const Input = struct {
    allocator: std.mem.Allocator,
    client: *std.http.Client,
    console: domain.Console,
    query: []const u8,
};

pub fn execute(input: Input) ![]domain.SearchResult {
    const params_archive = infra.api.archive_client.SearchParams{
        .console = input.console,
        .query = input.query,
    };
    const params_romsfun = infra.api.romsfun_client.SearchParams{
        .console = input.console,
        .query = input.query,
    };

    const archive = infra.api.archive_client.search(input.allocator, input.client, params_archive) catch null;
    const romsfun = infra.api.romsfun_client.search(input.allocator, input.client, params_romsfun) catch null;

    const a_len = if (archive) |a| a.len else 0;
    const r_len = if (romsfun) |r| r.len else 0;

    if (a_len == 0 and r_len == 0) return try input.allocator.alloc(domain.SearchResult, 0);

    const combined = try input.allocator.alloc(domain.SearchResult, a_len + r_len);
    if (archive) |a| @memcpy(combined[0..a_len], a);
    if (romsfun) |r| @memcpy(combined[a_len..], r);

    if (archive) |a| input.allocator.free(a);
    if (romsfun) |r| input.allocator.free(r);

    return combined;
}
