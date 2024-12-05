let
    Fonte = grupos,
    linhasSelecionadas = Table.SelectRows(Fonte, each ([FlagGrupo] = "Empresa") and List.Contains({"Empresa:", "CNPJ:", "Endereço:", "Bairro:"}, [Column1] )),
    primeirasLinhas = Table.FirstN(linhasSelecionadas,4),
    camposA = Record.FromList(primeirasLinhas[Column2], primeirasLinhas[Column1]),
    baseCamposB = Table.SelectRows(primeirasLinhas[[Column3], [Column4]], each [Column3] <> null),
    camposB = Record.FromList(baseCamposB[Column4], baseCamposB[Column3]),
    tabela = Table.FromRecords({camposA & camposB}),
    nomesColunas = Table.TransformColumnNames(tabela, each Text.Remove(Text.FromBinary(Text.ToBinary(_, 1251)), ":")),
    tipoAlterado = Table.TransformColumnTypes(nomesColunas,{{"Empresa", type text}, {"CNPJ", type text}, {"Endereco", type text}, {"Bairro", type text}, {"Telefone", type text}, {"Complemento", type text}, {"Municipio", type text}})
in
    tipoAlterado