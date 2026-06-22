use holylex::{lex, Token, TokenKind};
use std::fs;
use std::path::{Path, PathBuf};

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ScanReport {
    pub root: PathBuf,
    pub files: Vec<FileReport>,
}

impl ScanReport {
    pub fn token_count(&self) -> usize {
        self.files.iter().map(|file| file.token_count).sum()
    }

    pub fn function_count(&self) -> usize {
        self.files
            .iter()
            .map(|file| file.symbols.iter().filter(|symbol| symbol.kind == SymbolKind::Function).count())
            .sum()
    }

    pub fn class_count(&self) -> usize {
        self.files
            .iter()
            .map(|file| file.symbols.iter().filter(|symbol| symbol.kind == SymbolKind::Class).count())
            .sum()
    }

    pub fn include_count(&self) -> usize {
        self.files.iter().map(|file| file.includes.len()).sum()
    }

    pub fn asm_count(&self) -> usize {
        self.files.iter().map(|file| file.asm_count).sum()
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct FileReport {
    pub path: PathBuf,
    pub token_count: usize,
    pub symbols: Vec<Symbol>,
    pub includes: Vec<Include>,
    pub asm_count: usize,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum SymbolKind {
    Function,
    Class,
}

impl SymbolKind {
    pub fn as_str(self) -> &'static str {
        match self {
            SymbolKind::Function => "function",
            SymbolKind::Class => "class",
        }
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Symbol {
    pub kind: SymbolKind,
    pub name: String,
    pub line: usize,
    pub column: usize,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Include {
    pub target: String,
    pub line: usize,
    pub column: usize,
}

pub fn is_holy_source(path: &Path) -> bool {
    path.extension()
        .and_then(|e| e.to_str())
        .map(|e| matches!(e.to_ascii_lowercase().as_str(), "hc" | "hh" | "zc" | "zh"))
        .unwrap_or(false)
}

pub fn scan_path(path: &Path) -> Result<ScanReport, String> {
    let mut paths = Vec::new();
    collect_files(path, &mut paths)?;
    paths.retain(|path| is_holy_source(path));
    paths.sort();

    let mut files = Vec::new();
    for path in paths {
        files.push(scan_file_report(&path)?);
    }

    Ok(ScanReport {
        root: path.to_path_buf(),
        files,
    })
}

pub fn scan_file(path: &Path) -> Result<usize, String> {
    scan_file_report(path).map(|report| report.token_count)
}

pub fn scan_file_report(path: &Path) -> Result<FileReport, String> {
    let source = fs::read_to_string(path).map_err(|err| format!("{}: {}", path.display(), err))?;
    let tokens = lex(&source);
    let visible = visible_tokens(&tokens);

    Ok(FileReport {
        path: path.to_path_buf(),
        token_count: tokens.len(),
        symbols: collect_symbols(&visible),
        includes: collect_includes(&visible),
        asm_count: visible.iter().filter(|token| token.lexeme == "asm").count(),
    })
}

fn collect_files(path: &Path, out: &mut Vec<PathBuf>) -> Result<(), String> {
    if path.is_file() {
        out.push(path.to_path_buf());
        return Ok(());
    }

    for entry in fs::read_dir(path).map_err(|err| format!("{}: {}", path.display(), err))? {
        let entry = entry.map_err(|err| err.to_string())?;
        let path = entry.path();

        if path.is_dir() {
            collect_files(&path, out)?;
        } else if path.is_file() {
            out.push(path);
        }
    }

    Ok(())
}

fn visible_tokens(tokens: &[Token]) -> Vec<&Token> {
    tokens.iter().filter(|token| !token.is_trivia()).collect()
}

fn collect_symbols(tokens: &[&Token]) -> Vec<Symbol> {
    let mut symbols = Vec::new();
    let mut index = 0usize;

    while index < tokens.len() {
        let token = tokens[index];

        if token.kind == TokenKind::Keyword && token.lexeme == "class" {
            if let Some(name) = tokens.get(index + 1).filter(|token| token.kind == TokenKind::Ident) {
                symbols.push(Symbol {
                    kind: SymbolKind::Class,
                    name: name.lexeme.clone(),
                    line: name.line,
                    column: name.column,
                });
            }
        }

        if is_type_like(token) {
            if let (Some(name), Some(open)) = (tokens.get(index + 1), tokens.get(index + 2)) {
                if name.kind == TokenKind::Ident && open.lexeme == "(" && !is_control_keyword(&token.lexeme) {
                    symbols.push(Symbol {
                        kind: SymbolKind::Function,
                        name: name.lexeme.clone(),
                        line: name.line,
                        column: name.column,
                    });
                }
            }
        }

        index += 1;
    }

    symbols.sort_by(|a, b| (a.line, a.column, &a.name).cmp(&(b.line, b.column, &b.name)));
    symbols.dedup_by(|a, b| a.kind == b.kind && a.name == b.name && a.line == b.line && a.column == b.column);
    symbols
}

fn collect_includes(tokens: &[&Token]) -> Vec<Include> {
    let mut includes = Vec::new();
    let mut index = 0usize;

    while index + 2 < tokens.len() {
        if tokens[index].lexeme == "#"
            && tokens[index + 1].lexeme == "include"
            && matches!(tokens[index + 2].kind, TokenKind::String | TokenKind::Ident)
        {
            includes.push(Include {
                target: trim_include_target(&tokens[index + 2].lexeme),
                line: tokens[index].line,
                column: tokens[index].column,
            });
            index += 3;
            continue;
        }

        index += 1;
    }

    includes
}

fn trim_include_target(text: &str) -> String {
    text.trim_matches('"').to_string()
}

fn is_type_like(token: &Token) -> bool {
    matches!(token.kind, TokenKind::Keyword | TokenKind::Ident)
}

fn is_control_keyword(text: &str) -> bool {
    matches!(text, "if" | "for" | "while" | "switch" | "return" | "sizeof")
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn detects_holy_source_extensions() {
        assert!(is_holy_source(Path::new("a.HC")));
        assert!(is_holy_source(Path::new("a.HH")));
        assert!(is_holy_source(Path::new("a.ZC")));
        assert!(!is_holy_source(Path::new("a.txt")));
    }

    #[test]
    fn indexes_function_and_class() {
        let path = Path::new("virtual.HC");
        let source = "class CPoint { I64 x; };\nI64 Add(I64 a, I64 b) { return a + b; }";
        let tokens = lex(source);
        let visible = visible_tokens(&tokens);
        let symbols = collect_symbols(&visible);

        assert!(symbols.iter().any(|symbol| symbol.kind == SymbolKind::Class && symbol.name == "CPoint"));
        assert!(symbols.iter().any(|symbol| symbol.kind == SymbolKind::Function && symbol.name == "Add"));
        assert_eq!(path.extension().and_then(|value| value.to_str()), Some("HC"));
    }

    #[test]
    fn indexes_include() {
        let tokens = lex("#include \"KernelA.HH\"\n");
        let visible = visible_tokens(&tokens);
        let includes = collect_includes(&visible);
        assert_eq!(includes[0].target, "KernelA.HH");
        assert_eq!(includes[0].line, 1);
        assert_eq!(includes[0].column, 1);
    }
}
