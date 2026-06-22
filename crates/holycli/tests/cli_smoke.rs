use std::process::Command;

fn holytools() -> Command {
    Command::new(env!("CARGO_BIN_EXE_holytools"))
}

fn run(args: &[&str]) -> String {
    let output = holytools()
        .args(args)
        .output()
        .expect("holytools command should run");

    assert!(
        output.status.success(),
        "command failed: {:?}\nstdout:\n{}\nstderr:\n{}",
        args,
        String::from_utf8_lossy(&output.stdout),
        String::from_utf8_lossy(&output.stderr)
    );

    String::from_utf8(output.stdout).expect("stdout should be valid utf-8")
}

#[test]
fn version_reports_current_package_version() {
    let stdout = run(&["version"]);

    assert!(stdout.contains("holytools "));
    assert!(stdout.contains("writes: none"));
}

#[test]
fn stats_reports_fixture_counts() {
    let stdout = run(&["stats", "tests/fixtures/tiny"]);

    assert!(stdout.contains("holy-files: 2"));
    assert!(stdout.contains("functions: 2"));
    assert!(stdout.contains("classes: 1"));
    assert!(stdout.contains("includes: 1"));
    assert!(stdout.contains("status: ok"));
}

#[test]
fn resolve_includes_json_reports_no_missing_includes() {
    let stdout = run(&["resolve-includes", "tests/fixtures/tiny", "--json"]);

    assert!(stdout.contains("\"resolved\":1"));
    assert!(stdout.contains("\"missing\":0"));
    assert!(stdout.contains("\"status\":\"ok\""));
}

#[test]
fn dependency_order_reports_header_before_source() {
    let stdout = run(&["dependency-order", "tests/fixtures/tiny"]);
    let header = stdout
        .find("tests/fixtures/tiny/hello.HH")
        .expect("header should be listed");
    let source = stdout
        .find("tests/fixtures/tiny/hello.HC")
        .expect("source should be listed");

    assert!(header < source, "header should appear before source");
    assert!(stdout.contains("status: ok"));
}
