use std::fmt;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum TokenKind {
    Ident,
    Keyword,
    Number,
    String,
    Char,
    Comment,
    Symbol,
    Whitespace,
    Newline,
    Unknown,
}

impl TokenKind {
    pub fn as_str(self) -> &'static str {
        match self {
            TokenKind::Ident => "Ident",
            TokenKind::Keyword => "Keyword",
            TokenKind::Number => "Number",
            TokenKind::String => "String",
            TokenKind::Char => "Char",
            TokenKind::Comment => "Comment",
            TokenKind::Symbol => "Symbol",
            TokenKind::Whitespace => "Whitespace",
            TokenKind::Newline => "Newline",
            TokenKind::Unknown => "Unknown",
        }
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Token {
    pub kind: TokenKind,
    pub lexeme: String,
    pub line: usize,
    pub column: usize,
}

impl Token {
    fn new(kind: TokenKind, lexeme: String, line: usize, column: usize) -> Self {
        Self { kind, lexeme, line, column }
    }

    pub fn is_trivia(&self) -> bool {
        matches!(self.kind, TokenKind::Whitespace | TokenKind::Newline)
    }
}

impl fmt::Display for Token {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        let lexeme = self.lexeme.replace('\r', "\\r").replace('\n', "\\n").replace('\t', "\\t");
        write!(f, "{}:{}\t{}\t{}", self.line, self.column, self.kind.as_str(), lexeme)
    }
}

pub fn lex(source: &str) -> Vec<Token> {
    let mut lexer = Lexer::new(source);
    lexer.lex_all()
}

pub fn is_keyword(text: &str) -> bool {
    matches!(
        text,
        "asm" | "break" | "case" | "catch" | "class" | "const" | "default" | "do"
            | "else" | "extern" | "for" | "goto" | "if" | "public" | "return"
            | "sizeof" | "start" | "switch" | "throw" | "try" | "while" | "Bool"
            | "F64" | "I0" | "I8" | "I16" | "I32" | "I64" | "U0" | "U8" | "U16"
            | "U32" | "U64"
    )
}

struct Lexer {
    chars: Vec<char>,
    index: usize,
    line: usize,
    column: usize,
}

impl Lexer {
    fn new(source: &str) -> Self {
        Self { chars: source.chars().collect(), index: 0, line: 1, column: 1 }
    }

    fn lex_all(&mut self) -> Vec<Token> {
        let mut tokens = Vec::new();
        while let Some(ch) = self.peek() {
            if ch == '\u{feff}' {
                self.index += 1;
                continue;
            }
            let token = match ch {
                '\r' | '\n' => self.lex_newline(),
                c if c.is_whitespace() => self.lex_whitespace(),
                '/' if self.peek_next() == Some('/') => self.lex_line_comment(),
                '/' if self.peek_next() == Some('*') => self.lex_block_comment(),
                '"' => self.lex_quoted(TokenKind::String, '"'),
                '\'' => self.lex_quoted(TokenKind::Char, '\''),
                c if is_ident_start(c) => self.lex_ident_or_keyword(),
                c if c.is_ascii_digit() => self.lex_number(),
                c if is_symbol_start(c) => self.lex_symbol(),
                _ => {
                    let line = self.line;
                    let column = self.column;
                    let ch = self.bump().expect("peeked char must bump");
                    Token::new(TokenKind::Unknown, ch.to_string(), line, column)
                }
            };
            tokens.push(token);
        }
        tokens
    }

    fn peek(&self) -> Option<char> { self.chars.get(self.index).copied() }
    fn peek_next(&self) -> Option<char> { self.chars.get(self.index + 1).copied() }

    fn bump(&mut self) -> Option<char> {
        let ch = self.chars.get(self.index).copied()?;
        self.index += 1;
        if ch == '\n' {
            self.line += 1;
            self.column = 1;
        } else {
            self.column += 1;
        }
        Some(ch)
    }

    fn lex_newline(&mut self) -> Token {
        let line = self.line;
        let column = self.column;
        if self.peek() == Some('\r') && self.peek_next() == Some('\n') {
            self.index += 2;
            self.line += 1;
            self.column = 1;
            return Token::new(TokenKind::Newline, "\r\n".to_string(), line, column);
        }
        let ch = self.bump().expect("newline char");
        if ch == '\r' {
            self.line += 1;
            self.column = 1;
        }
        Token::new(TokenKind::Newline, ch.to_string(), line, column)
    }

    fn lex_whitespace(&mut self) -> Token {
        let line = self.line;
        let column = self.column;
        let mut text = String::new();
        while let Some(ch) = self.peek() {
            if !ch.is_whitespace() || ch == '\r' || ch == '\n' { break; }
            text.push(self.bump().expect("whitespace char"));
        }
        Token::new(TokenKind::Whitespace, text, line, column)
    }

