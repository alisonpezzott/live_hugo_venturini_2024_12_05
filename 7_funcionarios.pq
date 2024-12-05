let
    Fonte = grupos,
    add_FlagFunc = Table.AddColumn(
    Fonte, 
    "FlagFunc", 
     (r)=> List.First(
         List.Select(
             {"Func", "Local"},
             (i) => Text.StartsWith(r[Column1], i)
         )

), type text),
    IndiceFunc = Table.AddColumn(add_FlagFunc, "IndiceFunc", each List.Accumulate(
    List.FirstN(add_FlagFunc[FlagFunc], [Indice]), 0,
    (state, current) => if current = "Func" then state + 1 else state
), Int64.Type),
    linhasSoFuncionarios = Table.SelectRows(IndiceFunc, each ([FlagFunc] <> "Local") and ([FlagGrupo] = "Local")),
    subtabelasAgrupadas = Table.Group(linhasSoFuncionarios, {"IndiceFunc"}, {{"SubtabelasCadaFunc", each _, type table [Column1=nullable text, Column2=any, Column3=nullable text, Column4=nullable text, Column5=any, Column6=any, Column7=nullable date, Column8=nullable text, Column9=any, Column10=nullable number, Column11=nullable text, Column12=nullable text, FlagGrupo=text, Indice=number, IndiceGrupo=number, FlagFunc=text, IndiceFunc=number]}}),
    funcaoInvocada = Table.TransformColumns( subtabelasAgrupadas, {{"SubtabelasCadaFunc", fx_funcionarios, type table}}),
    listaTabelas = funcaoInvocada[SubtabelasCadaFunc],
    funcionariosCombinados = Table.Combine(listaTabelas),
    join_LocalContabil = Table.Join( funcionariosCombinados, {"IndiceGrupo"}, local_contabil, {"IndiceGrupo"}),
    join_Empresa = Table.Join( join_LocalContabil, {}, empresa, {} ),
    join_competencia = Table.Join( join_Empresa, {}, competencia, {})
in
    join_competencia