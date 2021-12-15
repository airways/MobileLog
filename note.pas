unit Note;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Memo.Types,
  FMX.Edit, FMX.ScrollBox, FMX.Memo, FMX.Controls.Presentation, FMX.StdCtrls,
  FMX.ListView.Appearances, FMX.ListBox;

type
  TfrmNote = class(TForm)
    btnSave: TButton;
    btnCancel: TButton;
    txtMemo: TMemo;
    txtTitle: TEdit;
    btnDelete: TButton;
    cboTag: TComboBox;
    Label1: TLabel;
    Label2: TLabel;
    procedure btnSaveClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    procedure btnDeleteClick(Sender: TObject);
  private
    { Private declarations }
    nEditing: integer;
  public
    { Public declarations }
    procedure NewItem();
    procedure EditItem(itemId: integer);
    function WordToTag(word: string): integer;
    function TagToWord(tag: integer): string;
  end;

var
  frmNote: TfrmNote;

implementation

uses
  Main,
  Model,
  System.DateUtils,
  FMX.DialogService;

{$R *.fmx}

{* Logic Functions *}

procedure TfrmNote.NewItem();
begin
  nEditing := -1;
  txtTitle.Text := '';
  txtMemo.Text := '';
  btnDelete.Visible := false;
  Show;
  txtTitle.SetFocus;
end;

procedure TfrmNote.EditItem(itemId: integer);
var
  item: TListViewItem;
  i: integer;
  tagName: string;
begin
  nEditing := itemId;
  item := frmMain.lstItems.Items[nEditing];
  txtTitle.Text := item.Text;
  tagName := TagToWord(item.Tag);
  for i := 0 to cboTag.items.Count - 1 do
  begin
    if cboTag.Items[i] = tagName then
    begin
      cboTag.ItemIndex := i;
      Break;
    end;
  end;
  txtMemo.Text := item.TagString;
  btnDelete.Visible := true;
  Show;
  txtMemo.SetFocus;
end;

function TfrmNote.WordToTag(word: string): Integer;
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

function TfrmNote.TagToWord(tag: Integer): string;
var
  i: integer;
  tagName: string;
begin
  for i := 1 to cboTag.Items.Count-1 do
  begin
    tagName := cboTag.Items[i];
    if WordToTag(tagName) = tag then
    begin
      Result := tagName;
      Break;
    end;
  end;
end;

{* Event Handlers *}

procedure TfrmNote.btnCancelClick(Sender: TObject);
begin
  Hide;
end;

procedure TfrmNote.btnDeleteClick(Sender: TObject);
begin
  if nEditing <> -1 then
  begin
    TDialogService.MessageDialog('Are you sure you want to delete this item?', System.UITypes.TMsgDlgType.mtInformation,
      [System.UITypes.TMsgDlgBtn.mbYes, System.UITypes.TMsgDlgBtn.mbNo],
      System.UITypes.TMsgDlgBtn.mbNo, 0,

    procedure(const AResult: TModalResult)
    begin
      case AResult of
        mrYES: begin
          frmMain.lstItems.Items.Delete(nEditing);
          Hide;
          frmMain.SaveData;
        end;
      end;
    end);
  end;
end;

procedure TfrmNote.btnSaveClick(Sender: TObject);
var
  Item: TListViewItem;
  Meta: TMetaFields;
  LocalDateTime: TDateTime;
begin
  if nEditing = -1 then
  begin
    Item := frmMain.lstItems.Items.Insert(0);
    Meta := TMetaFields.Create;
    Item.TagObject := Meta;
    Meta.Created := TTimeZone.Local.ToUniversalTime(Now);
    LocalDateTime := TTimeZone.Local.ToLocalTime(meta.Created);
    Item.Detail := DateTimeToStr(LocalDateTime);
  end else begin
    Item := frmMain.lstItems.Items[nEditing];
    Meta := TMetaFields(item.TagObject);
  end;
  Meta.Updated := TTimeZone.Local.ToUniversalTime(Now);
  Item.Text := txtTitle.Text;
  Item.Tag := WordToTag(cboTag.Items[cboTag.ItemIndex]);
  Item.TagString := txtMemo.Text;
  frmMain.SaveData;
  Hide;
end;

end.
