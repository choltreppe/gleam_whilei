import gleeunit
import gleeunit/should
import gleam/int
import gleam/string
import gleam/list
import simplifile.{get_files, read}

import parser.{parse}
import executer.{run}


pub fn main() {
  gleeunit.main()
}

pub fn interpreter_test() {
  let assert Ok(files) = get_files("examples")
  use file <- list.map(files)
  let assert Ok(#(file_no_ext, _)) = file |> string.split_once(".")
  let assert Ok(#(_, res_str)) = file_no_ext |> string.split_once("_")
  let assert Ok(res) = int.parse(res_str)
  case read(file) {
    Ok(code) -> case parse(code) {
      Ok(prog) -> run(prog) |> should.equal(res)
      _ -> should.fail()
    }
    _ -> should.fail()
  }
}
