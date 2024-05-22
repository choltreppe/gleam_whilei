import lineinfo.{type LineInfo}

pub type VarId = Int

pub type Op {Add Sub}

pub type Stmt {
  Asgn(
    res: VarId,
    left: VarId,
    op: Op,
    right: Int
  )
  Loop(iters: VarId, body: StmtList)
  While(cond_var: VarId, body: StmtList)
}

pub type StmtList = List(#(Stmt, LineInfo))