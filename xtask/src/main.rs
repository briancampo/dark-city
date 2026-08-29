//! Automation task runner for the Dark City repository (`cargo xtask check`).

use std::process::Command;

fn main() {
    let mut args = std::env::args().skip(1);
    let task = args.next().unwrap_or_else(|| "help".to_string());

    match task.as_str() {
        "check" => run_check(),
        "help" | "--help" | "-h" => print_help(),
        other => {
            eprintln!("Unknown xtask command: {}", other);
            print_help();
            std::process::exit(1);
        }
    }
}

fn print_help() {
    println!("Dark Factory xtask runner");
    println!("Usage: cargo xtask <command>");
    println!();
    println!("Commands:");
    println!("  check    Run fmt, clippy (-D warnings), and test suite across workspace");
    println!("  help     Print this help message");
}

fn run_check() {
    println!("=== 1. Checking code formatting (cargo fmt --check) ===");
    run_cmd("cargo", &["fmt", "--all", "--check"]);

    println!("=== 2. Running clippy with strict warnings (cargo clippy --all-targets -- -D warnings) ===");
    run_cmd(
        "cargo",
        &[
            "clippy",
            "--workspace",
            "--all-targets",
            "--",
            "-D",
            "warnings",
        ],
    );

    println!("=== 3. Running tests ===");
    // Attempt nextest if installed, otherwise cargo test
    let has_nextest = Command::new("cargo")
        .args(["nextest", "--version"])
        .output()
        .map(|o| o.status.success())
        .unwrap_or(false);

    if has_nextest {
        run_cmd("cargo", &["nextest", "run", "--workspace"]);
    } else {
        run_cmd("cargo", &["test", "--workspace"]);
    }

    println!("\n✅ All workspace checks passed successfully!");
}

fn run_cmd(cmd: &str, args: &[&str]) {
    let status = Command::new(cmd)
        .args(args)
        .status()
        .unwrap_or_else(|e| panic!("Failed to execute {} {:?}: {}", cmd, args, e));

    if !status.success() {
        eprintln!("\n❌ Command failed: {} {}", cmd, args.join(" "));
        std::process::exit(status.code().unwrap_or(1));
    }
}
