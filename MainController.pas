unit MainController;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  Model, Interfaces, System.Actions, FMX.ActnList;

type
  TdmMain = class(TDataModule, IMainController)
    ActionList1: TActionList;
    aNewItem: TAction;
    aEditItem: TAction;
    procedure aNewItemExecute(Sender: TObject);
    procedure aEditItemExecute(Sender: TObject);
  private
    { Private declarations }
    sDataFile: string;
    Items: TList<TLogItem>;
    MainViews: TList<IMainView>;
    EditViews: TList<IEditVIew>;
    Tags: TStringList;
    procedure LoadData();
    procedure SaveData();

  public
    { Public declarations }
    function WordToTag(word: string): Integer;
    function TagToWord(tag: Integer): string;
    procedure RegisterMainView(View: IMainView);
    procedure RegisterEditView(View: IEditView);
    procedure NewItem();
    procedure EditItem(Item: TLogItem);
    procedure SaveItem(Item: TLogItem);
    procedure DeleteItem(Item: TLogItem);
  end;

var
  dmMain: TdmMain;

implementation

{%CLASSGROUP 'FMX.Controls.TControl'}

{$R *.dfm}

uses
  System.Types,
  System.DateUtils,
  System.StrUtils,
  System.IOUtils,
  System.Variants,
  FMX.Types,
  Note;

procedure TdmMain.RegisterMainView(View: IMainView);
begin
  if MainViews = nil then
  begin
    MainViews := TList<IMainView>.Create();
  end;
  MainViews.Add(View);
  if MainViews.Count = 1 then
  begin
    LoadData;
  end;
end;


procedure TdmMain.RegisterEditView(View: IEditView);
begin
  if EditViews = nil then
  begin
    EditViews := TList<IEditView>.Create();
  end;
  EditViews.Add(View);
end;


function TdmMain.WordToTag(word: string): Integer;
var
  i: integer;
begin
  if word = '' then
  begin
    Result := 0;
  end else begin
    Result := 1;
    word := UpperCase(word);
    for i := 0 to word.Length do
    begin
      Result := Result * 26 + integer(word.Chars[i]) - 10;
    end;
  end;
end;

function TdmMain.TagToWord(tag: Integer): string;
var
  i: integer;
  tagName: string;
begin
  for i := 1 to Tags.Count-1 do
  begin
    tagName := Tags[i];
    if WordToTag(tagName) = tag then
    begin
      Result := tagName;
      Break;
    end;
  end;
end;

procedure TdmMain.LoadData();
var
  Strings: TStringList;
  i, j: Integer;
  Fields: TStringDynArray;
  SubFields: TStringDynArray;
  Item: TLogItem;
  iValue, iCode: Integer;
