use std::path::PathBuf;
use std::process::Command;

fn holytools() -> Command {
    Command::new(env!("CARGO_BIN_EXE_holytools"))
}

fn workspace_root() -> PathBuf {
    PathBuf::from(env!("CARGO_MANIFEST_DIR"))
        .parent()
        .and_then(|path| path.parent())
        .expect("holytools crate should live under crates/holycli")
        .to_path_buf()
}

fn tiny_fixture() -> PathBuf {
    workspace_root().join("tests").join("fixtures").join("tiny")
}

fn run_command(mut command: Command, context: &str) -> String {
    let output = command.output().expect("holytools command should run");

    assert!(
        output.status.success(),
        "command failed: {context}\nstdout:\n{}\nstderr:\n{}",
        String::from_utf8_lossy(&output.stdout),
        String::from_utf8_lossy(&output.stderr)
    );

    String::from_utf8(output.stdout).expect("stdout should be valid utf-8")
}

fn run(args: &[&str]) -> String {
    let mut command = holytools();
    command.args(args);
    run_command(command, &format!("{args:?}"))
}

fn run_with_fixture(command_name: &str, extra: &[&str]) -> String {
    let mut command = holytools();
    command.arg(command_name).arg(tiny_fixture()).args(extra);
    run_command(command, command_name)
}

#[test]
fn version_reports_current_package_version() {
    let stdout = run(&["version"]);

    assert!(stdout.contains("holytools "));
    assert!(stdout.contains("writes: none"));
}

#[test]
fn stats_reports_fixture_counts() {
    let stdout = run_with_fixture("stats", &[]);

    assert!(stdout.contains("holy-files: 2"));
    assert!(stdout.contains("functions: 2"));
    assert!(stdout.contains("classes: 1"));
    assert!(stdout.contains("includes: 1"));
    assert!(stdout.contains("status: ok"));
}

#[test]
fn resolve_includes_json_reports_no_missing_includes() {
    let stdout = run_with_fixture("resolve-includes", &["--json"]);

    assert!(stdout.contains("\"resolved\":1"));
    assert!(stdout.contains("\"missing\":0"));
    assert!(stdout.contains("\"status\":\"ok\""));
}

#[test]
fn dependency_order_reports_header_before_source() {
    let stdout = run_with_fixture("dependency-order", &[]);
    let header = stdout.find("hello.HH").expect("header should be listed");
    let source = stdout.find("hello.HC").expect("source should be listed");

    assert!(header < source, "header should appear before source");
    assert!(stdout.contains("status: ok"));
}
