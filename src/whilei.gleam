import gleam/io
import gleam/int
import argv
import simplifile.{read}

import parser.{parse}
import executer.{run}


pub fn main() {
  case argv.load().arguments {
    [filepath] -> case read(filepath) {
      Ok(code) -> case parse(code) {
        Ok(prog) -> io.println(run(prog) |> int.to_string)
        Error(e) -> io.println_error(e |> parser.error_msg)
      }
      _ -> io.println_error("Couldn't open file " <> filepath)
    }
    _ -> io.println("Usage: whilei <file>")
  }
}