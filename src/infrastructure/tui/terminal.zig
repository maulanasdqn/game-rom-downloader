const std = @import("std");

const Writer = std.Io.Writer;

const ENABLE_ECHO_INPUT: u32 = 0x0004;
const ENABLE_LINE_INPUT: u32 = 0x0002;
const ENABLE_VIRTUAL_TERMINAL_INPUT: u32 = 0x0200;
const ENABLE_VIRTUAL_TERMINAL_PROCESSING: u32 = 0x0004;
const STD_INPUT_HANDLE: u32 = @bitCast(@as(i32, -10));
const STD_OUTPUT_HANDLE: u32 = @bitCast(@as(i32, -11));

const HANDLE = std.os.windows.HANDLE;
const BOOL = std.os.windows.BOOL;
const DWORD = std.os.windows.DWORD;

extern "kernel32" fn GetStdHandle(nStdHandle: DWORD) callconv(.winapi) ?HANDLE;
extern "kernel32" fn GetConsoleMode(hConsoleHandle: HANDLE, lpMode: *DWORD) callconv(.winapi) BOOL;
extern "kernel32" fn SetConsoleMode(hConsoleHandle: HANDLE, dwMode: DWORD) callconv(.winapi) BOOL;
pub extern "kernel32" fn ReadConsoleA(
    hConsoleInput: HANDLE,
    lpBuffer: [*]u8,
    nNumberOfCharsToRead: DWORD,
    lpNumberOfCharsRead: *DWORD,
    pInputControl: ?*anyopaque,
) callconv(.winapi) BOOL;

pub const Terminal = struct {
    original_stdin_mode: u32 = 0,
    original_stdout_mode: u32 = 0,
    stdin_handle: ?HANDLE = null,
    stdout_handle: ?HANDLE = null,
    stdout_buf: [4096]u8 = undefined,
    stdout_writer: ?std.fs.File.Writer = null,
    stdout: ?*Writer = null,
    is_initialized: bool = false,

    pub fn init(self: *Terminal) !void {
        const stdin_h = GetStdHandle(STD_INPUT_HANDLE) orelse return error.StdinNotAvailable;
        const stdout_h = GetStdHandle(STD_OUTPUT_HANDLE) orelse return error.StdoutNotAvailable;

        self.stdin_handle = stdin_h;
        self.stdout_handle = stdout_h;

        if (GetConsoleMode(stdin_h, &self.original_stdin_mode) == 0) return error.GetConsoleModeFailedStdin;
        if (GetConsoleMode(stdout_h, &self.original_stdout_mode) == 0) return error.GetConsoleModeFailedStdout;

        const new_stdin = (self.original_stdin_mode & ~(ENABLE_ECHO_INPUT | ENABLE_LINE_INPUT)) | ENABLE_VIRTUAL_TERMINAL_INPUT;
        if (SetConsoleMode(stdin_h, new_stdin) == 0) return error.SetConsoleModeFailedStdin;

        const new_stdout = self.original_stdout_mode | ENABLE_VIRTUAL_TERMINAL_PROCESSING;
        if (SetConsoleMode(stdout_h, new_stdout) == 0) return error.SetConsoleModeFailedStdout;

        self.stdout_writer = std.fs.File.stdout().writer(&self.stdout_buf);
        self.stdout = &self.stdout_writer.?.interface;
        self.is_initialized = true;
    }

    pub fn deinit(self: *Terminal) void {
        if (!self.is_initialized) return;
        if (self.stdout) |out| {
            out.print("\x1b[?25h\x1b[0m", .{}) catch {};
            out.flush() catch {};
        }
        if (self.stdin_handle) |h| _ = SetConsoleMode(h, self.original_stdin_mode);
        if (self.stdout_handle) |h| _ = SetConsoleMode(h, self.original_stdout_mode);
    }

    pub fn write(self: *Terminal, s: []const u8) void {
        if (self.stdout) |out| out.writeAll(s) catch {};
    }

    pub fn print(self: *Terminal, comptime fmt: []const u8, args: anytype) void {
        if (self.stdout) |out| out.print(fmt, args) catch {};
    }

    pub fn flush(self: *Terminal) void {
        if (self.stdout) |out| out.flush() catch {};
    }

    pub fn clearScreen(self: *Terminal) void {
        self.write("\x1b[2J\x1b[H");
        self.flush();
    }

    pub fn hideCursor(self: *Terminal) void {
        self.write("\x1b[?25l");
        self.flush();
    }

    pub fn showCursor(self: *Terminal) void {
        self.write("\x1b[?25h");
        self.flush();
    }
};
