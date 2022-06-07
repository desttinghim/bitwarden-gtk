const std = @import("std");
pub const c = @import("c.zig");

/// The Schema libsecret uses to store and lookup our passwords
const Schema = c.SecretSchema{
    .name = "name.desttinghim.bitwardenGTK",
    .flags = c.SECRET_SCHEMA_NONE,
    .attributes = .{
        .{ .name = "email", .type = c.SECRET_SCHEMA_ATTRIBUTE_INTEGER },
        // .{ .name = "id", .type = c.SECRET_SCHEMA_ATTRIBUTE_STRING },
    } ++ .{
        // Fill up the rest of the space in the struct with NULL to
        // satisfy zig
        .{ .name = "NULL", .type = 0 }
    } ** 31,
    // There's no documentation on these, but zig needs them filled with something
    .reserved = undefined,
    .reserved1 = undefined,
    .reserved2 = undefined,
    .reserved3 = undefined,
    .reserved4 = undefined,
    .reserved5 = undefined,
    .reserved6 = undefined,
    .reserved7 = undefined,
};

/// Mirrors the schema, but is used for passing around the user info
const UserInfo = struct {
    email: []const u8,
};

// void
// secret_password_store (
//   const SecretSchema* schema,
//   const gchar* collection,
//   const gchar* label,
//   const gchar* password,
//   GCancellable* cancellable,
//   GAsyncReadyCallback callback,
//   gpointer user_data,
//   ...
// )

/// Store a password asynchronously
pub fn storePassword(email: []const u8, password: []const u8) void {
    const collection = c.SECRET_COLLECTION_DEFAULT;
    const label = "Label";
    const user_data: ?*anyopaque = null;
    c.secret_password_store(
        &Schema,
        collection,
        label,
        password.ptr,
        null, // cancellable
        onPasswordStored,
        user_data,
        // Var args
        "email",
        email.ptr,
        @as(?*anyopaque, null),
    );
}

pub fn onPasswordStored(source: ?*c.GObject, result: ?*c.GAsyncResult, user_data: c.gpointer) callconv(.C) void {
    var err: ?*c.GError = null;

    _ = source;
    _ = result;
    _ = user_data;

    const stored = c.secret_password_store_finish(result, &err);
    _ = stored;
    if (err != null) {
        std.debug.print("password store error!\n", .{});
        c.g_error_free(err);
    } else {
        std.debug.print("password stored\n", .{});
    }
}

// void
// secret_password_lookup (
//   const SecretSchema* schema,
//   GCancellable* cancellable,
//   GAsyncReadyCallback callback,
//   gpointer user_data,
//   ...
// )

pub fn lookupPassword(email: []const u8) void {
    const user_data: ?*anyopaque = null;
    c.secret_password_lookup(
        &Schema,
        null, // cancellable
        onPasswordLookup,
        user_data,
        // Var args
        "email",
        email.ptr,
        @as(?*anyopaque, null),
    );
}

fn onPasswordLookup(source: ?*c.GObject, result: ?*c.GAsyncResult, user_data: c.gpointer) callconv(.C) void {
    var err: ?*c.GError = null;

    _ = source;
    _ = result;
    _ = user_data;

    const password: ?[*:0]c.gchar = c.secret_password_lookup_finish(result, &err);
    if (err != null) {
        std.debug.print("password retrieve error!\n", .{});
        c.g_error_free(err);
    } else if (password == null) {
        std.debug.print("no matching password found!");
    } else {
        std.debug.print("password retrieved\n", .{});
        c.secret_password_free(password);
    }
}

pub fn clearPassword(email: []const u8) void {
    const user_data: ?*anyopaque = null;
    c.secret_password_clear(
        &Schema,
        null,   // cancellable
        onPasswordCleared,
        user_data,
        // Var args
        "email",
        email.ptr,
        @as(?*anyopaque, null),
    );
}

fn onPasswordCleared(source: ?*c.GObject, result: ?*c.GAsyncResult, user_data: c.gpointer) void {
    var err: ?*c.GError = null;

    _ = source;
    _ = result;
    _ = user_data;

    const removed: bool = c.secret_password_clear_finish(result, &err);
    if (err != null) {
        std.debug.print("password clear error!\n", .{});
        c.g_error_free(err);
    } else if (!removed) {
        std.debug.print("password not cleared.\n", .{});
    } else {
        std.debug.print("password cleared!\n", .{});
    }
}
