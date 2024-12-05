let
    Fonte = planilha_bruta,
    linhasSelecionada = Table.Range(Fonte, 4, 1)[[Column1]],
    dataExtraida = Table.TransformColumns(linhasSelecionada, {
        {"Column1", each Date.From(Text.BetweenDelimiters(_, ": ", " a ")), type date}
        }),
    colunaRenomeada = Table.RenameColumns(dataExtraida,{{"Column1", "Competencia"}})
in
    colunaRenomeada