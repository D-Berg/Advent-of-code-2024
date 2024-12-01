const std = @import("std");

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});

    const optimize = b.standardOptimizeOption(.{});

    const exe1 = b.addExecutable(.{
        .name = "problem1",
        .root_source_file = b.path("src/problem1.zig"),
        .target = target,
        .optimize = optimize,
    });

    const exe2 = b.addExecutable(.{
        .name = "problem2",
        .root_source_file = b.path("src/proglem2.zig"),
        .target = target,
        .optimize = optimize
    });

    b.installArtifact(exe1);
    b.installArtifact(exe2);

    const run_cmd_prbm1 = b.addRunArtifact(exe1);
    const run_cmd_prbm2 = b.addRunArtifact(exe2);

    run_cmd_prbm1.step.dependOn(b.getInstallStep());
    run_cmd_prbm2.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd_prbm1.addArgs(args);
        run_cmd_prbm2.addArgs(args);
    }
    const run_step1 = b.step("problem1", "Run Problem 1");
    run_step1.dependOn(&run_cmd_prbm1.step);

    const run_step2 = b.step("problem2", "Run Problem 2");
    run_step2.dependOn(&run_cmd_prbm2.step);

    const exe_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_exe_unit_tests.step);
}
