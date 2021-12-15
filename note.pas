unit note;

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
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
    nEditing: integer;
  public
    { Public declarations }
    procedure NewItem();
    procedure EditItem(itemId: integer);
  end;

var
  frmNote: TfrmNote;

implementation

uses
  main,
  Model,
  System.DateUtils,
  FMX.DialogService;

{$R *.fmx}

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
  item: TListViewItem;
  meta: TMetaFields;
begin
  if nEditing = -1 then
  begin
    item := frmMain.lstItems.Items.Insert(0);
    meta := TMetaFields.Create;
    item.TagObject := meta;
    meta.Created := TTimeZone.Local.ToUniversalTime(Now);
  end else begin
    item := frmMain.lstItems.Items[nEditing];
    meta := TMetaFields(item.TagObject);
  end;
  meta.Updated := TTimeZone.Local.ToUniversalTime(Now);
  item.Text := txtTitle.Text;
  item.Tag := frmMain.WordToTag(cboTag.Items[cboTag.ItemIndex]);
  item.TagString := txtMemo.Text;
  frmMain.SaveData;
  Hide;
end;

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
  tagName := frmMain.TagToWord(item.Tag);
  for i := 0 to cboTag.items.Count - 1 do
  begin
    if cboTag.items[i] = tagName then
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

procedure TfrmNote.FormCreate(Sender: TObject);
var
  i: integer;
  tagName: string;
begin
  for i := 1 to frmMain.lstTags.Items.Count-1 do
  begin
    tagName := frmMain.lstTags.Items[i];
    if (tagName <> '') and (tagName.Chars[i] <> '#') then
    begin
      cboTag.Items.Add(tagName);
    end;
  end;
end;

end.
