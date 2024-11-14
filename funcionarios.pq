let
    Fonte = arquivo,
    flagFuncAdd = Table.AddColumn(Fonte, "FlagFunc", (r) => List.First(List.Select({"Func", "Local"}, (i) => Text.StartsWith(r[Column1], i ))), type text),
    indiceFuncAdd = Table.AddColumn(flagFuncAdd, "IndiceFunc", each List.Accumulate(List.FirstN(flagFuncAdd[FlagFunc], [Indice]), 0, (state, current)=> if current = "Func" then state + 1 else state)),
    linhasFiltradas = Table.SelectRows(indiceFuncAdd, each ([FlagFunc] <> "Local") and ([FlagGrupo] = "Local")),
    colunasRemovidas = Table.RemoveColumns(linhasFiltradas,{"FlagGrupo", "Indice", "FlagFunc"}),
    funcionarios = Table.Group(colunasRemovidas, {"IndiceFunc"}, {{"Funcionarios", each _, type table }}),
    funcionariosTratados = Table.AddColumn(funcionarios, "FuncionariosTratados", each fx_funcionarios([Funcionarios])),
    funcionariosCombinados = Table.Combine(funcionariosTratados[FuncionariosTratados]),
    localContabilAdd = Table.Join(funcionariosCombinados, "IndiceGrupo", local_contabil, "IndiceGrupo"),
    empresaAdd = Table.Join(localContabilAdd, {}, empresa, {})
in
    empresaAdd