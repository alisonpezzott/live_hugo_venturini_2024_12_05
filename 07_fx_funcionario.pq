(subtabela as table) as table =>

let
    Fonte = subtabela,
    cabecalho = Table.FromRecords({ 
        [
            FuncionarioId = Fonte[Column2]{0},
            FuncionarioNome = Fonte[Column3]{0},
            Admissao = Fonte[Column5]{0},
            Demissao = Fonte[Column7]{0},
            IndiceLocal = Fonte[IndiceLocal]{0},
            Cargo = Fonte[Column2]{1},
            SalarioNominal = Fonte[Column6]{1},
            Situacao = Fonte[Column12]{1}
        ]
    }),
    proventosFonte = Table.SelectRows(Fonte, each [Column1] = "Proventos:"),
    creditosValidos = Table.SelectRows(proventosFonte[[Column3], [Column4], [Column5]], each [Column3] <> null),
    creditos = Table.RenameColumns(creditosValidos, {{"Column3", "Descricao"}, {"Column4", "Qtde"}, {"Column5", "Valor"}}),
    descontosValidos = Table.SelectRows(proventosFonte[[Column8], [Column9], [Column10]], each [Column8] <> null),
    descontos = Table.RenameColumns(descontosValidos, {{"Column8", "Descricao"}, {"Column9", "Qtde"}, {"Column10", "Valor"}}),
    proventos = creditos & descontos,
    posicaoImpostos = List.PositionOf(Fonte[Column1], "Base Impostos:") + 1,
    impostosFonte = Table.Skip(Fonte, posicaoImpostos),
    impostos = Table.FromColumns({impostosFonte[Column1] & impostosFonte[Column4], impostosFonte[Column2] & impostosFonte[Column5]}, {"Descricao", "Valor"}),
    valores = proventos & impostos,
    join_cabecalho = Table.Join(cabecalho, {}, valores, {}),
    tipoAlterado = Table.TransformColumnTypes(join_cabecalho, {
        {"Admissao", type date}, 
        {"FuncionarioId", type text}, 
        {"FuncionarioNome", type text}, 
        {"Demissao", type date}, 
        {"IndiceLocal", Int64.Type}, 
        {"Cargo", type text}, 
        {"SalarioNominal", Currency.Type}, 
        {"Situacao", type text}, 
        {"Descricao", type text}, 
        {"Qtde", type text}, 
        {"Valor", Currency.Type}
    })
in
    tipoAlterado