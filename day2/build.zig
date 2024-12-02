const std = @import("std");

pub fn build(b: *std.Build) void {

    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});


    const exe1 = b.addExecutable(.{
        .name = "problem1",
        .root_source_file = b.path("src/problem1.zig"),
        .target = target,
        .optimize = optimize
    });

    const exe2 = b.addExecutable(.{
        .name = "problem2",
        .root_source_file = b.path("src/problem2.zig"),
        .target = target,
        .optimize = optimize
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



}
