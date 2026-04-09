const std = @import("std");

pub fn encodeQuery(allocator: std.mem.Allocator, input: []const u8) ![]u8 {
    return encodeInternal(allocator, input, '+');
}

pub fn encodePath(allocator: std.mem.Allocator, input: []const u8) ![]u8 {
    return encodeInternal(allocator, input, null);
}

fn encodeInternal(allocator: std.mem.Allocator, input: []const u8, space_char: ?u8) ![]u8 {
    var result: std.ArrayList(u8) = .empty;
    defer result.deinit(allocator);

    for (input) |c| {
        if (c == ' ') {
            if (space_char) |sc| {
                try result.append(allocator, sc);
            } else {
                try result.appendSlice(allocator, "%20");
            }
        } else if (std.ascii.isAlphanumeric(c) or c == '-' or c == '_' or c == '.' or c == '~') {
            try result.append(allocator, c);
        } else {
            const hex = "0123456789ABCDEF";
            try result.append(allocator, '%');
            try result.append(allocator, hex[c >> 4]);
            try result.append(allocator, hex[c & 0x0F]);
        }
    }

    return try result.toOwnedSlice(allocator);
}
