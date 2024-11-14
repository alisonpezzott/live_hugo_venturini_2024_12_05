let
    Fonte = Excel.Workbook(File.Contents(nome_arquivo)){[Item="Planilha1",Kind="Sheet"]}[Data],
    
    colFlagGrupoAdd = Table.AddColumn(
        Fonte, 
        "FlagGrupo", 
        (r) => List.First(
            List.Select(
                {"Empresa", "Local"}, 
                (i) => Text.StartsWith(r[Column1], i )
            )
        ), 
        type text
    ),

    indiceAdd = Table.AddIndexColumn(colFlagGrupoAdd, "Indice", 1, 1, Int64.Type),
    
    indiceGrupoAdd = Table.AddColumn(
        indiceAdd,
        "IndiceGrupo",
        each List.Accumulate(
            List.FirstN(indiceAdd[FlagGrupo], [Indice]),
            0,
            (acumulador, atual) => 
            if atual <> null
                then acumulador + 1
                else acumulador
        ),
        Int64.Type
    ),

    grupoFill = Table.FillDown(indiceGrupoAdd,{"FlagGrupo"})
in
    grupoFill