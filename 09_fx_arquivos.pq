(arquivo as binary) as table =>
    let
        planilha_bruta =
            let
                Fonte = Excel.Workbook(arquivo)[Data]{0}
            in
                Fonte,
        grupos =
            let
                Fonte = Table.Skip(planilha_bruta, 5),
                add_Indice = Table.AddIndexColumn(Fonte, "Indice", 1, 1, Int64.Type),
                add_IndiceLocal = Table.AddColumn(
                    add_Indice,
                    "IndiceLocal",
                    each List.Accumulate(
                        List.FirstN(add_Indice[Column1], [Indice]),
                        0,
                        (acumulador, atual) =>
                            try

                                    if Text.StartsWith(atual, "Local") then
                                        acumulador + 1
                                    else
                                        acumulador
                            otherwise
                                acumulador
                    ),
                    Int64.Type
                )
            in
                add_IndiceLocal,
        Fonte = grupos,
        add_IndiceFuncionario = Table.AddColumn(
            Fonte,
            "IndiceFuncionario",
            each List.Accumulate(
                List.FirstN(Fonte[Column1], [Indice]),
                0,
                (acumulador, atual) =>
                    try
                        if Text.StartsWith(atual, "Func:") then acumulador + 1 else acumulador
                    otherwise
                        acumulador
            ),
            Int64.Type
        ),
        preenchidoAbaixo = Table.FillDown(add_IndiceFuncionario, {"Column1"}),
        localRemovido = Table.SelectRows(
            preenchidoAbaixo,
            each not Text.StartsWith([Column1], "Local")
        ),
        linhasAgrupadas = Table.Group(
            localRemovido,
            {"IndiceFuncionario"},
            {
                {
                    "SubtabelaFuncionario",
                    each _,
                    type table [
                        Column1 = nullable text,
                        Column2 = any,
                        Column3 = nullable text,
                        Column4 = nullable text,
                        Column5 = any,
                        Column6 = any,
                        Column7 = nullable date,
                        Column8 = nullable text,
                        Column9 = any,
                        Column10 = nullable number,
                        Column11 = nullable text,
                        Column12 = nullable text,
                        Indice = number,
                        IndiceLocal = number,
                        IndiceFuncionario = number
                    ]
                }
            }
        ),
        fx_funcionario = (subtabela as table) as table =>
            let
                Fonte = subtabela,
                //Fonte = funcionarios[SubtabelaFuncionario]{0},
                cabecalho = Table.FromRecords(
                    {
                        [
                            FuncionarioId   = Fonte[Column2]{0},
                            FuncionarioNome = Fonte[Column3]{0},
                            Admissao        = Fonte[Column5]{0},
                            Demissao        = Fonte[Column7]{0},
                            IndiceLocal     = Fonte[IndiceLocal]{0},
                            Cargo           = Fonte[Column2]{1},
                            SalarioNominal  = Fonte[Column6]{1},
                            Situacao        = Fonte[Column12]{1}
                        ]
                    }
                ),
                proventosFonte = Table.SelectRows(Fonte, each [Column1] = "Proventos:"),
                creditosValidos = Table.SelectRows(
                    proventosFonte[[Column3], [Column4], [Column5]],
                    each [Column3] <> null
                ),
                creditos = Table.RenameColumns(
                    creditosValidos,
                    {{"Column3", "Descricao"}, {"Column4", "Qtde"}, {"Column5", "Valor"}}
                ),
                descontosValidos = Table.SelectRows(
                    proventosFonte[[Column8], [Column9], [Column10]],
                    each [Column8] <> null
                ),
                descontos = Table.RenameColumns(
                    descontosValidos,
                    {{"Column8", "Descricao"}, {"Column9", "Qtde"}, {"Column10", "Valor"}}
                ),
                proventos = creditos & descontos,
                posicaoImpostos = List.PositionOf(Fonte[Column1], "Base Impostos:") + 1,
                impostosFonte = Table.Skip(Fonte, posicaoImpostos),
                impostos = Table.FromColumns(
                    {
                        impostosFonte[Column1] & impostosFonte[Column4],
                        impostosFonte[Column2] & impostosFonte[Column5]
                    },
                    {"Descricao", "Valor"}
                ),
                valores = proventos & impostos,
                join_cabecalho = Table.Join(cabecalho, {}, valores, {}),
                tipoAlterado = Table.TransformColumnTypes(
                    join_cabecalho,
                    {
                        {"Admissao", type date},
                        {"FuncionarioId", type text},
                        {"FuncionarioNome", type text},
                        {"Demissao", type date},
                        {"IndiceLocal", Int64.Type},
                        {"Cargo", type text},
                        {"SalarioNominal", Currency.Type},
                        {"Situacao", type text},
                        {"Descricao", type text},
                        {"Qtde", type number},
                        {"Valor", Currency.Type}
                    }
                )
            in
                tipoAlterado,
        fx_funcionarioInvocada = Table.TransformColumns(
            linhasAgrupadas,
            {{"SubtabelaFuncionario", fx_funcionario, type table}}
        ),
        subtabelasCombinadas = Table.Combine(fx_funcionarioInvocada[SubtabelaFuncionario]),
        locais =
            let
                Fonte = grupos[[Column1], [IndiceLocal]],
                linhasLocal = Table.SelectRows(Fonte, each Text.StartsWith([Column1], "Local")),
                localExtraido = Table.TransformColumns(
                    linhasLocal,
                    {{"Column1", each Text.AfterDelimiter(_, ": "), type text}}
                ),
                colunasRenomeadas = Table.RenameColumns(
                    localExtraido,
                    {{"Column1", "LocalContabil"}}
                )
            in
                colunasRenomeadas,
        joinLocal = Table.Join(subtabelasCombinadas, {"IndiceLocal"}, locais, {"IndiceLocal"}),
        competencia =
            let
                Fonte = planilha_bruta,
                linhasSelecionada = Table.Range(Fonte, 4, 1)[[Column1]],
                dataExtraida = Table.TransformColumns(
                    linhasSelecionada,
                    {{"Column1", each Date.From(Text.BetweenDelimiters(_, ": ", " a ")), type date}}
                ),
                colunaRenomeada = Table.RenameColumns(dataExtraida, {{"Column1", "Competencia"}})
            in
                colunaRenomeada,
        joinCompetencia = Table.Join(joinLocal, {}, competencia, {}),
        empresa =
            let
                Fonte = Table.FirstN(planilha_bruta, 4),
                fonte_a = Fonte[[Column1], [Column2]],
                registro_a = Record.FromList(fonte_a[Column2], fonte_a[Column1]),
                fonte_b = Table.SelectRows(Fonte[[Column3], [Column4]], each [Column3] <> null),
                registro_b = Record.FromList(fonte_b[Column4], fonte_b[Column3]),
                tabela = Table.FromRecords({registro_a & registro_b}),
                tipo = Table.TransformColumnTypes(
                    tabela,
                    {
                        {"Empresa:", type text},
                        {"CNPJ:", type text},
                        {"Endereço:", type text},
                        {"Bairro:", type text},
                        {"Telefone:", type text},
                        {"Complemento:", type text},
                        {"Município:", type text}
                    }
                ),
                colunasRenomeadas = Table.TransformColumnNames(
                    tipo,
                    each Text.Remove(Text.FromBinary(Text.ToBinary(_, 1251)), ":")
                )
            in
                colunasRenomeadas,
        joinEmpresa = Table.Join(joinCompetencia, {}, empresa, {})
    in
        joinEmpresa