const std = @import("std");

fn run_cmd(alloc: std.mem.Allocator, cmd: []const []const u8) ![]u8 {
    var child_process = std.ChildProcess.init(
        cmd,
        alloc,
    );
    child_process.stdout_behavior = .Pipe;

    try child_process.spawn();

    const out_bytes = try child_process.stdout.?.reader().readAllAlloc(alloc, std.math.maxInt(usize));
    switch (try child_process.wait()) {
        .Exited => |code| if (code == 0) {
            return out_bytes;
        },
        else => return error.NonZeroExitCode,
    }
    return out_bytes;
}

const LoginResponse = union(enum) {
    Success: struct {
        success: bool,
        data: ?Data,
    },
    Failure: struct {
        success: bool,
        message: []const u8,
    },
};

const Data = struct {
    noColor: bool,
    object: enum { message },
    title: []const u8,
    message: ?[]const u8,
};

// pub fn login(alloc: std.mem.Allocator, email: [:0]u8, password: [:0]u8) !bool {
//     const out_bytes = run_cmd(&[_][]const u8{ "bw", "login", "--check", "--nointeraction", "--response" });
//     defer alloc.free(out_bytes);
// }

pub fn isLoggedIn(alloc: std.mem.Allocator) !bool {
    const out_bytes = try run_cmd(alloc, &[_][]const u8{ "bw", "login", "--check", "--nointeraction", "--response" });
    defer alloc.free(out_bytes);

    std.debug.print("response: {s}", .{out_bytes});

    const parse_opt = std.json.ParseOptions{ .allocator = alloc };
    const res = try std.json.parse(LoginResponse, &std.json.TokenStream.init(out_bytes), parse_opt);
    defer std.json.parseFree(LoginResponse, res, parse_opt);
    switch (res) {
        .Success => |succ| return succ.success,
        .Failure => |fail| return fail.success,
    }
}

const StatusResponse = struct {
    serverUrl: []const u8,
    lastSync: ?[]const u8,
    userEmail: ?[]const u8,
    userId: ?[]const u8,
    status: enum { unlocked, locked, unauthenticated },
};

pub fn getStatus(alloc: std.mem.Allocator) !void {
    const out_bytes = try run_cmd(alloc, &[_][]const u8{ "bw", "status", "--nointeraction", "--response" });
    defer alloc.free(out_bytes);

    std.debug.print("response: {s}", .{out_bytes});

    const parse_opt = std.json.ParseOptions{ .allocator = alloc };
    const res = try std.json.parse(StatusResponse, &std.json.TokenStream.init(out_bytes), parse_opt);
    defer std.json.parseFree(StatusResponse, res, parse_opt);

    std.debug.print("status:\n\t{}", .{res});
}
