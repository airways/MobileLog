unit Main;

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
    tLoadData: TTimer;
    procedure btnAddClick(Sender: TObject);
    procedure lstItemsDblClick(Sender: TObject);
    procedure lstItemsItemClick(const Sender: TObject;
      const AItem: TListViewItem);
    procedure FormCreate(Sender: TObject);
    procedure tLoadDataTimer(Sender: TObject);
  private
    { Private declarations }
    sDataFile: string;
  public
    { Public declarations }
    procedure SaveData;
    procedure LoadData;
  end;

var
  frmMain: TfrmMain;

implementation

uses
  Note,
  ListViewUtils;

{$R *.fmx}

{* Logic Functions *}

procedure TfrmMain.SaveData;
begin
  ListViewSaveToFile(lstItems, sDataFile);
end;

procedure TfrmMain.tLoadDataTimer(Sender: TObject);
begin
   tLoadData.Enabled := false;
  LoadData;
end;

procedure TfrmMain.LoadData;
begin
  if FileExists(sDataFile) then
  begin
    ListViewLoadFromFile(lstItems, sDataFile);
  end;
end;

procedure TfrmMain.btnAddClick(Sender: TObject);
begin
  frmNote.NewItem;
end;

{* Event Handlers *}
procedure TfrmMain.FormCreate(Sender: TObject);
begin
  {$IFDEF ANDROID}// if the operative system is Android
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
    ShowMessage('No data file selected for this platform!');
    Application.Terminate;
  end;
end;


procedure TfrmMain.lstItemsDblClick(Sender: TObject);
begin
  if (lstItems.Selected <> nil) and (lstItems.Selected.TagObject <> nil) then
  begin
    frmNote.EditItem(lstItems.Selected.Index);
  end;
end;

procedure TfrmMain.lstItemsItemClick(const Sender: TObject;
  const AItem: TListViewItem);
begin
   if (lstItems.Selected <> nil) and (lstItems.Selected.TagObject <> nil) then
  begin
    frmNote.EditItem(lstItems.Selected.Index);
  end;
end;

end.
