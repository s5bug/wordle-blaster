const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    const exe = b.addExecutable("wordle-blaster", "src/main.zig");
    exe.setTarget(target);
    exe.setBuildMode(mode);

    exe.c_std = .C99;
    exe.addIncludeDir("include");

    const target_triple_str = target.linuxTriple(b.allocator) catch |err| {
        std.log.err("{} error while trying to stringify the target triple", .{err});
        std.os.exit(1);
    };
    const lib_dir = std.fs.path.join(b.allocator, &[_][]const u8{ "lib", target_triple_str }) catch |err| {
        std.log.err("{} error while trying to render library path", .{err});
        std.os.exit(1);
    };
    exe.addLibPath(lib_dir);

    exe.linkLibC();

    if (target.isDarwin()) {
        exe.addFrameworkDir("/Library/Frameworks");
        exe.addFrameworkDir("~/Library/Frameworks");
        exe.addFrameworkDir("/Library/Developer/CommandLineTools/SDKs/MacOSX10.15.sdk/System/Library/Frameworks");
        exe.linkFramework("OpenCL");
    } else {
        exe.linkSystemLibrary("opencl");
    }

    exe.addIncludeDir("src/blaster");
    exe.addCSourceFile("src/blaster/blaster.c", &[_][]const u8{});
    const fut = b.addSystemCommand(&[_][]const u8{ "futhark", "opencl", "--library", "src/blaster/blaster.fut" });
    exe.step.dependOn(&fut.step);

    exe.install();

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const exe_tests = b.addTest("src/main.zig");
    exe_tests.setTarget(target);
    exe_tests.setBuildMode(mode);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&exe_tests.step);
}
