const std = @import("std");

const fut = @cImport({
    @cInclude("blaster.h");
});

pub const Error = error{OutOfMemory};

pub const FutConfig = struct {
    ptr: *fut.futhark_context_config,

    pub fn init() Error!@This() {
        var ptr_opt: ?*fut.futhark_context_config = fut.futhark_context_config_new();
        if (ptr_opt) |ptr| {
            fut.futhark_context_config_set_logging(ptr, 1);
            return FutConfig{
                .ptr = ptr,
            };
        } else {
            return Error.OutOfMemory;
        }
    }

    pub fn deinit(self: @This()) void {
        fut.futhark_context_config_free(self.ptr);
    }
};

pub const FutContext = struct {
    ptr: *fut.futhark_context,

    pub fn init(cfg: FutConfig) Error!@This() {
        var ptr_opt: ?*fut.futhark_context = fut.futhark_context_new(cfg.ptr);
        if (ptr_opt) |ptr| {
            return FutContext{
                .ptr = ptr,
            };
        } else {
            return Error.OutOfMemory;
        }
    }

    pub fn deinit(self: @This()) void {
        fut.futhark_context_free(self.ptr);
    }

    pub fn next_guess(self: @This(), comptime word_size: usize, dictionary: []const *const [word_size]u8, possible: []const *const [word_size]u8) Error![word_size]u8 {
        const dictionary_packed: []u8 = try std.heap.c_allocator.alloc(u8, word_size * dictionary.len);
        defer std.heap.c_allocator.free(dictionary_packed);
        for(dictionary) |word, wi| {
            std.mem.copy(u8, dictionary_packed[(wi * word_size)..((wi + 1) * word_size)], word);
        }

        const dictionary_gpu: *fut.futhark_u8_2d =
            if(fut.futhark_new_u8_2d(self.ptr, dictionary_packed.ptr,  @intCast(i64, dictionary.len), word_size)) |ptr|
                ptr
            else
                return error.OutOfMemory;
        defer _ = fut.futhark_free_u8_2d(self.ptr, dictionary_gpu);

        const possible_packed: []u8 = try std.heap.c_allocator.alloc(u8, word_size * possible.len);
        defer std.heap.c_allocator.free(possible_packed);
        for(possible) |word, wi| {
            std.mem.copy(u8, possible_packed[(wi * word_size)..((wi + 1) * word_size)], word);
        }

        const possible_gpu: *fut.futhark_u8_2d =
            if(fut.futhark_new_u8_2d(self.ptr, possible_packed.ptr,  @intCast(i64, possible.len), word_size)) |ptr|
                ptr
            else
                return error.OutOfMemory;
        defer _ = fut.futhark_free_u8_2d(self.ptr, possible_gpu);

        var out_gpu: ?*fut.futhark_u8_1d = undefined;
        _ = fut.futhark_entry_next_guess(self.ptr, &out_gpu, dictionary_gpu, possible_gpu);
        defer _ = fut.futhark_free_u8_1d(self.ptr, out_gpu);

        var out: [word_size]u8 = undefined;
        _ = fut.futhark_values_u8_1d(self.ptr, out_gpu, &out);
        return out;
    }
};
