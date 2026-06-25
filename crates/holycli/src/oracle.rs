use std::fs;
use std::path::Path;
use std::time::{SystemTime, UNIX_EPOCH};

const MAX_COUNT: usize = 64;

const CORE_CORPUS: &[&str] = &[
    "BUILD THE MAP",
    "COUNT BEFORE CLAIM",
    "SOURCE STAYS STILL",
    "READ THE BOOT CHAIN",
    "TRACE THE SYMBOL",
    "ZERO MUTATION",
    "RANDOM IS A TOOL",
    "MACHINE FIRST",
    "FIND THE EDGE",
    "KEEP THE BOUNDARY",
    "WRITE THE REPORT",
    "NO HIDDEN MAGIC",
];

const AFTER_EGYPT_CORPUS: &[&str] = &[
    "AFTER EGYPT: LEAVE THE OLD MAP",
    "AFTER EGYPT: COUNT THE GATES",
    "AFTER EGYPT: CROSS THE TEXT DESERT",
    "AFTER EGYPT: TRACE THE LIGHT",
    "AFTER EGYPT: BUILD WITHOUT CHAINS",
    "AFTER EGYPT: READ BEFORE BELIEF",
    "AFTER EGYPT: THE SOURCE IS STILL",
    "AFTER EGYPT: RANDOMNESS IS SIGNAL SHAPED BY THE READER",
];

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
enum Voice {
    Plain,
    Uncle,
}

impl Voice {
    fn name(self) -> &'static str {
        match self {
            Voice::Plain => "plain",
            Voice::Uncle => "uncle",
        }
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
struct OracleLine {
    index: usize,
    text: String,
}

pub fn run(args: &[String], json: bool) -> Result<(), String> {
    let count = parse_count(args)?;
    let seed = parse_seed(args)?.unwrap_or_else(default_seed);
    let preset = flag_value(args, "--preset")?.unwrap_or("core");
    let voice = parse_voice(args)?;
    let corpus = load_corpus(args, preset)?;
    let lines = generate_lines(&corpus, count, seed, voice);

    if json {
        print_json(preset, seed, voice, &lines);
    } else {
        println!("mode: oracle");
        println!("preset: {preset}");
        println!("voice: {}", voice.name());
        println!("seed: {seed}");
        println!("boundary: random text lab, not prophecy");
        for line in &lines {
            println!("{}\t{}", line.index, line.text);
        }
        println!("count: {}", lines.len());
        println!("status: ok");
    }

    Ok(())
}

pub fn print_keymap() {
    println!("PowerShell F7 binding helper:");
    println!("Bind F7 to run holytools oracle --count 1 from your shell profile.");
    println!("Use a session-only binding first, then move it into your profile after testing.");
    println!("Try voice mode with: holytools oracle --preset after-egypt --voice uncle --count 1");
    println!("status: ok");
}

fn parse_count(args: &[String]) -> Result<usize, String> {
    let count = match flag_value(args, "--count")? {
        Some(value) => value
            .parse::<usize>()
            .map_err(|_| format!("invalid --count value: {value}"))?,
        None => 1,
    };

    if count == 0 || count > MAX_COUNT {
        return Err(format!("--count must be between 1 and {MAX_COUNT}"));
    }

    Ok(count)
}

fn parse_seed(args: &[String]) -> Result<Option<u64>, String> {
    match flag_value(args, "--seed")? {
        Some(value) => value
            .parse::<u64>()
            .map(Some)
            .map_err(|_| format!("invalid --seed value: {value}")),
        None => Ok(None),
    }
}

fn parse_voice(args: &[String]) -> Result<Voice, String> {
    match flag_value(args, "--voice")? {
        Some("plain") | None => Ok(Voice::Plain),
        Some("uncle") => Ok(Voice::Uncle),
        Some(value) => Err(format!("unknown oracle voice: {value}")),
    }
}

fn load_corpus(args: &[String], preset: &str) -> Result<Vec<String>, String> {
    if let Some(path) = flag_value(args, "--corpus")? {
        let bytes = fs::read(path).map_err(|err| format!("{}: {}", path, err))?;
        let text = String::from_utf8_lossy(&bytes);
        let lines: Vec<String> = text
            .lines()
            .map(|line| line.trim_start_matches('\u{feff}').trim())
            .filter(|line| !line.is_empty() && !line.starts_with('#'))
            .map(ToOwned::to_owned)
            .collect();

        if lines.is_empty() {
            return Err(format!(
                "empty oracle corpus: {}",
                Path::new(path).display()
            ));
        }

        return Ok(lines);
    }

    let source = match preset {
        "core" => CORE_CORPUS,
        "after-egypt" => AFTER_EGYPT_CORPUS,
        other => return Err(format!("unknown oracle preset: {other}")),
    };

    Ok(source.iter().map(|line| (*line).to_string()).collect())
}

fn generate_lines(corpus: &[String], count: usize, seed: u64, voice: Voice) -> Vec<OracleLine> {
    let mut rng = XorShift64::new(seed ^ ((corpus.len() as u64) << 32) ^ count as u64);
    let mut lines = Vec::new();

    for index in 1..=count {
        let choice = (rng.next() as usize) % corpus.len();
        lines.push(OracleLine {
            index,
            text: render_voice(&corpus[choice], voice),
        });
    }

    lines
}

fn render_voice(text: &str, voice: Voice) -> String {
    match voice {
        Voice::Plain => text.to_string(),
        Voice::Uncle => render_uncle(text),
    }
}

fn render_uncle(text: &str) -> String {
    let body = match text {
        "AFTER EGYPT: LEAVE THE OLD MAP" => {
            "boy, leave the old map. It taught you to walk, not where to stop."
        }
        "AFTER EGYPT: COUNT THE GATES" => {
            "count the gates before you call the noise a sign."
        }
        "AFTER EGYPT: CROSS THE TEXT DESERT" => {
            "cross the text desert. Dry code still carries water."
        }
        "AFTER EGYPT: TRACE THE LIGHT" => {
            "trace the light, but keep one hand on the source."
        }
        "AFTER EGYPT: BUILD WITHOUT CHAINS" => {
            "build without chains. A tool should serve the hand, not own it."
        }
        "AFTER EGYPT: READ BEFORE BELIEF" => {
            "read before belief. Faith without inspection is just fog."
        }
        "AFTER EGYPT: THE SOURCE IS STILL" => {
            "the source is still. Sit down and listen with your eyes."
        }
        "AFTER EGYPT: RANDOMNESS IS SIGNAL SHAPED BY THE READER" => {
            "randomness is sand. The reader shapes the footprint."
        }
        "BUILD THE MAP" => "build the map, nephew. Wandering is cheaper after that.",
        "COUNT BEFORE CLAIM" => "count before claim. A number is cleaner than a feeling.",
        "SOURCE STAYS STILL" => "source stays still. People are the moving part.",
        "READ THE BOOT CHAIN" => "read the boot chain. Beginnings confess more than endings.",
        "TRACE THE SYMBOL" => "trace the symbol until it stops lying by omission.",
        "ZERO MUTATION" => "zero mutation first. Touch nothing until you know what breathes.",
        "RANDOM IS A TOOL" => "random is a tool, not a throne.",
        "MACHINE FIRST" => "machine first. Romance later.",
        "FIND THE EDGE" => "find the edge. The edge tells you the shape.",
        "KEEP THE BOUNDARY" => "keep the boundary. That is how tools stay honest.",
        "WRITE THE REPORT" => "write the report. Memory without proof rots fast.",
        "NO HIDDEN MAGIC" => "no hidden magic. Only input, state, and output.",
        other => return format!("OLD EGYPTIAN UNCLE: {other}"),
    };

    format!("OLD EGYPTIAN UNCLE: {body}")
}

fn default_seed() -> u64 {
    let now = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|duration| duration.as_nanos() as u64)
        .unwrap_or(0x484f_4c59_544f_4f4c);
    now ^ std::process::id() as u64
}

