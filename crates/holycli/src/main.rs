use holyindex::{scan_file_report, scan_path, FileReport};
use holylex::lex;
use std::env;
use std::fs;
use std::path::{Path, PathBuf};
use std::process::ExitCode;

fn main() -> ExitCode {
    match run() {
        Ok(()) => ExitCode::SUCCESS,
        Err(err) => {
            eprintln!("error: {err}");
            ExitCode::FAILURE
        }
    }
}

fn run() -> Result<(), String> {
    let args: Vec<String> = env::args().collect();
    let command = args.get(1).map(String::as_str).unwrap_or("help");
    let json = has_flag(&args, "--json");

    match command {
        "version" => {
            println!("holytools {}", env!("CARGO_PKG_VERSION"));
            println!("writes: none");
            Ok(())
        }
        "scan" => {
            let path = required_path(&args, "scan")?;
            let report = scan_path(Path::new(path))?;

            if json {
                println!(
                    "{{\"root\":\"{}\",\"holy_files\":{},\"status\":\"ok\"}}",
                    json_escape(&display(Path::new(path))),
                    report.files.len()
                );
            } else {
                println!("root: {}", display(Path::new(path)));
                println!("holy-files: {}", report.files.len());
                println!("status: ok");
            }

            Ok(())
        }
        "stats" => {
            let path = required_path(&args, "stats")?;
            let report = scan_path(Path::new(path))?;

            if json {
                println!(
                    "{{\"root\":\"{}\",\"holy_files\":{},\"tokens\":{},\"functions\":{},\"classes\":{},\"includes\":{},\"asm_blocks\":{},\"status\":\"ok\"}}",
                    json_escape(&display(Path::new(path))),
                    report.files.len(),
                    report.token_count(),
                    report.function_count(),
                    report.class_count(),
                    report.include_count(),
                    report.asm_count()
                );
            } else {
                println!("root: {}", display(Path::new(path)));
                println!("holy-files: {}", report.files.len());
                println!("tokens: {}", report.token_count());
                println!("functions: {}", report.function_count());
                println!("classes: {}", report.class_count());
                println!("includes: {}", report.include_count());
                println!("asm-blocks: {}", report.asm_count());
                println!("status: ok");
            }

            Ok(())
        }
        "source-map" => {
            let path = required_path(&args, "source-map")?;
            let root = Path::new(path);
            let report = scan_path(root)?;
            let rows = resolved_includes(root, &report.files);
            let resolved_count = rows.iter().filter(|row| row.resolved.is_some()).count();
            let missing_count = rows.len() - resolved_count;
            let dependency_files = dependency_order(root, &report.files).len();
            let reverse_edges = rows.len();

            if json {
                println!(
                    "{{\"root\":\"{}\",\"holy_files\":{},\"tokens\":{},\"functions\":{},\"classes\":{},\"includes\":{},\"asm_blocks\":{},\"resolved_includes\":{},\"missing_includes\":{},\"dependency_files\":{},\"reverse_edges\":{},\"status\":\"ok\"}}",
                    json_escape(&display(root)),
                    report.files.len(),
                    report.token_count(),
                    report.function_count(),
                    report.class_count(),
                    report.include_count(),
                    report.asm_count(),
                    resolved_count,
                    missing_count,
                    dependency_files,
                    reverse_edges
                );
            } else {
                println!("root: {}", display(root));
                println!("holy-files: {}", report.files.len());
                println!("tokens: {}", report.token_count());
                println!("functions: {}", report.function_count());
                println!("classes: {}", report.class_count());
                println!("includes: {}", report.include_count());
                println!("asm-blocks: {}", report.asm_count());
                println!("resolved-includes: {resolved_count}");
                println!("missing-includes: {missing_count}");
                println!("dependency-files: {dependency_files}");
                println!("reverse-edges: {reverse_edges}");
                println!("status: ok");
            }

            Ok(())
        }
        "tokens" => {
            let path = required_path(&args, "tokens")?;
            let source = fs::read_to_string(path).map_err(|err| err.to_string())?;

            for token in lex(&source).into_iter().filter(|token| !token.is_trivia()) {
                println!("{token}");
            }

            println!("status: ok");
            Ok(())
        }
        "outline" => {
            let path = required_path(&args, "outline")?;
            let report = scan_file_report(Path::new(path))?;

            if json {
                print_outline_json(path, &report);
            } else {
                print_outline_text(path, &report);
            }

            Ok(())
        }
        "find-symbol" => {
            let path = required_path(&args, "find-symbol")?;
            let name = required_second_arg(&args, "find-symbol")?;
            let report = scan_path(Path::new(path))?;
            let mut matches = Vec::new();

            for file in report.files {
                for symbol in file.symbols {
                    if symbol.name == name {
                        matches.push((file.path.clone(), symbol));
                    }
                }
            }

            matches.sort_by(|a, b| {
                (display(&a.0), a.1.line, a.1.column, &a.1.name).cmp(&(
                    display(&b.0),
                    b.1.line,
                    b.1.column,
                    &b.1.name,
                ))
            });

            if json {
                print!("{{\"query\":\"{}\",\"matches\":[", json_escape(name));
                for (index, (path, symbol)) in matches.iter().enumerate() {
                    if index > 0 {
                        print!(",");
                    }
                    print!(
                        "{{\"file\":\"{}\",\"line\":{},\"column\":{},\"kind\":\"{}\",\"name\":\"{}\"}}",
                        json_escape(&display(path)),
                        symbol.line,
                        symbol.column,
                        symbol.kind.as_str(),
                        json_escape(&symbol.name)
                    );
                }
                println!("],\"count\":{},\"status\":\"ok\"}}", matches.len());
            } else {
                for (path, symbol) in &matches {
                    println!(
                        "{}:{}:{}\t{}\t{}",
                        display(path),
                        symbol.line,
                        symbol.column,
                        symbol.kind.as_str(),
                        symbol.name
                    );
                }
                println!("matches: {}", matches.len());
                println!("status: ok");
            }

            Ok(())
        }
        "symbols" => {
            let path = required_path(&args, "symbols")?;
            let report = scan_path(Path::new(path))?;

            if json {
                print!("{{\"symbols\":[");
                let mut first = true;
                for file in report.files {
                    for symbol in file.symbols {
                        if !first {
                            print!(",");
                        }
                        first = false;
                        print!(
                            "{{\"file\":\"{}\",\"line\":{},\"column\":{},\"kind\":\"{}\",\"name\":\"{}\"}}",
                            json_escape(&display(&file.path)),
                            symbol.line,
                            symbol.column,
                            symbol.kind.as_str(),
                            json_escape(&symbol.name)
                        );
                    }
                }
                println!("],\"status\":\"ok\"}}");
            } else {
                for file in report.files {
                    for symbol in file.symbols {
                        println!(
                            "{}:{}:{}\t{}\t{}",
                            display(&file.path),
                            symbol.line,
                            symbol.column,
                            symbol.kind.as_str(),
                            symbol.name
                        );
                    }
                }
                println!("status: ok");
            }

            Ok(())
        }
        "include-graph" => {
            let path = required_path(&args, "include-graph")?;
            let report = scan_path(Path::new(path))?;
            let mut edges = Vec::new();

            for file in report.files {
                for include in file.includes {
                    edges.push((file.path.clone(), include));
                }
            }

            edges.sort_by(|a, b| {
                (display(&a.0), a.1.line, a.1.column, &a.1.target).cmp(&(
                    display(&b.0),
                    b.1.line,
                    b.1.column,
                    &b.1.target,
                ))
            });

            if json {
                print!("{{\"edges\":[");
                for (index, (from, include)) in edges.iter().enumerate() {
                    if index > 0 {
                        print!(",");
                    }
                    print!(
                        "{{\"from\":\"{}\",\"to\":\"{}\",\"line\":{},\"column\":{}}}",
                        json_escape(&display(from)),
                        json_escape(&include.target),
                        include.line,
                        include.column
                    );
                }
                println!("],\"count\":{},\"status\":\"ok\"}}", edges.len());
            } else {
                for (from, include) in &edges {
                    println!(
                        "{}:{}:{}\t{} -> {}",
                        display(from),
                        include.line,
                        include.column,
                        display(from),
                        include.target
                    );
                }
                println!("edges: {}", edges.len());
                println!("status: ok");
            }

            Ok(())
        }
        "resolve-includes" => {
            let path = required_path(&args, "resolve-includes")?;
            let root = Path::new(path);
            let report = scan_path(root)?;
            let rows = resolved_includes(root, &report.files);
            let resolved_count = rows.iter().filter(|row| row.resolved.is_some()).count();
            let missing_count = rows.len() - resolved_count;

            if json {
                print!("{{\"includes\":[");
                for (index, row) in rows.iter().enumerate() {
                    if index > 0 {
                        print!(",");
                    }
                    let status = if row.resolved.is_some() {
                        "resolved"
                    } else {
                        "missing"
                    };
                    let resolved = row
                        .resolved
                        .as_ref()
                        .map(|path| display(path))
                        .unwrap_or_else(|| "".to_string());
                    print!(
                        "{{\"file\":\"{}\",\"line\":{},\"column\":{},\"target\":\"{}\",\"status\":\"{}\",\"resolved\":\"{}\"}}",
                        json_escape(&display(&row.file)),
                        row.line,
                        row.column,
                        json_escape(&row.target),
                        status,
                        json_escape(&resolved)
                    );
                }
                println!(
                    "],\"resolved\":{},\"missing\":{},\"status\":\"ok\"}}",
                    resolved_count, missing_count
                );
            } else {
                for row in &rows {
                    match &row.resolved {
                        Some(resolved) => println!(
                            "{}:{}:{}\t{}\tresolved\t{}",
                            display(&row.file),
                            row.line,
                            row.column,
                            row.target,
                            display(resolved)
                        ),
                        None => println!(
                            "{}:{}:{}\t{}\tmissing\t-",
                            display(&row.file),
                            row.line,
                            row.column,
                            row.target
                        ),
                    }
                }
                println!("resolved: {resolved_count}");
                println!("missing: {missing_count}");
                println!("status: ok");
            }

            Ok(())
        }
        "missing-includes" => {
            let path = required_path(&args, "missing-includes")?;
            let root = Path::new(path);
            let report = scan_path(root)?;
            let rows: Vec<_> = resolved_includes(root, &report.files)
                .into_iter()
                .filter(|row| row.resolved.is_none())
                .collect();

            if json {
                print!("{{\"missing\":[");
                for (index, row) in rows.iter().enumerate() {
                    if index > 0 {
                        print!(",");
                    }
                    print!(
                        "{{\"file\":\"{}\",\"line\":{},\"column\":{},\"target\":\"{}\"}}",
                        json_escape(&display(&row.file)),
                        row.line,
                        row.column,
                        json_escape(&row.target)
                    );
                }
                println!("],\"count\":{},\"status\":\"ok\"}}", rows.len());
            } else {
                for row in &rows {
                    println!(
                        "{}:{}:{}\t{}",
                        display(&row.file),
                        row.line,
                        row.column,
                        row.target
                    );
                }
                println!("missing: {}", rows.len());
                println!("status: ok");
            }

            Ok(())
        }
        "entrypoints" => {
            let path = required_path(&args, "entrypoints")?;
            let root = Path::new(path);
            let report = scan_path(root)?;
            let rows = entrypoint_files(root, &report.files);

            if json {
                print!("{{\"entrypoints\":[");
                for (index, file) in rows.iter().enumerate() {
                    if index > 0 {
                        print!(",");
                    }
                    print!(
                        "{{\"index\":{},\"file\":\"{}\"}}",
                        index + 1,
                        json_escape(&display(file))
                    );
                }
                println!("],\"count\":{},\"status\":\"ok\"}}", rows.len());
            } else {
                for (index, file) in rows.iter().enumerate() {
                    println!("{}\t{}", index + 1, display(file));
                }
                println!("entrypoints: {}", rows.len());
                println!("status: ok");
            }

            Ok(())
        }
        "dependency-order" => {
            let path = required_path(&args, "dependency-order")?;
            let root = Path::new(path);
            let report = scan_path(root)?;
            let order = dependency_order(root, &report.files);

            if json {
                print!("{{\"order\":[");
                for (index, file) in order.iter().enumerate() {
                    if index > 0 {
                        print!(",");
                    }
                    print!(
                        "{{\"index\":{},\"file\":\"{}\"}}",
                        index + 1,
                        json_escape(&display(file))
                    );
                }
                println!("],\"count\":{},\"status\":\"ok\"}}", order.len());
            } else {
                for (index, file) in order.iter().enumerate() {
                    println!("{}\t{}", index + 1, display(file));
                }
                println!("files: {}", order.len());
                println!("status: ok");
            }

            Ok(())
        }
        "reverse-includes" => {
            let path = required_path(&args, "reverse-includes")?;
            let root = Path::new(path);
            let report = scan_path(root)?;
            let mut rows = Vec::new();

            for include in resolved_includes(root, &report.files) {
                let status = if include.resolved.is_some() {
                    "resolved"
                } else {
                    "missing"
                };
                let target = include
                    .resolved
                    .as_ref()
                    .map(|path| display(path))
                    .unwrap_or_else(|| include.target.clone());
                rows.push((
                    target,
                    display(&include.file),
                    include.line,
                    include.column,
                    status.to_string(),
                ));
            }

            rows.sort();

            if json {
                print!("{{\"reverse\":[");
                for (index, (target, from, line, column, status)) in rows.iter().enumerate() {
                    if index > 0 {
                        print!(",");
                    }
                    print!(
                        "{{\"target\":\"{}\",\"from\":\"{}\",\"line\":{},\"column\":{},\"status\":\"{}\"}}",
                        json_escape(target),
                        json_escape(from),
                        line,
                        column,
                        status
                    );
                }
                println!("],\"count\":{},\"status\":\"ok\"}}", rows.len());
            } else {
                for (target, from, line, column, status) in &rows {
                    println!("{}\t<-\t{}:{}:{}\t{}", target, from, line, column, status);
                }
                println!("edges: {}", rows.len());
                println!("status: ok");
            }

            Ok(())
        }
        "includes" => {
            let path = required_path(&args, "includes")?;
            let report = scan_path(Path::new(path))?;

            if json {
                print!("{{\"includes\":[");
                let mut first = true;
                for file in report.files {
                    for include in file.includes {
                        if !first {
                            print!(",");
                        }
                        first = false;
                        print!(
                            "{{\"file\":\"{}\",\"line\":{},\"column\":{},\"target\":\"{}\"}}",
                            json_escape(&display(&file.path)),
                            include.line,
                            include.column,
                            json_escape(&include.target)
                        );
                    }
                }
                println!("],\"status\":\"ok\"}}");
            } else {
                for file in report.files {
                    for include in file.includes {
                        println!(
                            "{}:{}:{}\t{}",
                            display(&file.path),
                            include.line,
                            include.column,
                            include.target
                        );
                    }
                }
                println!("status: ok");
            }

            Ok(())
        }
        _ => {
            println!("holytools");
            println!("usage: holytools <version|scan|stats|source-map|tokens|outline|symbols|find-symbol|include-graph|resolve-includes|missing-includes|entrypoints|dependency-order|reverse-includes|includes> [path] [name] [--json]");
            Ok(())
        }
    }
}

