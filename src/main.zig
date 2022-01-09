const std = @import("std");

const bl = @import("blaster/blaster.zig");

const dictionary: [8938]*const [5]u8 = blk: {
    @setEvalBranchQuota(10_000);
    const full_string = @embedFile("./wordl5.txt");
    var res: [8938]*const [5]u8 = undefined;
    for(res) |*ap, i| {
        ap.* = full_string[(i * 6)..(((i + 1) * 6) - 1)];
    }
    break :blk res;
};

pub fn main() anyerror!void {
    const cfg = try bl.FutConfig.init();
    const ctx = try bl.FutContext.init(cfg);

    const next: [5]u8 = try ctx.next_guess(5, &dictionary, &dictionary);

    std.debug.print("{s}", .{ &next });
}
