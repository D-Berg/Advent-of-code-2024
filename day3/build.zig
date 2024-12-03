const std = @import("std");

pub fn build(b: *std.Build) void {

    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe1 = b.addExecutable(.{
        .name = "problem1",
        .root_source_file = b.path("src/p1.zig"),
        .target = target,
        .optimize = optimize,
    });

    const exe2 = b.addExecutable(.{
        .name = "problem2",
        .root_source_file = b.path("src/p2.zig"),
        .target = target,
        .optimize = optimize,
    });

    b.installArtifact(exe1);
    b.installArtifact(exe2);


    const run_cmd1 = b.addRunArtifact(exe1);
    const run_cmd2 = b.addRunArtifact(exe2);

    run_cmd1.step.dependOn(b.getInstallStep());
    run_cmd2.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd1.addArgs(args);
        run_cmd2.addArgs(args);
    }

    const run_step1 = b.step("problem1", "run problem 1");
    const run_step2 = b.step("problem2", "run problem 2");

    run_step1.dependOn(&run_cmd1.step);
    run_step2.dependOn(&run_cmd2.step);


    const exe_unit_tests1 = b.addTest(.{
        .root_source_file = b.path("src/p1.zig"),
        .target = target,
        .optimize = optimize
    });

    const run_exe_unit_tests1 = b.addRunArtifact(exe_unit_tests1);

    const test_step1 = b.step("test1", "Run problem1's unit tests");
    test_step1.dependOn(&run_exe_unit_tests1.step);
    

    const exe_unit_tests2 = b.addTest(.{
        .root_source_file = b.path("src/p2.zig"),
        .target = target,
        .optimize = optimize
    });

    const run_exe_unit_tests2 = b.addRunArtifact(exe_unit_tests2);

    const test_step2 = b.step("test2", "Run problem2's unit tests");
    test_step2.dependOn(&run_exe_unit_tests2.step);


}
