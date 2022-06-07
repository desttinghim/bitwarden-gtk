const std = @import("std");
const GTK = @import("gtk");
const c = GTK.c;
const gtk = GTK.gtk;

email_entry: gtk.Entry,
password_entry: gtk.Entry,