#[derive(Debug, Clone, PartialEq, Eq, PartialOrd, Ord)]
struct OutlineRow {
    line: usize,
    column: usize,
    kind: String,
    name: String,
}

#[derive(Debug, Clone, PartialEq, Eq, PartialOrd, Ord)]
struct ResolvedInclude {
    file: PathBuf,
    line: usize,
    column: usize,
    target: String,
    resolved: Option<PathBuf>,
}

fn print_outline_text(path: &str, report: &FileReport) {
    println!("file: {}", display(Path::new(path)));

    for row in outline_rows(report) {
        println!("{}\t{}:{}\t{}", row.kind, row.line, row.column, row.name);
    }

    println!("tokens: {}", report.token_count);
    println!("status: ok");
}

fn print_outline_json(path: &str, report: &FileReport) {
    print!(
        "{{\"file\":\"{}\",\"tokens\":{},\"items\":[",
        json_escape(&display(Path::new(path))),
        report.token_count
    );

    let mut first = true;
    for row in outline_rows(report) {
        if !first {
            print!(",");
        }
        first = false;
        print!(
            "{{\"line\":{},\"column\":{},\"kind\":\"{}\",\"name\":\"{}\"}}",
            row.line,
            row.column,
            json_escape(&row.kind),
            json_escape(&row.name)
        );
    }

    println!("],\"status\":\"ok\"}}");
}

