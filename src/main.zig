const std = @import("std");
const GTK = @import("gtk");
const c = GTK.c;
const gtk = GTK.gtk;

const secret = @import("secret.zig");
const Bitwarden = @import("bw-cli.zig");

const Login = @import("Login.zig");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
var login: Login = undefined;
/// Stores the session token
var session: ?[]const u8 = null;

pub fn main() anyerror!void {
    const app = c.gtk_application_new("name.desttinghim.bitwardenGTK", c.G_APPLICATION_FLAGS_NONE) orelse @panic("null app :(");
    defer c.g_object_unref(app);

    _ = c.g_signal_connect_data(
        app,
        "activate",
        @ptrCast(c.GCallback, activate),
        null,
        null,
        c.G_CONNECT_AFTER,
    );
    _ = c.g_application_run(@ptrCast(*c.GApplication, app), 0, null);

    std.debug.print("main finished\n", .{});
}

fn activate(app: *c.GtkApplication) void {
    activate_impl(app) catch |e| {
        std.debug.print("error: {s}\n", .{e});
        return;
    };
}

fn activate_impl(app: *c.GtkApplication) !void {
    const builder = gtk.Builder.new();
    try builder.add_from_string(@embedFile("example.glade"));
    builder.set_application(app);
    if (builder.get_widget("window")) |w| {
        w.show_all();
        w.connect("delete-event", @ptrCast(c.GCallback, c.gtk_main_quit), null);
        if (w.to_window()) |window| {
            window.set_decorated(false);
        }
    }
    if (builder.get_widget("ok_button")) |w| {
        if (w.to_button()) |b| {
            b.connect_clicked(@ptrCast(c.GCallback, submit_handler), null);
        }
    }
    if (builder.get_widget("cancel_button")) |w| {
        if (w.to_button()) |b| {
            b.connect_clicked(@ptrCast(c.GCallback, c.gtk_main_quit), null);
        }
    }

    const email_widget = builder.get_widget("email_entry") orelse return error.NoEmailEntry;
    const email_entry = email_widget.to_entry() orelse return error.InvalidEmailEntry;

    const password_widget = builder.get_widget("password_entry") orelse return error.NoPasswordEntry;
    const password_entry = password_widget.to_entry() orelse return error.InvalidPasswordEntry;

    login = .{
        .email_entry = email_entry,
        .password_entry = password_entry,
    };

    const stack_widget = builder.get_widget("login_stack") orelse return error.NoLoginStack;
    const stack = stack_widget.to_stack() orelse return error.InvalidLoginStack;

    const login_screen = stack.get_child_by_name("login_screen") orelse return error.NoLoginScreen;
    const home_screen = stack.get_child_by_name("home_screen") orelse return error.NoHomeScreen;

    const stat = try Bitwarden.getStatus(gpa.allocator());
    if (stat.data.template.status == .unlocked) {
        stack.set_visible_child(home_screen);
    } else if (stat.data.template.status == .unauthenticated){
        stack.set_visible_child(login_screen);
    } else {
        std.debug.print("locked: {}\n", .{stat});
        stack.set_visible_child(login_screen);
    }

    c.gtk_main();
}

fn submit_handler() void {
    submit_handler_impl() catch |e| {
        std.debug.print("error: {s}\n", .{e});
        return;
    };
}

fn submit_handler_impl() !void {
    const alloc = gpa.allocator();

    const email = login.email_entry.get_text(alloc) orelse return;
    defer alloc.free(email);

    const password = login.password_entry.get_text(alloc) orelse return;
    defer alloc.free(password);

    const res = try Bitwarden.login(alloc, email, password);
    std.debug.print("response: {}\n", .{res});

    if (res.data) |data| {
        session = data.raw;

        secret.storePassword(email, password);
    }
}
