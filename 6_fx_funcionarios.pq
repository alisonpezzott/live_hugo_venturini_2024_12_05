( subtabela as table ) as table => 
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
    tipoAlterado