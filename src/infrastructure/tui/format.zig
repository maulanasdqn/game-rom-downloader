const std = @import("std");

pub const SizeBuf = struct {
    data: [12]u8 = .{' '} ** 12,
    len: usize = 0,

    pub fn slice(self: *const SizeBuf) []const u8 {
        return self.data[0..self.len];
    }
};

pub fn size(bytes: u64) SizeBuf {
    var result: SizeBuf = .{};

    const s = if (bytes >= 1024 * 1024 * 1024)
        std.fmt.bufPrint(&result.data, "{d:.1} GB", .{asF64(bytes) / (1024.0 * 1024.0 * 1024.0)})
    else if (bytes >= 1024 * 1024)
        std.fmt.bufPrint(&result.data, "{d:.1} MB", .{asF64(bytes) / (1024.0 * 1024.0)})
    else if (bytes >= 1024)
        std.fmt.bufPrint(&result.data, "{d:.1} KB", .{asF64(bytes) / 1024.0})
    else
        std.fmt.bufPrint(&result.data, "{d} B", .{bytes});

    result.len = (s catch "?").len;
    return result;
}

fn asF64(value: u64) f64 {
    return @floatFromInt(value);
}
