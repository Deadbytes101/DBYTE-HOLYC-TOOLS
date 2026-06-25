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

fn fixture(name: &str) -> PathBuf {
    workspace_root().join("tests").join("fixtures").join(name)
}

fn tiny_fixture() -> PathBuf {
    fixture("tiny")
}

fn missing_fixture() -> PathBuf {
    fixture("missing")
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

fn run_with_fixture(command_name: &str, path: PathBuf, extra: &[&str]) -> String {
    let mut command = holytools();
    command.arg(command_name).arg(path).args(extra);
    run_command(command, command_name)
}

fn run_with_tiny_fixture(command_name: &str, extra: &[&str]) -> String {
    run_with_fixture(command_name, tiny_fixture(), extra)
}

fn run_with_missing_fixture(command_name: &str, extra: &[&str]) -> String {
    run_with_fixture(command_name, missing_fixture(), extra)
}

#[test]
fn version_reports_current_package_version() {
    let stdout = run(&["version"]);

    assert!(stdout.contains("holytools "));
    assert!(stdout.contains("writes: none"));
}

#[test]
fn stats_reports_fixture_counts() {
    let stdout = run_with_tiny_fixture("stats", &[]);

    assert!(stdout.contains("holy-files: 2"));
    assert!(stdout.contains("functions: 2"));
    assert!(stdout.contains("classes: 1"));
    assert!(stdout.contains("includes: 1"));
    assert!(stdout.contains("status: ok"));
}

#[test]
fn source_map_reports_fixture_summary() {
    let stdout = run_with_tiny_fixture("source-map", &[]);

    assert!(stdout.contains("holy-files: 2"));
    assert!(stdout.contains("tokens: 73"));
    assert!(stdout.contains("functions: 2"));
    assert!(stdout.contains("classes: 1"));
    assert!(stdout.contains("resolved-includes: 1"));
    assert!(stdout.contains("missing-includes: 0"));
    assert!(stdout.contains("dependency-files: 2"));
    assert!(stdout.contains("reverse-edges: 1"));
    assert!(stdout.contains("status: ok"));
}

#[test]
fn source_map_json_reports_fixture_summary() {
    let stdout = run_with_tiny_fixture("source-map", &["--json"]);

    assert!(stdout.contains("\"holy_files\":2"));
    assert!(stdout.contains("\"tokens\":73"));
    assert!(stdout.contains("\"functions\":2"));
    assert!(stdout.contains("\"classes\":1"));
    assert!(stdout.contains("\"resolved_includes\":1"));
    assert!(stdout.contains("\"missing_includes\":0"));
    assert!(stdout.contains("\"dependency_files\":2"));
    assert!(stdout.contains("\"reverse_edges\":1"));
    assert!(stdout.contains("\"status\":\"ok\""));
}

#[test]
fn missing_includes_reports_missing_target() {
    let stdout = run_with_missing_fixture("missing-includes", &[]);

    assert!(stdout.contains("broken.HC:1:1"));
    assert!(stdout.contains("absent.HH"));
    assert!(stdout.contains("missing: 1"));
    assert!(stdout.contains("status: ok"));
}

#[test]
fn missing_includes_json_reports_missing_target() {
    let stdout = run_with_missing_fixture("missing-includes", &["--json"]);

    assert!(stdout.contains("\"target\":\"absent.HH\""));
    assert!(stdout.contains("\"count\":1"));
    assert!(stdout.contains("\"status\":\"ok\""));
}

#[test]
fn entrypoints_reports_source_file() {
    let stdout = run_with_tiny_fixture("entrypoints", &[]);

    assert!(stdout.contains("1\t"));
    assert!(stdout.contains("hello.HC"));
    assert!(stdout.contains("entrypoints: 1"));
    assert!(stdout.contains("status: ok"));
}

#[test]
fn entrypoints_json_reports_source_file() {
    let stdout = run_with_tiny_fixture("entrypoints", &["--json"]);

    assert!(stdout.contains("\"file\":"));
    assert!(stdout.contains("hello.HC"));
    assert!(stdout.contains("\"count\":1"));
    assert!(stdout.contains("\"status\":\"ok\""));
}

#[test]
fn resolve_includes_json_reports_no_missing_includes() {
    let stdout = run_with_tiny_fixture("resolve-includes", &["--json"]);

    assert!(stdout.contains("\"resolved\":1"));
    assert!(stdout.contains("\"missing\":0"));
    assert!(stdout.contains("\"status\":\"ok\""));
}

#[test]
fn dependency_order_reports_header_before_source() {
    let stdout = run_with_tiny_fixture("dependency-order", &[]);
    let header = stdout.find("hello.HH").expect("header should be listed");
    let source = stdout.find("hello.HC").expect("source should be listed");

    assert!(header < source, "header should appear before source");
    assert!(stdout.contains("status: ok"));
}

#[test]
fn oracle_reports_seeded_random_text() {
    let stdout = run(&["oracle", "--seed", "7", "--count", "2"]);

    assert!(stdout.contains("mode: oracle"));
    assert!(stdout.contains("seed: 7"));
    assert!(stdout.contains("boundary: random text lab, not prophecy"));
    assert!(stdout.contains("count: 2"));
    assert!(stdout.contains("status: ok"));
}

#[test]
fn oracle_json_reports_seeded_after_egypt_text() {
    let stdout = run(&[
        "oracle",
        "--preset",
        "after-egypt",
        "--seed",
        "7",
        "--count",
        "1",
        "--json",
    ]);

    assert!(stdout.contains("\"mode\":\"oracle\""));
    assert!(stdout.contains("\"preset\":\"after-egypt\""));
    assert!(stdout.contains("\"seed\":7"));
    assert!(stdout.contains("\"count\":1"));
    assert!(stdout.contains("\"status\":\"ok\""));
}
