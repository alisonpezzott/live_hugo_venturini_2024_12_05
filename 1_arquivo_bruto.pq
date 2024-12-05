let
    Fonte = bases[Content]{0},
    Excel = Excel.Workbook(Fonte){[Item="Planilha1",Kind="Sheet"]}[Data]
in
    Excel