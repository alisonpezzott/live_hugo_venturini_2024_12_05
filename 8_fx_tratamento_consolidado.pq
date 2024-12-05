( arquivo as binary ) as table =>
let
    arquivo_bruto_int = 
    let
        Fonte = arquivo,
        Excel = Excel.Workbook(Fonte){[Item="Planilha1",Kind="Sheet"]}[Data]
    in
        Excel,
    grupos_int = 
    let
        Fonte = arquivo_bruto_int,
        add_FlagGrupo = Table.AddColumn(Fonte, "FlagGrupo", (r)=> List.First(
        List.Select(
            {"Empresa", "Local"},
            (i) => Text.StartsWith( r[Column1], i )
        )
        ),
        type text
    ),
        add_Index = Table.AddIndexColumn(add_FlagGrupo, "Indice", 1, 1, Int64.Type),
        add_IndiceGrupo = Table.AddColumn(add_Index, 
        "IndiceGrupo", 
        each List.Accumulate(
        List.FirstN(add_Index[FlagGrupo], [Indice]),
        0,
        (state, current) => if current <> null then state + 1 else state 
        ), 
    Int64.Type
    ),
        flagGrupoPreenchidoAbaixo = Table.FillDown(add_IndiceGrupo,{"FlagGrupo"})
    in
        flagGrupoPreenchidoAbaixo,
    
    add_FlagFunc = Table.AddColumn(
    grupos_int, 
    "FlagFunc", 
     (r)=> List.First(
         List.Select(
             {"Func", "Local"},
             (i) => Text.StartsWith(r[Column1], i)
         )

), type text),
    IndiceFunc = Table.AddColumn(add_FlagFunc, "IndiceFunc", each List.Accumulate(
    List.FirstN(add_FlagFunc[FlagFunc], [Indice]), 0,
    (state, current) => if current = "Func" then state + 1 else state
), Int64.Type),
    linhasSoFuncionarios = Table.SelectRows(IndiceFunc, each ([FlagFunc] <> "Local") and ([FlagGrupo] = "Local")),
    subtabelasAgrupadas = Table.Group(linhasSoFuncionarios, {"IndiceFunc"}, {{"SubtabelasCadaFunc", each _, type table [Column1=nullable text, Column2=any, Column3=nullable text, Column4=nullable text, Column5=any, Column6=any, Column7=nullable date, Column8=nullable text, Column9=any, Column10=nullable number, Column11=nullable text, Column12=nullable text, FlagGrupo=text, Indice=number, IndiceGrupo=number, FlagFunc=text, IndiceFunc=number]}}),