    fn lex_line_comment(&mut self) -> Token {
        let line = self.line;
        let column = self.column;
        let mut text = String::new();
        while let Some(ch) = self.peek() {
            if ch == '\r' || ch == '\n' { break; }
            text.push(self.bump().expect("comment char"));
        }
        Token::new(TokenKind::Comment, text, line, column)
    }

    fn lex_block_comment(&mut self) -> Token {
        let line = self.line;
        let column = self.column;
        let mut text = String::new();
        text.push(self.bump().expect("comment slash"));
        text.push(self.bump().expect("comment star"));
        while let Some(ch) = self.peek() {
            text.push(self.bump().expect("comment body"));
            if ch == '*' && self.peek() == Some('/') {
                text.push(self.bump().expect("comment slash"));
                break;
            }
        }
        Token::new(TokenKind::Comment, text, line, column)
    }

    fn lex_quoted(&mut self, kind: TokenKind, quote: char) -> Token {
        let line = self.line;
        let column = self.column;
        let mut text = String::new();
        let mut escaped = false;
        text.push(self.bump().expect("quote"));
        while let Some(ch) = self.peek() {
            text.push(self.bump().expect("quoted char"));
            if escaped {
                escaped = false;
                continue;
            }
            if ch == '\\' {
                escaped = true;
                continue;
            }
            if ch == quote { break; }
        }
        Token::new(kind, text, line, column)
    }

    fn lex_ident_or_keyword(&mut self) -> Token {
        let line = self.line;
        let column = self.column;
        let mut text = String::new();
        while let Some(ch) = self.peek() {
            if !is_ident_continue(ch) { break; }
            text.push(self.bump().expect("ident char"));
        }
        let kind = if is_keyword(&text) { TokenKind::Keyword } else { TokenKind::Ident };
        Token::new(kind, text, line, column)
    }

    fn lex_number(&mut self) -> Token {
        let line = self.line;
        let column = self.column;
        let mut text = String::new();
        while let Some(ch) = self.peek() {
            if !(ch.is_ascii_alphanumeric() || ch == '_' || ch == '.') { break; }
            text.push(self.bump().expect("number char"));
        }
        Token::new(TokenKind::Number, text, line, column)
    }

    fn lex_symbol(&mut self) -> Token {
        let line = self.line;
        let column = self.column;
        let first = self.bump().expect("symbol char");
        let mut text = first.to_string();
        if let Some(next) = self.peek() {
            let pair = format!("{first}{next}");
            if is_two_char_symbol(&pair) {
                text.push(self.bump().expect("symbol pair"));
            }
        }
        Token::new(TokenKind::Symbol, text, line, column)
    }
}

fn is_ident_start(ch: char) -> bool { ch == '_' || ch.is_ascii_alphabetic() }
fn is_ident_continue(ch: char) -> bool { ch == '_' || ch.is_ascii_alphanumeric() }

fn is_symbol_start(ch: char) -> bool {
    matches!(ch, '#' | '(' | ')' | '{' | '}' | '[' | ']' | ';' | ',' | '.' | ':' | '?' | '~' | '+' | '-' | '*' | '/' | '%' | '=' | '!' | '<' | '>' | '&' | '|' | '^' | '@' | '$')
}

fn is_two_char_symbol(text: &str) -> bool {
    matches!(text, "==" | "!=" | "<=" | ">=" | "&&" | "||" | "++" | "--" | "+=" | "-=" | "*=" | "/=" | "%=" | "<<" | ">>" | "->" | "::")
}

#[cfg(test)]
mod tests {
    use super::*;

    fn visible_lexemes(source: &str) -> Vec<String> {
        lex(source).into_iter().filter(|token| !token.is_trivia()).map(|token| token.lexeme).collect()
    }

    #[test]
    fn tokenizes_basic_holyc_function() {
        let lexemes = visible_lexemes("I64 Add(I64 a, I64 b) { return a + b; }");
        assert_eq!(lexemes, vec!["I64", "Add", "(", "I64", "a", ",", "I64", "b", ")", "{", "return", "a", "+", "b", ";", "}"]);
    }

    #[test]
    fn skips_utf8_bom() {
        let tokens = lex("\u{feff}I64 Add");
        let visible: Vec<_> = tokens.into_iter().filter(|token| !token.is_trivia()).collect();
        assert_eq!(visible[0].lexeme, "I64");
        assert_eq!(visible[0].line, 1);
        assert_eq!(visible[0].column, 1);
    }

    #[test]
    fn tokenizes_comment_and_string() {
        let tokens = lex("// hi\n\"abc\";");
        assert!(tokens.iter().any(|token| token.kind == TokenKind::Comment));
        assert!(tokens.iter().any(|token| token.kind == TokenKind::String));
    }
}
