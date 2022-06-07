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

const LoginResponse = struct {
    success: bool,
    message: ?[]const u8 = null,
    data: ?Data = null,
};

const Data = struct {
    object: enum { message},
    noColor: bool,
    title: []const u8,
    message: ?[]const u8,
    raw: ?[]const u8 = null,
};

pub fn login(alloc: std.mem.Allocator, email: [:0]const u8, password: [:0]const u8) !LoginResponse {
    const out_bytes = try run_cmd(alloc, &[_][]const u8{ "bw", "login", email, password, "--nointeraction", "--response", "--raw" });
    defer alloc.free(out_bytes);

    std.debug.print("out_bytes: {s}\n", .{out_bytes});

    const parse_opt = std.json.ParseOptions{ .allocator = alloc };
    const res = try std.json.parse(LoginResponse, &std.json.TokenStream.init(out_bytes), parse_opt);
    // defer std.json.parseFree(LoginResponse, res, parse_opt);
    return res;
}

pub fn isLoggedIn(alloc: std.mem.Allocator) !bool {
    const out_bytes = try run_cmd(alloc, &[_][]const u8{ "bw", "login", "--check", "--nointeraction", "--response" });
    defer alloc.free(out_bytes);

    std.debug.print("response: {s}\n", .{out_bytes});

    const parse_opt = std.json.ParseOptions{ .allocator = alloc };
    const res = try std.json.parse(LoginResponse, &std.json.TokenStream.init(out_bytes), parse_opt);
    defer std.json.parseFree(LoginResponse, res, parse_opt);
    return res.success;
}

const StatusResponse = struct {
    success: bool,
    data: struct {
        object: enum { template },
        template: StatusData,
    },
};

const StatusData = struct {
    serverUrl: ?[]const u8,
    lastSync: ?[]const u8,
    userEmail: ?[]const u8 = null,
    userId: ?[]const u8 = null,
    status: enum { unlocked, locked, unauthenticated },
};

pub fn getStatus(alloc: std.mem.Allocator) !StatusResponse {
    const out_bytes = try run_cmd(alloc, &[_][]const u8{ "bw", "status", "--nointeraction", "--response" });
    defer alloc.free(out_bytes);

    std.debug.print("response: {s}\n", .{out_bytes});

    const parse_opt = std.json.ParseOptions{ .allocator = alloc };
    const res = try std.json.parse(StatusResponse, &std.json.TokenStream.init(out_bytes), parse_opt);
    defer std.json.parseFree(StatusResponse, res, parse_opt);

    // std.debug.print("status:\n\t{}\n", .{res});
    return res;
}
