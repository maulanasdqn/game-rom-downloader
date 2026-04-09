param(
    [Parameter(Position=0)]
    [ValidateSet("build", "run", "test", "clean", "release")]
    [string]$Command = "build"
)

switch ($Command) {
    "build"   { zig build }
    "run"     { zig build run }
    "test"    { zig build test }
    "clean"   { Remove-Item -Recurse -Force zig-out, .zig-cache -ErrorAction SilentlyContinue }
    "release" { zig build -Doptimize=ReleaseFast }
}
