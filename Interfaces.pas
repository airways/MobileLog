unit Interfaces;

interface

uses
  System.Generics.Collections,
  Model;

type
  IMainView = interface
    procedure ShowError(Message: string; Fatal: boolean);
    procedure UpdateItems(LogItems: TList<TLogItem>);
  end;

  IEditView = interface
    procedure NewItem();
    procedure EditItem(Item: TLogItem);
  end;

  IMainController = interface
    procedure RegisterMainView(View: IMainView);
    procedure RegisterEditView(View: IEditView);

    function WordToTag(word: string): Integer;
    function TagToWord(tag: Integer): string;

    procedure NewItem();
    procedure EditItem(Item: TLogItem);

    procedure SaveItem(Item: TLogItem);
    procedure DeleteItem(Item: TLogItem);
  end;

implementation

end.
