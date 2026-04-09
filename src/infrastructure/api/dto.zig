pub const SearchResponseDto = struct {
    response: struct {
        numFound: i64 = 0,
        docs: []const DocDto = &.{},
    },
};

pub const DocDto = struct {
    identifier: []const u8,
    title: ?[]const u8 = null,
};

pub const MetadataResponseDto = struct {
    result: []const FileEntryDto = &.{},
};

pub const FileEntryDto = struct {
    name: []const u8,
    size: ?[]const u8 = null,
};
