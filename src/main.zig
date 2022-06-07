const std = @import("std");
const GTK = @import("gtk");
const c = GTK.c;
const gtk = GTK.gtk;

var login: Login = undefined;
var gpa = std.heap.GeneralPurposeAllocator(.{}){};

fn submit_handler() void {
    const alloc = gpa.allocator();

    const email = login.email_entry.get_text(alloc) orelse return;
    defer alloc.free(email);

    const password = login.password_entry.get_text(alloc) orelse return;
    defer alloc.free(password);

    std.debug.print("email: {s}\tpass: {s}\n", .{email, password});
}

const Login = struct {
    email_entry: gtk.Entry,
    password_entry: gtk.Entry,
};

pub fn main() anyerror!void {
    const app = c.gtk_application_new("org.gtk.example", c.G_APPLICATION_FLAGS_NONE) orelse @panic("null app :(");
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
        if(w.to_window()) |window| {
            window.set_decorated(false);
        }
    }
    if (builder.get_widget("ok_button")) |w| {
        if(w.to_button()) |b| {
            b.connect_clicked(@ptrCast(c.GCallback, submit_handler), null);
        }
    }
    if (builder.get_widget("cancel_button")) |w| {
        if(w.to_button()) |b| {
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

    c.gtk_main();
}
