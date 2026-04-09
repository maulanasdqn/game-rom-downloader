pub const Console = enum {
    ps1,
    ps2,

    pub fn displayName(self: Console) []const u8 {
        return switch (self) {
            .ps1 => "PlayStation 1",
            .ps2 => "PlayStation 2",
        };
    }

    pub fn shortName(self: Console) []const u8 {
        return switch (self) {
            .ps1 => "PS1",
            .ps2 => "PS2",
        };
    }

    pub fn searchSubject(self: Console) []const u8 {
        return switch (self) {
            .ps1 => "playstation",
            .ps2 => "playstation+2",
        };
    }
};
