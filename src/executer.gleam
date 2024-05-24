import gleam/int
import gleam/list
import gleam/result
import gleam/io.{println}
import ast


type Mem = List(Int)

fn load(mem: Mem, i: Int) -> Int {
  case mem |> list.at(i) {
    Ok(val) -> val
    _ -> 0
  }
}

fn store(mem: Mem, i: Int, val: Int) -> Mem {
  let len = list.length(mem)
  case i < len {
    True -> list.concat([list.take(mem, i), [val, ..list.drop(mem, i+1)]])
    False -> list.concat([mem, list.repeat(0, i-len), [val]])
  }
}


fn run_loop(body: ast.StmtList, n: Int, mem: Mem) -> Mem {
  case n {
    0 -> mem
    iters ->
      run_stmts(body, mem)
      |> run_loop(body, iters-1, _)
  }
}

fn run_stmt(stmt: ast.Stmt, mem: Mem) -> Mem {
  case stmt {
    ast.Asgn(res, left, op, right) -> {
      let left = mem |> load(left)
      mem |> store(
        res,
        case op {
          ast.Add -> left + right
          ast.Sub -> case left > right {
            True -> left - right
            False -> 0
          }
        }
      )
    }
    ast.Loop(iters, body) -> run_loop(body, mem |> load(iters), mem)
    ast.While(cond_var, body) ->
      case mem |> load(cond_var) {
        0 -> mem
        _ -> {
          run_stmts(body, mem)
          |> run_stmt(ast.While(cond_var, body), _)
        }
      }
    ast.Debug(id) -> {
      let res = mem |> load(id) |> int.to_string
      println("Debug: x" <> int.to_string(id) <> " = " <> res)
      mem
    }
  }
}

fn run_stmts(stmts: ast.StmtList, mem: Mem) -> Mem {
  case stmts {
    [] -> mem
    [stmt, ..tail] ->
      run_stmt(stmt, mem)
      |> run_stmts(tail, _)
  }
}

pub fn run(stmts: ast.StmtList) -> Int {
  run_stmts(stmts, [])
  |> list.at(0)
  |> result.unwrap(0)
}