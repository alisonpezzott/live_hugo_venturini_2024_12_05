let
    Fonte = grupos,
    add_IndiceFuncionario = Table.AddColumn(Fonte, "IndiceFuncionario", each List.Accumulate(
         List.FirstN(Fonte[Column1], [Indice]), 0,
         (acumulador, atual)=> try if Text.StartsWith(atual, "Func:") then acumulador + 1 else acumulador otherwise acumulador

    )

, Int64.Type),
    preenchidoAbaixo = Table.FillDown(add_IndiceFuncionario,{"Column1"}),
    localRemovido = Table.SelectRows( preenchidoAbaixo, each not Text.StartsWith([Column1], "Local")),
    linhasAgrupadas = Table.Group(localRemovido, {"IndiceFuncionario"}, {{"SubtabelaFuncionario", each _, type table [Column1=nullable text, Column2=any, Column3=nullable text, Column4=nullable text, Column5=any, Column6=any, Column7=nullable date, Column8=nullable text, Column9=any, Column10=nullable number, Column11=nullable text, Column12=nullable text, Indice=number, IndiceLocal=number, IndiceFuncionario=number]}}),
    fx_funcionarioInvocada = Table.TransformColumns(linhasAgrupadas, {
        {"SubtabelaFuncionario", fx_funcionario, type table}
        }),
    subtabelasCombinadas = Table.Combine(fx_funcionarioInvocada[SubtabelaFuncionario]),
    joinLocal = Table.Join(subtabelasCombinadas, {"IndiceLocal"}, locais, {"IndiceLocal"}),
    joinCompetencia = Table.Join( joinLocal, {}, competencia, {}),
    joinEmpresa = Table.Join(joinCompetencia, {}, empresa, {})
in
    joinEmpresa