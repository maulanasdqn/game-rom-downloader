const std = @import("std");
const lib = @import("game_rom_downloader");

const domain = lib.domain;
const app = lib.application;
const infra = lib.infrastructure;

const Terminal = infra.tui.Terminal;

pub fn main() !void {
    var gpa: std.heap.GeneralPurposeAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var client: std.http.Client = .{ .allocator = allocator };
    defer client.deinit();

    var term: Terminal = .{};
    try term.init();
    defer term.deinit();
    term.hideCursor();

    run(allocator, &client, &term) catch |err| switch (err) {
        error.UserCancelled, error.UserInterrupt => {
            term.clearScreen();
            term.showCursor();
            term.print("\n Goodbye!\n\n", .{});
            term.flush();
        },
        else => |e| {
            term.clearScreen();
            term.showCursor();
            term.print("\n\x1b[31m Error: {}\x1b[0m\n", .{e});
            term.print(" Press any key to exit.\n", .{});
            term.flush();
            _ = infra.tui.readKey(&term) catch {};
        },
    };
}

fn run(allocator: std.mem.Allocator, client: *std.http.Client, term: *Terminal) !void {
    const console = try infra.tui.console_screen.render(term);

    const query = try infra.tui.text_input_screen.render(term, allocator, .{
        .title = console.displayName(),
        .prompt = "Search: ",
    });
    defer allocator.free(query);

    showStatus(term, "Searching for \"{s}\" on {s}...", .{ query, console.displayName() });

    const results = try app.search_games.execute(.{
        .allocator = allocator,
        .client = client,
        .console = console,
        .query = query,
    });
    defer domain.SearchResult.freeSlice(results, allocator);

    if (results.len == 0) {
        try showEmptyAndWait(term, "No results found.");
        return;
    }

    const selected = try pickGame(allocator, term, query, console, results);
    const files = try loadFiles(allocator, client, term, selected);
    defer domain.GameFile.freeSlice(files, allocator);

    const file = try pickFile(allocator, term, files);
    const save_dir = try pickSaveDir(allocator, term);
    defer allocator.free(save_dir);

    term.clearScreen();
    term.print("\n", .{});
    term.flush();

    try app.download_game.execute(.{
        .allocator = allocator,
        .client = client,
        .identifier = selected.identifier,
        .title = selected.title,
        .filename = file.name,
        .save_dir = save_dir,
        .console = console,
        .term = term,
    });

    showComplete(allocator, term, save_dir, file.name);
    _ = try infra.tui.readKey(term);
}

fn pickGame(allocator: std.mem.Allocator, term: *Terminal, query: []const u8, console: domain.Console, results: []const domain.SearchResult) !domain.SearchResult {
    const titles = try allocator.alloc([]const u8, results.len);
    defer allocator.free(titles);
    for (results, 0..) |r, i| titles[i] = r.title;

    const header = try std.fmt.allocPrint(allocator, "Search results for \"{s}\" ({s})", .{ query, console.shortName() });
    defer allocator.free(header);

    return results[try infra.tui.list_screen.render(term, header, titles)];
}

fn loadFiles(allocator: std.mem.Allocator, client: *std.http.Client, term: *Terminal, selected: domain.SearchResult) ![]domain.GameFile {
    showStatus(term, "Fetching file list for \"{s}\"...", .{selected.title});
    return try app.fetch_files.execute(.{
        .allocator = allocator,
        .client = client,
        .identifier = selected.identifier,
        .title = selected.title,
    });
}

fn pickFile(allocator: std.mem.Allocator, term: *Terminal, files: []const domain.GameFile) !domain.GameFile {
    if (files.len == 0) {
        try showEmptyAndWait(term, "No downloadable ROM files found.");
        return error.NoResults;
    }
    if (files.len == 1) return files[0];

    const names = try allocator.alloc([]u8, files.len);
    defer { for (names) |n| allocator.free(n); allocator.free(names); }
    const ptrs = try allocator.alloc([]const u8, files.len);
    defer allocator.free(ptrs);

    for (files, 0..) |f, i| {
        names[i] = if (f.size) |s|
            try std.fmt.allocPrint(allocator, "{s} ({d:.1} MB)", .{ f.name, @as(f64, @floatFromInt(s)) / (1024.0 * 1024.0) })
        else
            try allocator.dupe(u8, f.name);
        ptrs[i] = names[i];
    }

    return files[try infra.tui.list_screen.render(term, "Select file to download", ptrs)];
}

fn pickSaveDir(allocator: std.mem.Allocator, term: *Terminal) ![]u8 {
    const default_dir = try infra.config.defaults.getDownloadDir(allocator);
    defer allocator.free(default_dir);
    return try infra.tui.text_input_screen.render(term, allocator, .{
        .title = "Save to folder:",
        .prefill = default_dir,
    });
}

fn showStatus(term: *Terminal, comptime fmt: []const u8, args: anytype) void {
    term.clearScreen();
    term.print("\n\x1b[33m " ++ fmt ++ "\x1b[0m\n", args);
    term.flush();
}

fn showEmptyAndWait(term: *Terminal, msg: []const u8) !void {
    term.print("\n\x1b[31m {s} Press any key to exit.\x1b[0m\n", .{msg});
    term.flush();
    _ = try infra.tui.readKey(term);
}

fn showComplete(allocator: std.mem.Allocator, term: *Terminal, save_dir: []const u8, filename: []const u8) void {
    term.showCursor();
    const path = std.fmt.allocPrint(allocator, "{s}/{s}", .{ save_dir, filename }) catch filename;
    defer if (path.ptr != filename.ptr) allocator.free(path);
    term.print("\n\n\x1b[32m Download complete: {s}\x1b[0m\n", .{path});
    term.print(" Press any key to exit.\n", .{});
    term.flush();
}
