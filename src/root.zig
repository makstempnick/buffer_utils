const std = @import("std");
const Allocator = std.mem.Allocator;

/// Represents a 2D buffer of values.
/// chunk_size defines the amount of continuous values that should be treated as one.
pub fn Buffer(T: type, chunk_size: usize) type {
    if (chunk_size == 0)
        @compileError("chunk_size must be at least 1.");

    const chunk_type = if (chunk_size == 1) T else [chunk_size]T;

    return struct {
        const Self = @This();

        width: usize,
        height: usize,
        values: []T,

        /// Creates a buffer with its values `undefined`
        pub fn init(gpa: Allocator, width: usize, height: usize) !Self {
            const values = try gpa.alloc(T, width * height * chunk_size);
            return .{ .width = width, .height = height, .values = values };
        }

        /// Creates a buffer from a slice of values.
        pub fn from(width: usize, height: usize, values: []T) Self {
            return .{ .width = width, .height = height, .values = values };
        }

        /// Frees the memory.
        /// This should only be used on a Buffer that allocated its own memory.
        pub fn deinit(self: *const Self, gpa: Allocator) void {
            gpa.free(self.values);
        }

        /// Clears buffer with the given value.
        pub fn clear(self: *const Self, value: chunk_type) void {
            if (chunk_size == 1) {
                @memset(self.values[0..], value);
            } else {
                for (0..self.values.len / chunk_size) |i| {
                    for (0..chunk_size) |j|
                        self.values[i * chunk_size + j] = value[j];
                }
            }
        }

        /// Returns the value on a given position on the buffer.
        pub fn getPos(self: *const Self, x: usize, y: usize) chunk_type {
            const index = idx(x, y, self.width) * chunk_size;

            if (chunk_size == 1)
                return self.values[index];

            var value: chunk_type = undefined;

            for (0..chunk_size) |i|
                value[i] = self.values[index + i];

            return value;
        }

        /// Sets the value on a given position on the buffer.
        pub fn setPos(self: *const Self, x: usize, y: usize, value: chunk_type) void {
            const index = idx(x, y, self.width) * chunk_size;

            if (chunk_size == 1) {
                self.values[index] = value;
            } else {
                for (0..chunk_size) |i|
                    self.values[index + i] = value[i];
            }
        }

        /// Returns the value on a given width and height percentage of the buffer.
        pub fn getPerc(self: *const Self, perc_x: f32, perc_y: f32) chunk_type {
            const x: usize = @trunc(@as(f32, @floatFromInt(self.width - 1)) * perc_x);
            const y: usize = @trunc(@as(f32, @floatFromInt(self.height - 1)) * perc_y);

            return self.getPos(x, y);
        }

        /// Sets the value on a given width and height percentage of the buffer.
        pub fn setPerc(self: *const Self, perc_x: f32, perc_y: f32, value: chunk_type) void {
            const x: usize = @trunc(@as(f32, @floatFromInt(self.width - 1)) * perc_x);
            const y: usize = @trunc(@as(f32, @floatFromInt(self.height - 1)) * perc_y);

            return self.setPos(x, y, value);
        }

        /// Returns a new version of the buffer with content scaled to given size.
        pub fn scale(self: *const Self, gpa: Allocator, width: usize, height: usize) !Self {
            var new_buffer = try Buffer(T, chunk_size).init(gpa, width, height);

            for (0..height) |y| {
                for (0..width) |x| {
                    const perc_x = @as(f32, @floatFromInt(x)) / @as(f32, @floatFromInt(width - 1));
                    const perc_y = @as(f32, @floatFromInt(y)) / @as(f32, @floatFromInt(height - 1));

                    const value = self.getPerc(perc_x, perc_y);

                    new_buffer.setPos(x, y, value);
                }
            }

            return new_buffer;
        }
    };
}
pub fn idx(x: usize, y: usize, width: usize) usize {
    return y * width + x;
}
pub fn xy(i: usize, width: usize) [2]usize {
    const x = i / width;
    const y = i % width;

    return [_]usize{ x, y };
}
