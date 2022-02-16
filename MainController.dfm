object dmMain: TdmMain
  OldCreateOrder = False
  Height = 150
  Width = 215
  object ActionList1: TActionList
    Left = 24
    Top = 24
    object aNewItem: TAction
      Category = 'Items'
      Text = '+'
      ShortCut = 16462
      OnExecute = aNewItemExecute
    end
    object aEditItem: TAction
      Category = 'Items'
      Text = '&Edit Item'
      OnExecute = aEditItemExecute
    end
  end
end
