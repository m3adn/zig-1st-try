const std = @import("std");

pub fn main() !void {
    const addr = try std.net.Address.parseIp("127.0.0.1", 8080);
    var listener = try std.net.Address.listen(addr, .{ .reuse_address = true });
    defer listener.deinit();

    var buf: [65535]u8 = undefined;
    var count: u64 = 0;

    while (true) {
        const conn = try listener.accept();
        var server = std.http.Server.init(conn, &buf);

        // Use a flag to count only once per connection.
        var counted = false;

        while (server.state == .ready) {
            var request = server.receiveHead() catch |err| switch (err) {
                std.http.Server.ReceiveHeadError.HttpConnectionClosing => break,
                else => return err,
            };

            _ = try request.reader();

            if (!counted) {
                // Increment count once for this connection.
                counted = true;
                count += 1;
            }

            var text_buffer: [128]u8 = undefined;
            const response_body = try std.fmt.bufPrintZ(&text_buffer, "Hello http.std! You are connection #%{}\n", .{count});
            try request.respond(response_body, std.http.Server.Request.RespondOptions{});
        }
        conn.stream.close();
    }
}