fn outline_rows(report: &FileReport) -> Vec<OutlineRow> {
    let mut rows = Vec::new();

    for include in &report.includes {
        rows.push(OutlineRow {
            line: include.line,
            column: include.column,
            kind: "include".to_string(),
            name: include.target.clone(),
        });
    }

    for symbol in &report.symbols {
        rows.push(OutlineRow {
            line: symbol.line,
            column: symbol.column,
            kind: symbol.kind.as_str().to_string(),
            name: symbol.name.clone(),
        });
    }

    rows.sort();
    rows
}

fn resolved_includes(root: &Path, files: &[FileReport]) -> Vec<ResolvedInclude> {
    let mut rows = Vec::new();

    for file in files {
        for include in &file.includes {
            rows.push(ResolvedInclude {
                file: file.path.clone(),
                line: include.line,
                column: include.column,
                target: include.target.clone(),
                resolved: resolve_include(root, &file.path, &include.target),
            });
        }
    }

    rows.sort();
    rows
}

fn entrypoint_files(root: &Path, files: &[FileReport]) -> Vec<PathBuf> {
    let mut incoming = Vec::new();
    for row in resolved_includes(root, files) {
        if let Some(resolved) = row.resolved {
            if files.iter().any(|file| file.path == resolved) {
                incoming.push(resolved);
            }
        }
    }
    incoming.sort();
    incoming.dedup();

    let mut rows: Vec<PathBuf> = files
        .iter()
        .map(|file| file.path.clone())
        .filter(|file| !incoming.contains(file))
        .collect();
    rows.sort();
    rows
}

