const std = @import("std");

const extensions = [_][]const u8{
    ".bin", ".cue", ".iso", ".img",
    ".chd", ".zip", ".7z",  ".rar",
    ".pbp",
};

pub fn isRomFile(name: []const u8) bool {
    for (extensions) |ext| {
        if (std.ascii.endsWithIgnoreCase(name, ext)) return true;
    }
    return false;
}
