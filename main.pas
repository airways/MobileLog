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
  FMX.Layouts, FMX.ListBox, Data.DB, FireDAC.Comp.Client, FireDAC.Comp.DataSet,
  System.Generics.Collections,
  Interfaces, Model;

type
  TfrmMain = class(TForm, IMainView)
    btnAdd: TButton;
    lstItems: TListView;
    tLoadData: TTimer;
    procedure btnAddClick(Sender: TObject);
    procedure lstItemsDblClick(Sender: TObject);
    procedure lstItemsItemClick(const Sender: TObject;
      const AItem: TListViewItem);
    procedure tLoadDataTimer(Sender: TObject);
  private
    { Private declarations }
    sDataFile: string;
  public
    { Public declarations }
    procedure ShowError(msg: string; Fatal: boolean);
    procedure UpdateItems(LogItems: TList<TLogItem>);
  end;

var
  frmMain: TfrmMain;

implementation

uses
  FMX.DialogService,
  Note,
  System.DateUtils,
  MainController;

{$R *.fmx}

{* Logic Functions *}

procedure TfrmMain.ShowError(msg: string; Fatal: boolean);
begin
  TDialogService.MessageDialog(msg, System.UITypes.TMsgDlgType.mtInformation,
      [System.UITypes.TMsgDlgBtn.mbOK],
      System.UITypes.TMsgDlgBtn.mbOK, 0,

    procedure(const AResult: TModalResult)
    begin
      if Fatal then
      begin
        Application.Terminate;
      end;
    end);
end;

procedure RenderListItem(var Item: TListViewItem; LogItem: TLogItem);
var
  LocalDateTime: TDateTime;
  time: string;
begin
  Item.TagObject := LogItem;

  LocalDateTime := TTimeZone.Local.ToLocalTime(LogItem.Created);
  Item.Detail := '';

  // Title
//  Item.Text := frmNote.TagToWord(tag) + StrUtils.IfThen(tag > 0, StrUtils.IfThen(meta.TagValue <> '', ': ', '') + meta.TagValue, '');
  Item.Text := LogItem.TagName;
  if (Item.Text <> '') and (LogItem.TagValue <> '') then
  begin
    Item.Text := Item.Text + ': ';
  end;
  Item.Text := Item.Text + LogItem.TagValue;

  // Tag (type) -- this is a string encoded as an integer, up to 12 characters
  Item.Tag := dmMain.WordToTag(LogItem.TagName);

  // Body
  Item.TagString := LogItem.Memo.Replace('~e', #3)
                        .Replace('~t~', #9)
                        .Replace('~n~', #10)
                        .Replace('~r~', #13);

  // Item details
  DateTimeToString(time, 'hh:nn am/pm', TTimeZone.Local.ToLocalTime(LogItem.EntryDateTime));
  Item.Detail := time;
  if Item.TagString <> '' then
  begin
    Item.Detail := Item.Detail + ';';
    Item.Detail := Item.Detail + ' ' + Item.TagString.Substring(0, 100);
    Item.Detail := Item.Detail.Trim;
    Item.Detail := Item.Detail.Replace(#3, ' ')
                              .Replace(#9, ' ')
                              .Replace(#10, ' ')
                              .Replace(#13, ' ');;
  end;

end;

procedure TfrmMain.UpdateItems(LogItems: TList<TLogItem>);
var
  i: integer;
  listItem: TListViewItem;
  currDate: string;
  lastDate: string;
  HeadingItem: TListViewItem;
  addHeading: boolean;
begin
  // Update in reverse order from bottom
  lstItems.Items.Clear;
  for i := LogItems.Count-1 downto 0 do
  begin
    // Check if we need to add a new heading
    DateTimeToString(currDate, 'yy-mm-dd dddd', TTimeZone.Local.ToLocalTime(LogItems[i].Created));

    if (lstItems.Items.Count > 0) and (TLogItem(lstItems.Items[0].TagObject) <> nil) then
    begin
      DateTimeToString(lastDate, 'yy-mm-dd dddd', TTimeZone.Local.ToLocalTime(TLogItem(lstItems.Items[0].TagObject).Created));
    end;

    // Add heading row if we are on a new date -- or if there were no items at all
    // and lastDate is blank.
    if currDate <> lastDate then
    begin
      HeadingItem := lstItems.Items.Insert(0);
      HeadingItem.Text := currDate;
      lastDate := currDate;
      HeadingItem.Purpose := TListItemPurpose.Header;
    end;

    // Always insert the item below the top heading row
    listItem := lstItems.Items.Insert(1);
    RenderListItem(listItem, LogItems[i]);
  end;
end;

procedure TfrmMain.tLoadDataTimer(Sender: TObject);
begin
  dmMain.RegisterMainView(Self);
end;

procedure TfrmMain.btnAddClick(Sender: TObject);
begin
  dmMain.NewItem;
end;

{* Event Handlers *}

procedure TfrmMain.lstItemsDblClick(Sender: TObject);
begin
  if (lstItems.Selected <> nil) and (lstItems.Selected.TagObject <> nil) then
  begin
    dmMain.EditItem(TLogItem(lstItems.Selected.TagObject));
  end;
end;

procedure TfrmMain.lstItemsItemClick(const Sender: TObject;
  const AItem: TListViewItem);
begin
   if (lstItems.Selected <> nil) and (lstItems.Selected.TagObject <> nil) then
  begin
    dmMain.EditItem(TLogItem(lstItems.Selected.TagObject));
  end;
end;

end.
