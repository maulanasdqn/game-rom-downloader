const std = @import("std");

pub const SearchResult = struct {
    identifier: []const u8,
    title: []const u8,

    pub fn free(self: SearchResult, allocator: std.mem.Allocator) void {
        allocator.free(self.identifier);
        allocator.free(self.title);
    }

    pub fn freeSlice(results: []const SearchResult, allocator: std.mem.Allocator) void {
        for (results) |r| r.free(allocator);
        allocator.free(results);
    }
};
