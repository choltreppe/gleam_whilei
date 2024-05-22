import gleam/io
import gleam/int

import ast
import parser.{parse}
import executer.{run}


pub fn main() {
  case parse(
    "x0 := x0 + 2;
    x1 := x1 + 3;
    LOOP x1 DO
      LOOP x0 DO
        x0 := x0 + 1
      END
    END"
  ) {
    Ok(prog) -> io.println(run(prog) |> int.to_string)
    Error(e) -> io.println(e |> parser.error_string)
  }
}