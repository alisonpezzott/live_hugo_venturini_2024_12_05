( tabela as table ) as table => 
let
    Fonte = tabela,
    // Fonte = funcionarios{[IndiceFunc=6]}[Funcionarios],
    cabecalhoRegistro = [ 
        Funcionario ID = Fonte[Column2]{0},
        Nome = Fonte[Column3]{0},
        Admissão = Fonte[Column5]{0}, 
        Demissão = Fonte[Column7]{0},
        IndiceGrupo = Fonte[IndiceGrupo]{0},
        Cargo = Fonte[Column2]{1}, 
        Salario = Fonte[Column6]{1},
        Situação = Fonte[Column12]{1}
    ],
    cabecalhoTabela = Table.FromRecords({cabecalhoRegistro}),
    proventosInicial = Table.SelectRows(Table.FillDown(Fonte, {"Column1"}), each ([Column1] = "Proventos:")),
    proventos = Table.SelectColumns(proventosInicial,{"Column3", "Column4", "Column5"}),
    proventosValidos = Table.SelectRows(proventos, each [Column3] <> null and [Column3] <> ""),
    proventosFinal = Table.RenameColumns(proventosValidos,{{"Column3", "Descrição"}, {"Column4", "Quantidade"}, {"Column5", "Valor"}}),
    descontos = Table.SelectColumns(proventosInicial,{"Column8", "Column9", "Column10"}),
    descontosValidos = Table.SelectRows(descontos, each [Column8] <> null and [Column8] <> ""),
    descontoComSinal = Table.TransformColumns(descontosValidos, {{"Column10", each _ * -1, type number}}),
    descontosFinal = Table.RenameColumns(descontoComSinal,{{"Column8", "Descrição"}, {"Column9", "Quantidade"}, {"Column10", "Valor"}}),
    folha = proventosFinal & descontosFinal,
    posicaoImpostos = List.PositionOf(Fonte[Column1], "Base Impostos:"),
    baseImpostosInicial = Table.RemoveFirstN(Fonte, posicaoImpostos + 1),
    baseImpostosRecord = Record.FromList(
    baseImpostosInicial[Column2] & baseImpostosInicial[Column5],
    baseImpostosInicial[Column1] & baseImpostosInicial[Column4]
),
    baseImpostosFinal = Table.FromRecords({baseImpostosRecord}),
    tabelasCombinadas = List.Accumulate({folha, baseImpostosFinal}, cabecalhoTabela, (state, current) => Table.Join(state, {}, current, {})),
    tipoAlterado = Table.TransformColumnTypes(tabelasCombinadas,{{"Funcionario ID", type text}, {"Nome", type text}, {"Admissão", type date}, {"Demissão", type date}, {"IndiceGrupo", Int64.Type}, {"Cargo", type text}, {"Salario", Currency.Type}, {"Situação", type text}, {"Descrição", type text}, {"Quantidade", type text}, {"Valor", Currency.Type}, {"IRRF", Currency.Type}, {"INSS", Currency.Type}, {"INSS Empresa", Currency.Type}, {"FGTS GFIP", Currency.Type}, {"FGTS GRRF", Currency.Type}, {"PIS", Currency.Type}})
in
    tipoAlterado