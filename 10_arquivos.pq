let
    Fonte = Folder.Files(pasta),
    tabelasExtraidas = Table.TransformColumns(Fonte, {{"Content", fx_Arquivos, type table}}),
    tabelasCombinadas = Table.Combine(tabelasExtraidas[Content])
in
    tabelasCombinadas