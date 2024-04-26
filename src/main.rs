use clap::{Args, Parser, Subcommand};
use log::debug;

#[derive(Debug, Parser)]
#[command(name = "hello-world")]
/// A demo program for getting started quickly
struct HelloWorld {
    #[command(subcommand)]
    command: Commands,
}

#[derive(Debug, Subcommand)]
enum Commands {
    Greet(ArgsGreet),
}

#[derive(Debug, Args)]
/// Says hello
struct ArgsGreet {
    #[clap(short, long)]
    greeting: String,
    #[clap(short, long)]
    name: String,
}

fn greet_cmd(args: &ArgsGreet, _cli: &HelloWorld) {
    println!("{}, {}", args.greeting, args.name);
}

fn main() -> anyhow::Result<()> {
    env_logger::init();
    let cli = HelloWorld::parse();
    debug!("{:?}", &cli);
    match cli.command {
        Commands::Greet(ref args) => greet_cmd(&args, &cli),
    }
    Ok(())
}
