pub fn lex(source: &str) -> Vec<String> {
    source.split_whitespace().map(str::to_string).collect()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn tokenizes_words() {
        let tokens = lex("I64 Add");
        assert_eq!(tokens, vec!["I64".to_string(), "Add".to_string()]);
    }
}
