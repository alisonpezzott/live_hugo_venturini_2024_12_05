let
    Fonte = grupos,
    linhasSelecionadas = Table.SelectRows(Fonte, each ([FlagGrupo] = "Empresa") and Text.StartsWith([Column1], "Relação")),
    colunaSelecionada = linhasSelecionadas[[Column1]],
    colunasRenomeadas = Table.RenameColumns(colunaSelecionada,{{"Column1", "Competencia"}}),
    dataExtraida = Table.TransformColumns(colunasRenomeadas, {{"Competencia", each Date.From( Text.BetweenDelimiters(_, "Período: ", " a ")), type date}})
in
    dataExtraida