import gleam/int

pub type LineInfo {
  LineInfo(line: Int, col: Int)
}

pub fn error_msg(at info: LineInfo, msg msg: String) -> String {
  int.to_string(info.line) <> ":" <> int.to_string(info.col) <> " Error: " <> msg
}