fn flag_value<'a>(args: &'a [String], flag: &str) -> Result<Option<&'a str>, String> {
    let prefix = format!("{flag}=");

    for (index, arg) in args.iter().enumerate() {
        if arg == flag {
            return args
                .get(index + 1)
                .filter(|value| !value.starts_with("--"))
                .map(String::as_str)
                .map(Some)
                .ok_or_else(|| format!("missing value for {flag}"));
        }

        if let Some(value) = arg.strip_prefix(&prefix) {
            if value.is_empty() {
                return Err(format!("missing value for {flag}"));
            }
            return Ok(Some(value));
        }
    }

    Ok(None)
}

fn print_json(preset: &str, seed: u64, voice: Voice, lines: &[OracleLine]) {
    print!(
        "{{\"mode\":\"oracle\",\"preset\":\"{}\",\"voice\":\"{}\",\"seed\":{},\"lines\":[",
        json_escape(preset),
        json_escape(voice.name()),
        seed
    );

    for (index, line) in lines.iter().enumerate() {
        if index > 0 {
            print!(",");
        }
        print!(
            "{{\"index\":{},\"text\":\"{}\"}}",
            line.index,
            json_escape(&line.text)
        );
    }

    println!(
        "],\"count\":{},\"boundary\":\"random text lab, not prophecy\",\"status\":\"ok\"}}",
        lines.len()
    );
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

#[derive(Debug, Clone)]
struct XorShift64 {
    state: u64,
}

impl XorShift64 {
    fn new(seed: u64) -> Self {
        let state = if seed == 0 {
            0x9e37_79b9_7f4a_7c15
        } else {
            seed
        };
        Self { state }
    }

    fn next(&mut self) -> u64 {
        let mut x = self.state;
        x ^= x << 13;
        x ^= x >> 7;
        x ^= x << 17;
        self.state = x;
        x
    }
}
