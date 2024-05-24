import gleam/int
import gleam/string
import gleam/regex
import gleam/result

import ast


type LineInfo {
  LineInfo(line: Int, col: Int)
}

pub opaque type ParsingError {
  UnexpectedChar(String, LineInfo)
  UnexpectedToken(Token, LineInfo)
  UnexpectedEnd
}

type ParsingResult(a) = Result(a, ParsingError)

pub fn error_msg(e: ParsingError) -> String {
  case e {
    UnexpectedEnd -> "unexpected end of file"
    _ -> {
      let #(info, msg) = case e {
        UnexpectedChar(c, info) -> #(info, "unexpected chararcter '" <> c <> "'")
        UnexpectedToken(token, info) -> #(info, "unexpected token " <> token_to_string(token))
        UnexpectedEnd -> panic as "already covered"
      }
      int.to_string(info.line) <> ":" <> int.to_string(info.col) <> " Error: " <> msg
    }
  }
}


type Token {
  Num(Int)
  Var(ast.VarId)
  Op(ast.Op)
  Semi
  Asgn
  GtEq
  Loop
  While
  Do
  End
  Debug
}

type Tokens = List(#(Token, LineInfo))

fn token_to_string(token: Token) -> String {
  case token {
    Num(val) -> int.to_string(val)
    Var(id) -> "x" <> int.to_string(id)
    Op(op) -> case op {
      ast.Add -> "+"
      ast.Sub -> "-"
    }
    Semi -> ";"
    Asgn -> ":="
    GtEq -> ">="
    Loop -> "LOOP"
    While -> "WHILE"
    Do -> "DO"
    End -> "END"
    Debug -> "DEBUG"
  }
}

fn parse_num(code: String, info: LineInfo) -> ParsingResult(#(Int, String)) {
  // I would like to do this just once in global scope
  let assert Ok(num_regex) = regex.from_string("^[0-9]+")

  case regex.scan(num_regex, code) {
    [regex.Match(content, _)] -> {
      let assert Ok(id) = int.parse(content)
      Ok(#(id, code |> string.drop_left(string.length(content))))
    }
    [] -> case string.first(code) {
      Ok(c) -> UnexpectedChar(c, info)
      _ -> UnexpectedEnd
    } |> Error

    _ -> panic
  }
}

fn tokenize(code: String, info: LineInfo) -> ParsingResult(Tokens) {
  case code {
    "" -> Ok([#(End, info)]) // putting End at the end to simplify parsing
    "\n" <> tail -> tokenize(tail, LineInfo(info.line + 1, 1))
    _ -> {
      case
        case code |> string.trim_left {
          ";" <> tail -> Ok(#(Semi, tail))
          ":=" <> tail -> Ok(#(Asgn, tail))
          ">=" <> tail -> Ok(#(GtEq, tail))
          "+" <> tail -> Ok(#(Op(ast.Add), tail))
          "-" <> tail -> Ok(#(Op(ast.Sub), tail))
          "LOOP" <> tail -> Ok(#(Loop, tail))
          "WHILE" <> tail -> Ok(#(While, tail))
          "DO" <> tail -> Ok(#(Do, tail))
          "END" <> tail -> Ok(#(End, tail))
          "DEBUG" <> tail -> Ok(#(Debug, tail))
          "x" <> tail -> case parse_num(tail, info) {
            Ok(#(id, tail)) -> Ok(#(Var(id), tail))
            Error(e) -> Error(e)
          }
          code -> case parse_num(code, info) {
            Ok(#(val, tail)) -> Ok(#(Num(val), tail))
            Error(e) -> Error(e)
          }
        }
      {
        Ok(#(token, tail)) -> {
          let info = LineInfo(info.line, info.col + string.length(code) - string.length(tail))
          tokenize(tail, info)
          |> result.map(fn(tokens){[#(token, info), ..tokens]})
        }
        Error(e) -> Error(e)
      }
    }
  }
}


fn parse_stmt(tokens: Tokens) -> ParsingResult(#(ast.Stmt, Tokens)) {
  case tokens {
    [#(Var(res), _), #(Asgn, _), #(Var(left), _), #(Op(op), _), #(Num(right), _), ..tail] ->
      Ok(#(ast.Asgn(res, left, op, right), tail))
    [#(Loop, _), #(Var(iters), _), #(Do, _), ..tail] -> {
      use #(body, tail) <- result.map(parse_stmt_list(tail))
      #(ast.Loop(iters, body), tail)
    }
    [#(While, _), #(Var(cond_var), _), #(GtEq, _), #(Num(0), _), #(Do, _), ..tail] -> {
      use #(body, tail) <- result.map(parse_stmt_list(tail))
      #(ast.While(cond_var, body), tail)
    }
    [#(Debug, _), #(Var(id), _), ..tail] ->
      Ok(#(ast.Debug(id), tail))
    [#(token, info), .._] -> Error(UnexpectedToken(token, info))
    [] -> panic
  }
}

fn parse_stmt_list(tokens: Tokens) -> ParsingResult(#(ast.StmtList, Tokens)) {
  use #(stmt, tail) <- result.try(parse_stmt(tokens))
  case tail {
    [#(Semi, _), ..tail] -> {
      use #(stmts, tail) <- result.map(parse_stmt_list(tail))
      #([stmt, ..stmts], tail)
    }
    [#(End, _), ..tail] -> Ok(#([stmt], tail))
    [#(token, info), .._] -> Error(UnexpectedToken(token, info))
    [] -> panic
  }
}

pub fn parse(code: String) -> Result(ast.StmtList, ParsingError) {
  use tokens <- result.try(tokenize(code, LineInfo(line: 1, col: 1)))
  use #(stmts, tail) <- result.try(parse_stmt_list(tokens))
  case tail {
    [] -> Ok(stmts)
    [#(End, info), .._] -> Error(UnexpectedToken(End, info))
    _ -> panic
  }
}