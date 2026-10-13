const std = @import("std");
const utils = @import("utils");
const sdl = @import("sdl3");

test "test1" {
    var allocator = std.heap.DebugAllocator(.{}).init;
    const gpa = allocator.allocator();

    defer sdl.shutdown();

    const flags = sdl.InitFlags{ .video = true };
    try sdl.init(flags);
    defer sdl.quit(flags);

    const window = try sdl.video.Window.init("tests", 400, 400, .{});
    defer window.deinit();

    const surface = try window.getSurface();
    const pixels = surface.getPixels().?;

    const buffer = utils.Buffer(u8, 4).from(400, 400, pixels);
    // defer buffer.deinit(gpa);

    const depth = try utils.Buffer(f32, 1).init(gpa, 100, 100);
    defer depth.deinit(gpa);

    for (100..300) |x| {
        for (100..300) |y| {
            buffer.setPos(x, y, .{ 0, 0, 255, 255 });
        }
    }

    var running = true;
    while (running) {
        // for (0..buffer.values.len / 4) |i| {
        //     const index = i * 4;

        //     pixels[index] = buffer.values[index + 2];
        //     pixels[index + 1] = buffer.values[index + 1];
        //     pixels[index + 2] = buffer.values[index];
        //     pixels[index + 3] = buffer.values[index + 3];
        // }

        try window.updateSurface();

        while (sdl.events.poll()) |event| {
            switch (event) {
                .quit => running = false,
                .terminating => running = false,
                else => {},
            }
        }
    }
}