fx_funcionarios_int =( subtabela as table ) as table => 
    let
        Fonte = subtabela,
        //Fonte = funcionarios{[IndiceFunc=2]}[SubtabelasCadaFunc],
        cabecalho = Table.FromRecords({[
        FuncionarioID = Fonte[Column2]{0},
        Nome = Fonte[Column3]{0},
        Admissao = Fonte[Column5]{0},
        Demissao = Fonte[Column7]{0},
        Cargo = Fonte[Column2]{1},
        SalarioBase = Fonte[Column6]{1}, 
        Situacao = Fonte[Column12]{1},
        IndiceGrupo =  Fonte[IndiceGrupo]{0}
    ]}),
        proventosInicial = Table.SelectRows(Table.FillDown(Fonte,{"Column1"}), each ([Column1] = "Proventos:")),
        colunasProventos = proventosInicial[[Column3], [Column4], [Column5]],
        proventosValidos = Table.SelectRows(colunasProventos, each [Column3] <> null and [Column3] <> ""),
        proventos = Table.RenameColumns(proventosValidos,{{"Column3", "Descricao"}, {"Column4", "Qtde"}, {"Column5", "Valor"}}),
        colunasDescontos = proventosInicial[[Column8], [Column9], [Column10]],
        descontosValidos = Table.SelectRows(colunasDescontos, each [Column8] <> null and [Column8] <> ""),
        descontosComSinal = Table.TransformColumns(descontosValidos, {{"Column10", each _ * -1, type number}}),
        descontos = Table.RenameColumns(descontosComSinal,{{"Column8", "Descricao"}, {"Column9", "Qtde"}, {"Column10", "Valor"}}),
        posicaoImpostos = List.PositionOf(Fonte[Column1], "Base Impostos:"),
        baseImpostos = Table.Skip(Fonte, posicaoImpostos + 1),
        impostos = Table.FromColumns( {baseImpostos[Column1] & baseImpostos[Column4], baseImpostos[Column2] & baseImpostos[Column5]}, {"Descricao", "Valor"}),
        folha = proventos & descontos & impostos,
        merge = Table.Join(cabecalho, {}, folha, {}),
        tipoAlterado = Table.TransformColumnTypes(merge,{{"FuncionarioID", type text}, {"Nome", type text}, {"Admissao", type date}, {"Demissao", type date}, {"Cargo", type text}, {"SalarioBase", Currency.Type}, {"Situacao", type text}, {"IndiceGrupo", Int64.Type}, {"Descricao", type text}, {"Qtde", type text}, {"Valor", Currency.Type}})
    in
        tipoAlterado,

    funcaoInvocada = Table.TransformColumns( subtabelasAgrupadas, {{"SubtabelasCadaFunc", fx_funcionarios_int, type table}}),
    listaTabelas = funcaoInvocada[SubtabelasCadaFunc],
    funcionariosCombinados = Table.Combine(listaTabelas),

    local_contabil_int = 
    let
        Fonte = grupos_int[[Column1], [IndiceGrupo]],
        linhasLocal = Table.SelectRows( Fonte, each Text.StartsWith([Column1], "Local")),
        localExtraido = Table.TransformColumns(linhasLocal, {{"Column1", each Text.AfterDelimiter(_, ": "), type text}}),
        colunasRenomeadas = Table.RenameColumns(localExtraido,{{"Column1", "LocalContabil"}})
    in
        colunasRenomeadas,

    join_localContabil = Table.Join( funcionariosCombinados, {"IndiceGrupo"}, local_contabil_int, {"IndiceGrupo"}), 

    
    empresa_int = 
    let
        Fonte = grupos_int,
        linhasSelecionadas = Table.SelectRows(Fonte, each ([FlagGrupo] = "Empresa") and List.Contains({"Empresa:", "CNPJ:", "Endereço:", "Bairro:"}, [Column1] )),
        primeirasLinhas = Table.FirstN(linhasSelecionadas,4),
        camposA = Record.FromList(primeirasLinhas[Column2], primeirasLinhas[Column1]),
        baseCamposB = Table.SelectRows(primeirasLinhas[[Column3], [Column4]], each [Column3] <> null),
        camposB = Record.FromList(baseCamposB[Column4], baseCamposB[Column3]),
        tabela = Table.FromRecords({camposA & camposB}),
        nomesColunas = Table.TransformColumnNames(tabela, each Text.Remove(Text.FromBinary(Text.ToBinary(_, 1251)), ":")),
        tipoAlterado = Table.TransformColumnTypes(nomesColunas,{{"Empresa", type text}, {"CNPJ", type text}, {"Endereco", type text}, {"Bairro", type text}, {"Telefone", type text}, {"Complemento", type text}, {"Municipio", type text}})
    in
        tipoAlterado,

    join_empresa = Table.Join( join_localContabil, {}, empresa_int, {} ),

    competencia_int = 
    let
        Fonte = grupos_int,
        linhasSelecionadas = Table.SelectRows(Fonte, each ([FlagGrupo] = "Empresa") and Text.StartsWith([Column1], "Relação")),
        colunaSelecionada = linhasSelecionadas[[Column1]],
        colunasRenomeadas = Table.RenameColumns(colunaSelecionada,{{"Column1", "Competencia"}}),
        dataExtraida = Table.TransformColumns(colunasRenomeadas, {{"Competencia", each Date.From( Text.BetweenDelimiters(_, "Período: ", " a ")), type date}})
    in
        dataExtraida,


    join_competencia = Table.Join( join_empresa, {}, competencia_int, {})
in
    join_competencia