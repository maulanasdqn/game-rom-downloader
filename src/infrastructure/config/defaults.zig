const std = @import("std");

pub fn getDownloadDir(allocator: std.mem.Allocator) ![]u8 {
    const userprofile = std.process.getEnvVarOwned(allocator, "USERPROFILE") catch |err| switch (err) {
        error.EnvironmentVariableNotFound => return try allocator.dupe(u8, "Downloads"),
        else => return err,
    };
    defer allocator.free(userprofile);
    return try std.fmt.allocPrint(allocator, "{s}\\Downloads", .{userprofile});
}