fn dependency_order(root: &Path, files: &[FileReport]) -> Vec<PathBuf> {
    let mut all: Vec<PathBuf> = files.iter().map(|file| file.path.clone()).collect();
    all.sort();

    let mut ordered = Vec::new();
    let mut visiting = Vec::new();
    let mut visited = Vec::new();

    for file in &all {
        visit_dependency(root, files, file, &mut visiting, &mut visited, &mut ordered);
    }

    ordered
}

fn visit_dependency(
    root: &Path,
    files: &[FileReport],
    file: &PathBuf,
    visiting: &mut Vec<PathBuf>,
    visited: &mut Vec<PathBuf>,
    ordered: &mut Vec<PathBuf>,
) {
    if visited.contains(file) || visiting.contains(file) {
        return;
    }

    visiting.push(file.clone());

    if let Some(report) = files.iter().find(|item| item.path == *file) {
        let mut deps = Vec::new();
        for include in &report.includes {
            if let Some(resolved) = resolve_include(root, &report.path, &include.target) {
                if files.iter().any(|item| item.path == resolved) {
                    deps.push(resolved);
                }
            }
        }
        deps.sort();
        deps.dedup();

        for dep in deps {
            visit_dependency(root, files, &dep, visiting, visited, ordered);
        }
    }

    visiting.retain(|item| item != file);
    visited.push(file.clone());
    ordered.push(file.clone());
}

