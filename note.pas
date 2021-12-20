unit Note;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Memo.Types,
  FMX.Edit, FMX.ScrollBox, FMX.Memo, FMX.Controls.Presentation, FMX.StdCtrls,
  FMX.ListView.Appearances, FMX.ListBox, FMX.DateTimeCtrls;

type
  TfrmNote = class(TForm)
    btnSave: TButton;
    btnCancel: TButton;
    txtMemo: TMemo;
    btnDelete: TButton;
    cboTag: TComboBox;
    Label2: TLabel;
    Label3: TLabel;
    txtTagValue: TEdit;
    dateEntryOn: TDateEdit;
    timeEntryAt: TTimeEdit;
    Label1: TLabel;
    Label4: TLabel;
    procedure btnSaveClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    procedure btnDeleteClick(Sender: TObject);
    procedure txtMemoEnter(Sender: TObject);
    procedure txtMemoExit(Sender: TObject);
    procedure txtMemoChange(Sender: TObject);
  private
    { Private declarations }
    nEditing: integer;
    bChangingMemo: boolean;
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
  ListViewUtils,
  System.DateUtils,
  FMX.DialogService,
  System.UIConsts,
  StrUtils;

{$R *.fmx}

{* Logic Functions *}

procedure TfrmNote.NewItem();
begin
  bChangingMemo := false;
  nEditing := -1;
  txtTagValue.Text := '';
  txtMemo.Text := '';
  dateEntryOn.Date := Now;
  timeEntryAt.Time := Now;
  btnDelete.Visible := false;
  Show;
  cboTag.SetFocus;
end;

procedure TfrmNote.EditItem(itemId: integer);
var
  item: TListViewItem;
  i: integer;
  tagName: string;
  meta: TMetaFields;
  LocalDateTime: TDateTime;
begin
  bChangingMemo := false;
  nEditing := itemId;
  item := frmMain.lstItems.Items[nEditing];
  meta := TMetaFields(item.TagObject);
  tagName := TagToWord(item.Tag);
  txtTagValue.Text := meta.TagValue;
  for i := 0 to cboTag.items.Count - 1 do
  begin
    if cboTag.Items[i] = tagName then
    begin
      cboTag.ItemIndex := i;
      Break;
    end;
  end;
  txtMemo.Text := item.TagString;
  LocalDateTime := TTimeZone.Local.ToLocalTime(meta.EntryDateTime);
  dateEntryOn.Date := LocalDateTime;
  timeEntryAt.Time := LocalDateTime;
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

procedure TfrmNote.txtMemoChange(Sender: TObject);
begin
  if not bChangingMemo and (txtMemo.Text = '') then
  begin
    bChangingMemo := true;
    txtMemo.Text := 'Memo';
    bChangingMemo := false;
    txtMemo.FontColor := claDarkgray;
  end else begin
    txtMemo.FontColor := claBlack;
  end;
end;

procedure TfrmNote.txtMemoEnter(Sender: TObject);
begin
  if not bChangingMemo and (txtMemo.Text = 'Memo') and (txtMemo.FontColor = claDarkgray) then
  begin
    bChangingMemo := true;
    txtMemo.Text := '';
    bChangingMemo := false;
    txtMemo.FontColor := claBlack;
  end;
end;

procedure TfrmNote.txtMemoExit(Sender: TObject);
begin
  if not bChangingMemo and (txtMemo.Text = '') then
  begin
    bChangingMemo := true;
    txtMemo.Text := 'Memo';
    bChangingMemo := false;
    txtMemo.FontColor := claDarkgray;
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
  newTag: integer;
  newMemo: string;
  currDate: string;
  lastDate: string;
  addAtIndex: integer;
begin
  if nEditing = -1 then
  begin
    addAtIndex := 0;

    Meta := TMetaFields.Create;
    Meta.Created := TTimeZone.Local.ToUniversalTime(Now);

    if frmMain.lstItems.Items.Count > 0 then
    begin
      if (frmMain.lstItems.Items[0].TagObject = nil) then // Heading item
      begin
        lastDate := frmMain.lstItems.Items[0].Text;
        DateTimeToString(currDate, 'yy-mm-dd dddd', TTimeZone.Local.ToLocalTime(meta.Created));
        if lastDate <> currDate then
        begin
          AddHeadingRowIfNeeded(frmMain.lstItems, meta, true);
        end else begin
          addAtIndex := 1;
        end;
      end;
    end;

    Item := frmMain.lstItems.Items.Insert(addAtIndex);
    Item.TagObject := Meta;
  end else begin
    Item := frmMain.lstItems.Items[nEditing];
    Meta := TMetaFields(item.TagObject);
  end;

  Meta.Updated := TTimeZone.Local.ToUniversalTime(Now);
  Meta.EntryDateTime := TTimeZone.Local.ToUniversalTime(dateEntryOn.Date + timeEntryAt.Time);

  Meta.TagValue := txtTagValue.Text;

  if cboTag.ItemIndex > -1 then
  begin
    newTag := WordToTag(cboTag.Items[cboTag.ItemIndex]);
  end else begin
    newTag := 0;
  end;
  if (txtMemo.Text = 'Memo') and (txtMemo.FontColor = claDarkgray) then
  begin
    newMemo := '';
  end else begin
    newMemo := txtMemo.Text;
  end;

  RenderListItem(Item, meta, newTag, newMemo);

  frmMain.SaveData;
  Hide;
end;

end.
