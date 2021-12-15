unit main;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.ListView.Types,
  FMX.ListView.Appearances, FMX.ListView.Adapters.Base, FMX.ListView,
  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Param,
  FireDAC.Stan.Error, FireDAC.DatS, FireDAC.Phys.Intf, FireDAC.DApt.Intf,
  FireDAC.Stan.Async, FireDAC.DApt, FireDAC.UI.Intf, FireDAC.Stan.Def,
  FireDAC.Stan.Pool, FireDAC.Phys, FireDAC.Phys.SQLite, FireDAC.Phys.SQLiteDef,
  FireDAC.Stan.ExprFuncs, FireDAC.Phys.SQLiteWrapper.Stat, FireDAC.FMXUI.Wait,
  FMX.Layouts, FMX.ListBox, Data.DB, FireDAC.Comp.Client, FireDAC.Comp.DataSet;

type
  TfrmMain = class(TForm)
    btnAdd: TButton;
    lstItems: TListView;
    FDTable1: TFDTable;
    FDConnection1: TFDConnection;
    lstTags: TListBox;
    procedure btnAddClick(Sender: TObject);
    procedure lstItemsDblClick(Sender: TObject);
    procedure lstItemsItemClick(const Sender: TObject;
      const AItem: TListViewItem);
    procedure FormCreate(Sender: TObject);
    procedure lstTagsPaint(Sender: TObject; Canvas: TCanvas;
      const ARect: TRectF);
  private
    { Private declarations }
    sDataFile: string;
    sTagFile: string;
  public
    { Public declarations }
    procedure SaveData;
    procedure LoadData;
    function WordToTag(word: string): integer;
    function TagToWord(tag: integer): string;
  end;

var
  frmMain: TfrmMain;

implementation

uses note, ListViewSaveLoad;

{$R *.fmx}

procedure TfrmMain.btnAddClick(Sender: TObject);
begin
  frmNote.NewItem;
end;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  {$IFDEF ANDROID}// if the operative system is Android
    sDataFile := Format('%sitems.dat', [GetHomePath]);
    sTagFile := Format('%stags.dat', [GetHomePath]);
  {$ENDIF ANDROID}
  {$IFDEF WIN32}
    sDataFile := Format('%sitems.dat', [ExtractFilePath(ParamStr(0))]);
    sTagFile := Format('%stags.dat', [ExtractFilePath(ParamStr(0))]);
  {$ENDIF WIN32}
  {$IFDEF WIN64}
    sDataFile := Format('%sitems.dat', [ExtractFilePath(ParamStr(0))]);
    sTagFile := Format('%stags.dat', [ExtractFilePath(ParamStr(0))]);
  {$ENDIF WIN64}
  if sDataFile.Length = 0 then
  begin
    ShowMessage('No data file selected for this platform!');
    Application.Terminate;
  end;
  LoadData;
end;

procedure TfrmMain.lstItemsDblClick(Sender: TObject);
begin
  if lstItems.Selected <> nil then
  begin
    frmNote.EditItem(lstItems.Selected.Index);
  end;
end;

procedure TfrmMain.lstItemsItemClick(const Sender: TObject;
  const AItem: TListViewItem);
begin
   if lstItems.Selected <> nil then
  begin
    frmNote.EditItem(lstItems.Selected.Index);
  end;
end;

procedure TfrmMain.SaveData;
begin
  lstTags.Items.SaveToFile(sTagFile);
  ListViewSaveToFile(lstItems, sDataFile);
end;

procedure TfrmMain.lstTagsPaint(Sender: TObject; Canvas: TCanvas;
  const ARect: TRectF);
begin
  TListBox(Sender).Visible := false;
end;

procedure TfrmMain.LoadData;
begin
  if FileExists(sTagFile) then
  begin
    lstTags.Items.LoadFromFile(sTagFile);
  end;
  if FileExists(sDataFile) then
  begin
    ListViewLoadFromFile(lstItems, sDataFile);
  end;
end;

function TfrmMain.WordToTag(word: string): Integer;
var
  i: integer;
begin
  if word = '' then
  begin
    Result := 0;
  end else begin
    Result := 1;
    for i := 0 to word.Length do
    begin
      Result := Result * 26 + integer(word.Chars[i]) - 61;
    end;
  end;
end;

function TfrmMain.TagToWord(tag: Integer): string;
var
  i: integer;
  tagName: string;
begin
  for i := 1 to lstTags.Items.Count-1 do
  begin
    tagName := frmMain.lstTags.Items[i];
    if WordToTag(tagName) = tag then
    begin
      Result := tagName;
      Break;
    end;
  end;
end;

end.