begin
  if MainViews.Count = 0 then
  begin
    raise Exception.Create('No views registered so it is a bad idea to try to LoadData!');
  end;

  Tags := TStringList.Create;
  {$IFDEF ANDROID}
  Tags.LoadFromFile(TPath.GetDocumentsPath + PathDelim + 'tags.txt');
  {$ELSE}
  Tags.LoadFromFile(ExpandFileName(GetCurrentDir + '\..\..\tags.txt'));
  {$ENDIF}
  Log.d(Tags.Text);
  {$IFDEF ANDROID}
    sDataFile := Format('%sitems.dat', [GetHomePath]);
  {$ENDIF ANDROID}
  {$IFDEF WIN32}
    sDataFile := Format('%sitems.dat', [ExtractFilePath(ParamStr(0))]);
  {$ENDIF WIN32}
  {$IFDEF WIN64}
    sDataFile := Format('%sitems.dat', [ExtractFilePath(ParamStr(0))]);
  {$ENDIF WIN64}

  if sDataFile.Length = 0 then
  begin
    Log.d('No data file found for selected platform');
    MainViews.Items[0].ShowError('No data file selected for this platform!', true);
  end else begin
    Items := TList<TLogItem>.Create;
    Strings := TStringList.Create;
    try
      Strings.LoadFromFile(sDataFile);

      Log.d('Loaded %d% lines', [Strings.Count]);

      for i := 0 to Strings.Count-1 do begin
        Fields := SplitString(Strings[i], #9);
        Item := TLogItem.Create;

        Item.TagValue := Fields[0].Replace('~t~', #9)
                                  .Replace('~n~', #10)
                                  .Replace('~r~', #13);
        Item.TagName := Fields[1].Replace('~t~', #9)
                                 .Replace('~n~', #10)
                                 .Replace('~r~', #13);
        val(Item.TagName, iValue, iCode);
        if iCode = 0 then
        begin
          Item.TagName := TagToWord(iValue);
        end;

        // Meta Fields
        SubFields := SplitString(Fields[2], #3);
        case SubFields[0].ToInteger() of        // Meta Fields Version
          1: begin
            Item.Created := ISO8601ToDate(SubFields[1]);
            Item.Updated := ISO8601ToDate(SubFields[2]);
            Item.EntryDateTime := Item.Created;
            if Length(SubFields) > 2 then
            begin
              Item.TagValue := Item.TagValue + SubFields[3];
            end;
          end;
          2: begin
            Item.Created := ISO8601ToDate(SubFields[1]);
            Item.Updated := ISO8601ToDate(SubFields[2]);
            Item.EntryDateTime := ISO8601ToDate(SubFields[3]);
          end;
        end;

        Item.Memo := Fields[3].Replace('~t~', #9)
                              .Replace('~n~', #10)
                              .Replace('~r~', #13);

        Items.Add(Item);
      end;
    finally
      Strings.Free;
    end;
    MainViews[0].UpdateItems(Items);
  end;
end;

procedure TdmMain.SaveData();
  procedure AddValueToLine(var Line: string; const Text: string);
  begin
    Line := Line + Text.Replace(#3, '~e~')        // End of Text used to separate subvalues
                       .Replace(#9, '~t~')        // Tab used to separate values
                       .Replace(#10, '~n~')       // Newline used to separate records
                       .Replace(#13, '~r~')       // Carriage Return not used but encoded for safety
                       + #9;                      // Add separator for this level
  end;

  procedure AddSubValueToLine(var Line: string; const Text: string);
  begin
    Line := Line + Text.Replace(#3, '~e~')
                       .Replace(#9, '~t~')
                       .Replace(#10, '~n~')
                       .Replace(#13, '~r~')
                       + #3;                      // Add separator for this level
  end;

  procedure MoveCompletedLineToList(const Strings: TStringList; var Line: string);
  begin
    Strings.Add(System.Copy(Line, 1, Length(Line)-1));//remove trailing tab
    Line := '';
  end;

var
  Strings: TStringList;
  LatestLine: string;
  i, j: Integer;
begin
  LatestLine := '';

  Strings := TStringList.Create;
  try
    for i := 0 to Items.Count-1 do begin
      with Items[i] do begin
        // Title and Tag
        AddValueToLine(LatestLine, TagValue);
        AddValueToLine(LatestLine, TagName);

        // Meta Fields
        AddSubValueToLine(LatestLine, '2');     // Meta Fields Version
        AddSubValueToLine(LatestLine, DateToISO8601(Created));
        AddSubValueToLine(LatestLine, DateToISO8601(Updated));
        AddSubValueToLine(LatestLine, DateToISO8601(EntryDateTime));
        AddValueToLine(LatestLine, '');         // Terminate meta field subvalues

        // Body
        AddValueToLine(LatestLine, Memo);
        MoveCompletedLineToList(Strings, LatestLine);
      end;
    end;
    Strings.SaveToFile(sDataFile, TEncoding.UTF8);
  finally
    Strings.Free;
  end;

  MainViews.Items[0].UpdateItems(Items);
end;

procedure TdmMain.NewItem();
begin
  frmNote.NewItem;
end;

procedure TdmMain.EditItem(Item: TLogItem);
begin
  frmNote.EditItem(Item);
end;

procedure TdmMain.SaveItem(Item: TLogItem);
begin
  if not Items.Contains(Item) then
  begin
    Items.Insert(0, Item);
  end;
  SaveData;
end;

procedure TdmMain.aEditItemExecute(Sender: TObject);
var
  Item: TLogItem;
begin
  Item := TLogItem(aEditItem.Tag);
  dmMain.EditItem(Item);
end;

procedure TdmMain.aNewItemExecute(Sender: TObject);
begin
  NewItem;
end;

procedure TdmMain.DeleteItem(Item: TLogItem);
begin
  Items.Remove(Item);
  SaveData;
end;

end.
