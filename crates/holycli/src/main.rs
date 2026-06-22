use holylex::lex;
use std::env;
use std::fs;
use std::path::Path;
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
    match command {
        "version" => {
            println!("holytools {}", env!("CARGO_PKG_VERSION"));
            println!("writes: none");
            Ok(())
        }
        "scan" => {
            let path = args.get(2).ok_or("usage: holytools scan <path>")?;
            let mut count = 0usize;
            collect(Path::new(path), &mut count)?;
            println!("holy-files: {count}");
            println!("status: ok");
            Ok(())
        }
        "tokens" => {
            let path = args.get(2).ok_or("usage: holytools tokens <file>")?;
            let source = fs::read_to_string(path).map_err(|err| err.to_string())?;
            for token in lex(&source) {
                println!("{token}");
            }
            println!("status: ok");
            Ok(())
        }
        _ => {
            println!("holytools");
            println!("usage: holytools <version|scan|tokens> [path]");
            Ok(())
        }
    }
}

fn collect(path: &Path, count: &mut usize) -> Result<(), String> {
    if path.is_file() {
        if is_holy(path) {
            *count += 1;
        }
        return Ok(());
    }
    for entry in fs::read_dir(path).map_err(|err| err.to_string())? {
        let entry = entry.map_err(|err| err.to_string())?;
        let path = entry.path();
        if path.is_dir() {
            collect(&path, count)?;
        } else if is_holy(&path) {
            *count += 1;
        }
    }
    Ok(())
}

fn is_holy(path: &Path) -> bool {
    path.extension()
        .and_then(|value| value.to_str())
        .map(|value| matches!(value.to_ascii_lowercase().as_str(), "hc" | "hh" | "zc" | "zh"))
        .unwrap_or(false)
}