fn resolve_include(root: &Path, source_file: &Path, target: &str) -> Option<PathBuf> {
    let target_path = Path::new(target);
    let root_dir = if root.is_file() {
        root.parent().unwrap_or(root)
    } else {
        root
    };
    let mut candidates = Vec::new();

    if target_path.is_absolute() {
        candidates.push(target_path.to_path_buf());
    } else {
        if let Some(parent) = source_file.parent() {
            candidates.push(parent.join(target_path));
        }
        candidates.push(root_dir.join(target_path));
    }

    candidates.into_iter().find(|candidate| candidate.is_file())
}

fn required_path<'a>(args: &'a [String], command: &str) -> Result<&'a str, String> {
    args.iter()
        .skip(2)
        .find(|arg| !arg.starts_with('-'))
        .map(String::as_str)
        .ok_or_else(|| format!("usage: holytools {command} <path>"))
}

fn required_second_arg<'a>(args: &'a [String], command: &str) -> Result<&'a str, String> {
    args.iter()
        .skip(2)
        .filter(|arg| !arg.starts_with('-'))
        .nth(1)
        .map(String::as_str)
        .ok_or_else(|| format!("usage: holytools {command} <path> <name>"))
}

fn has_flag(args: &[String], flag: &str) -> bool {
    args.iter().any(|arg| arg == flag)
}

fn display(path: &Path) -> String {
    path.display().to_string().replace('\\', "/")
}

fn json_escape(text: &str) -> String {
    let mut out = String::new();

    for ch in text.chars() {
        match ch {
            '"' => out.push_str("\\\""),
            '\\' => out.push_str("\\\\"),
            '\n' => out.push_str("\\n"),
            '\r' => out.push_str("\\r"),
            '\t' => out.push_str("\\t"),
            c if c.is_control() => out.push_str(&format!("\\u{:04x}", c as u32)),
            c => out.push(c),
        }
    }

    out
}
