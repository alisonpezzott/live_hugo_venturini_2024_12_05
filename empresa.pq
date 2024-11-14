let
    Fonte = arquivo,
    empresa = Table.SelectRows(Fonte, each ([FlagGrupo] = "Empresa")),
    primeirasLinhas = Table.FirstN(empresa, 4),
    grupoA = Table.SelectColumns(primeirasLinhas,{"Column1", "Column2"}),
    nomesA = grupoA[Column1],
    valoresA = grupoA[Column2],
    registroA = Record.FromList(valoresA, nomesA),
    grupoB = Table.SelectColumns(primeirasLinhas,{"Column3", "Column4"}),
    grupoBFiltrado = Table.SelectRows(grupoB, each [Column3] <> null and [Column3] <> ""),
    nomesB = grupoBFiltrado[Column3],
    valoresB = grupoBFiltrado[Column4],
    registroB = Record.FromList(valoresB, nomesB),
    registroCombinado = registroA & registroB,
    tabela = Table.FromRecords({registroCombinado}),
    tipo = Table.TransformColumnTypes(tabela,{{"Empresa:", type text}, {"CNPJ:", type text}, {"Endereço:", type text}, {"Bairro:", type text}, {"Telefone:", type text}, {"Complemento:", type text}, {"Município:", type text}}),
    nomesColunaFormatados = Table.TransformColumnNames(tipo, each Text.Remove(_, ":"))
in
    nomesColunaFormatados