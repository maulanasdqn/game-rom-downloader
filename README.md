# Game ROM Downloader

A terminal-based game ROM downloader for PlayStation 1 and PlayStation 2.
Built in Zig with zero external dependencies.

Searches multiple sources (Archive.org, romsfun.com), presents results in an
interactive TUI, and downloads selected ROMs with a live progress bar.

## Features

- PS1 and PS2 ROM search and download
- Dual-source search: Archive.org (primary) + romsfun.com (fallback)
- Interactive terminal UI with arrow-key navigation
- Scrollable search results with highlight selection
- Download progress bar with speed and percentage
- Configurable save directory (defaults to Downloads folder)
- All downloads sourced from Archive.org

## Requirements

- [Zig](https://ziglang.org/download/) 0.15.2 or later
- Windows 10/11 (uses Windows Console API for TUI)
- Internet connection

## Build

```
zig build
```

Or use the provided scripts:

```powershell
# PowerShell
.\build.ps1 build
.\build.ps1 release    # optimized build
```

```bash
# Make (if installed)
make build
make release
```

## Run

```
zig build run
```

Or run the compiled binary directly:

```
./zig-out/bin/game_rom_downloader.exe
```

## Usage

1. Select a console (PS1 or PS2) using arrow keys
2. Type a game name and press Enter to search
3. Browse results from Archive.org and romsfun.com
4. Select a game, then select a file if multiple are available
5. Confirm or change the save directory
6. Wait for the download to complete

Results tagged with `[romsfun]` were found via romsfun.com. These are
automatically resolved and downloaded through Archive.org.

### Controls

| Key        | Action                  |
|------------|-------------------------|
| Up/Down    | Navigate lists          |
| Enter      | Confirm selection       |
| Escape     | Go back / Cancel        |
| Backspace  | Delete text input       |

## Architecture

The project follows Clean Architecture with three layers:

```
src/
├── main.zig                         Entry point
├── root.zig                         Library re-exports
│
├── domain/                          Core entities (no dependencies)
│   ├── console.zig                  Console enum (PS1, PS2)
│   ├── search_result.zig            SearchResult entity
│   ├── game_file.zig                GameFile entity
│   └── rom_filter.zig               ROM file extension matching
│
├── application/                     Use cases (one per file)
│   ├── search_games.zig             Search both sources, merge results
│   ├── fetch_files.zig              Get file list for a game
│   └── download_game.zig            Resolve URL and download
│
└── infrastructure/                  External integrations
    ├── api/
    │   ├── archive_client.zig       Archive.org search + metadata API
    │   ├── romsfun_client.zig       romsfun.com HTML scraping
    │   ├── romsfun_parser.zig       HTML parsing for romsfun pages
    │   ├── http_client.zig          Generic HTTP GET helper
    │   ├── url_encoder.zig          URL encoding (query + path)
    │   └── dto.zig                  JSON response DTOs
    ├── tui/
    │   ├── terminal.zig             Windows console raw mode
    │   ├── input.zig                Keyboard input handling
    │   ├── console_screen.zig       Console selection screen
    │   ├── text_input_screen.zig    Text input screen
    │   ├── list_screen.zig          Scrollable list screen
    │   ├── progress_screen.zig      Download progress bar
    │   └── format.zig               Human-readable file sizes
    ├── download/
    │   └── file_downloader.zig      Streaming download with progress
    └── config/
        └── defaults.zig             Default download directory
```

### Design decisions

- **Domain layer** has no imports from infrastructure or application.
  Contains only pure data types and logic.
- **Application layer** orchestrates use cases. Each file is a single
  use case with an `Input` struct and an `execute` function.
- **Infrastructure layer** handles all I/O: HTTP requests, terminal
  rendering, file system access, and configuration.
- **DTOs** are used for all function parameters with 3+ fields.
- **No external dependencies.** Everything uses the Zig standard library.
- **Max 200 lines per file.** Single responsibility per module.

### How sources work

**Archive.org** is the primary source. It provides both search (via the
Advanced Search API) and direct file downloads. Search queries use
full-text matching with subject and mediatype filters.

**romsfun.com** is a search-only fallback. Its results appear tagged with
`[romsfun]` in the list. When selected, the application extracts the game
title, searches Archive.org for a match, and downloads from there.
romsfun's CDN blocks non-browser downloads, so it cannot be used as a
direct download source.

## License

This project is for personal and educational use.
Respect the copyright laws in your jurisdiction.
