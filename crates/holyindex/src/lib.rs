use holylex::lex;
use std::fs;
use std::path::Path;

pub fn is_holy_source(path: &Path) -> bool {
    path.extension()
        .and_then(|e| e.to_str())
        .map(|e| matches!(e.to_ascii_lowercase().as_str(), "hc" | "hh" | "zc" | "zh"))
        .unwrap_or(false)
}

pub fn scan_file(path: &Path) -> Result<usize, String> {
    let source = fs::read_to_string(path).map_err(|err| format!("{}: {}", path.display(), err))?;
    Ok(lex(&source).len())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn detects_holy_source_extensions() {
        assert!(is_holy_source(Path::new("a.HC")));
        assert!(is_holy_source(Path::new("a.HH")));
        assert!(!is_holy_source(Path::new("a.txt")));
    }
}
