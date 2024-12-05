let
    Fonte = grupos[[Column1], [IndiceLocal]],
    linhasLocal = Table.SelectRows(Fonte, each Text.StartsWith([Column1], "Local")),
    localExtraido = Table.TransformColumns(linhasLocal, {{"Column1", each Text.AfterDelimiter(_, ": "), type text}}),
    colunasRenomeadas = Table.RenameColumns(localExtraido, {{"Column1", "LocalContabil"}})
in
    colunasRenomeadas