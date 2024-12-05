let
    Fonte = Table.FirstN(planilha_bruta, 4),
    fonte_a = Fonte[[Column1], [Column2]],
    registro_a = Record.FromList(fonte_a[Column2], fonte_a[Column1]),
    fonte_b = Table.SelectRows(Fonte[[Column3], [Column4]], each [Column3] <> null),
    registro_b = Record.FromList(fonte_b[Column4], fonte_b[Column3]),
    tabela = Table.FromRecords({registro_a & registro_b}),
    tipo = Table.TransformColumnTypes(tabela, {
        {"Empresa:", type text}, 
        {"CNPJ:", type text}, 
        {"Endereço:", type text}, 
        {"Bairro:", type text}, 
        {"Telefone:", type text}, 
        {"Complemento:", type text}, 
        {"Município:", type text}
    }),
    colunasRenomeadas = Table.TransformColumnNames(tipo, each Text.Remove(Text.FromBinary(Text.ToBinary(_, 1251)), ":"))
in
    colunasRenomeadas