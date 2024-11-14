let
    Fonte = arquivo,
    colunasSelecionadas = Table.SelectColumns(Fonte,{"IndiceGrupo", "Column1"}),
    linhasFiltradas = Table.SelectRows(colunasSelecionadas, each Text.StartsWith([Column1], "Local")),
    localFormatado = Table.TransformColumns(linhasFiltradas, {{"Column1", each Text.AfterDelimiter(_, ": "), type text}}),
    colunasRenomeada = Table.RenameColumns(localFormatado,{{"Column1", "Local Contábil"}})
in
    colunasRenomeada