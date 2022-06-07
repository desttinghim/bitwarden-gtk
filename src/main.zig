const std = @import("std");
const GTK = @import("gtk");
const c = GTK.c;
const gtk = GTK.gtk;

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
}

fn activate(app: *c.GtkApplication) void {
    const window = gtk.ApplicationWindow.new(app).as_window();
    window.set_title("Example Program");
    window.set_default_size(640, 480);
    window.as_widget().show_all();
}

test "basic test" {
    try std.testing.expectEqual(10, 3 + 7);
}
