// use clap::{Args, Parser, Subcommand};
// use log::debug;

// #[derive(Debug, Parser)]
// #[command(name = "hello-world")]
// /// A demo program for getting started quickly
// struct HelloWorld {
//     #[command(subcommand)]
//     command: Commands,
// }

// #[derive(Debug, Subcommand)]
// enum Commands {
//     Greet(ArgsGreet),
// }

// #[derive(Debug, Args)]
// /// Says hello
// struct ArgsGreet {
//     #[clap(short, long)]
//     greeting: String,
//     #[clap(short, long)]
//     name: String,
// }

// fn greet_cmd(args: &ArgsGreet, _cli: &HelloWorld) {
//     println!("{}, {}", args.greeting, args.name);
// }

// fn main() -> anyhow::Result<()> {
//     env_logger::init();
//     let cli = HelloWorld::parse();
//     debug!("{:?}", &cli);
//     match cli.command {
//         Commands::Greet(ref args) => greet_cmd(&args, &cli),
//     }
//     Ok(())
// }

#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")] // hide console window on Windows in release
#![allow(rustdoc::missing_crate_level_docs)] // it's an example

use eframe::egui;

fn main() -> Result<(), eframe::Error> {
    env_logger::init(); // Log to stderr (if you run with `RUST_LOG=debug`).
    let options = eframe::NativeOptions {
        viewport: egui::ViewportBuilder::default().with_inner_size([320.0, 240.0]),
        ..Default::default()
    };
    eframe::run_native(
        "Confirm exit",
        options,
        Box::new(|_cc| Ok(Box::<MyApp>::default())),
    )
}

#[derive(Default)]
struct MyApp {
    show_confirmation_dialog: bool,
    allowed_to_close: bool,
}

impl eframe::App for MyApp {
    fn update(&mut self, ctx: &egui::Context, _frame: &mut eframe::Frame) {
        egui::CentralPanel::default().show(ctx, |ui| {
            ui.heading("Try to close the window");
        });

        if ctx.input(|i| i.viewport().close_requested()) {
            if self.allowed_to_close {
                // do nothing - we will close
            } else {
                ctx.send_viewport_cmd(egui::ViewportCommand::CancelClose);
                self.show_confirmation_dialog = true;
            }
        }

        if self.show_confirmation_dialog {
            egui::Window::new("Do you want to quit?")
                .collapsible(false)
                .resizable(false)
                .show(ctx, |ui| {
                    ui.horizontal(|ui| {
                        if ui.button("No").clicked() {
                            self.show_confirmation_dialog = false;
                            self.allowed_to_close = false;
                        }

                        if ui.button("Yes").clicked() {
                            self.show_confirmation_dialog = false;
                            self.allowed_to_close = true;
                            ui.ctx().send_viewport_cmd(egui::ViewportCommand::Close);
                        }
                    });
                });
        }
    }
}
