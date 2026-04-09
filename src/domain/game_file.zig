const std = @import("std");

pub const GameFile = struct {
    name: []const u8,
    size: ?u64,

    pub fn free(self: GameFile, allocator: std.mem.Allocator) void {
        allocator.free(self.name);
    }

    pub fn freeSlice(files: []const GameFile, allocator: std.mem.Allocator) void {
        for (files) |f| f.free(allocator);
        allocator.free(files);
    }
};
