unit Note;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Memo.Types,
  FMX.Edit, FMX.ScrollBox, FMX.Memo, FMX.Controls.Presentation, FMX.StdCtrls,
  FMX.ListView.Appearances, FMX.ListBox, FMX.DateTimeCtrls, FMX.MultiView,
  Model, Interfaces;

type
  TfrmNote = class(TForm, IEditView)
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
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
    Editing: TLogItem;
    bChangingMemo: boolean;
  public
    { Public declarations }
    procedure NewItem();
    procedure EditItem(Item: TLogItem);
  end;

var
  frmNote: TfrmNote;

implementation

uses
  System.DateUtils,
  FMX.DialogService,
  System.UIConsts,
  StrUtils,
  MainController;

{$R *.fmx}

{* Logic Functions *}

procedure TfrmNote.NewItem();
begin
  bChangingMemo := false;
  Editing := nil;
  txtTagValue.Text := '';
  txtMemo.Text := '';
  dateEntryOn.Date := Now;
  timeEntryAt.Time := Now;
  btnDelete.Visible := false;
  Show;
  cboTag.SetFocus;
end;

procedure TfrmNote.EditItem(Item: TLogItem);
var
  i: integer;
  tagName: string;
  LocalDateTime: TDateTime;
begin
  bChangingMemo := false;
  Editing := Item;
  tagName := Editing.TagName;
  txtTagValue.Text := Editing.TagValue;
  for i := 0 to cboTag.items.Count - 1 do
  begin
    if cboTag.Items[i] = tagName then
    begin
      cboTag.ItemIndex := i;
      Break;
    end;
  end;
  txtMemo.Text := Editing.Memo;
  LocalDateTime := TTimeZone.Local.ToLocalTime(Editing.EntryDateTime);
  dateEntryOn.Date := LocalDateTime;
  timeEntryAt.Time := LocalDateTime;
  btnDelete.Visible := true;
  Show;
  txtMemo.SetFocus;
end;

procedure TfrmNote.FormCreate(Sender: TObject);
begin
  dmMain.RegisterEditView(Self);
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
  if Editing <> nil then
  begin
    TDialogService.MessageDialog('Are you sure you want to delete this item?', System.UITypes.TMsgDlgType.mtInformation,
      [System.UITypes.TMsgDlgBtn.mbYes, System.UITypes.TMsgDlgBtn.mbNo],
      System.UITypes.TMsgDlgBtn.mbNo, 0,

    procedure(const AResult: TModalResult)
    begin
      case AResult of
        mrYES: begin
          dmMain.DeleteItem(Editing);
          Hide;
        end;
      end;
    end);
  end;
end;

procedure TfrmNote.btnSaveClick(Sender: TObject);
var
  LocalDateTime: TDateTime;
  newTag: integer;
  newMemo: string;
begin
  if Editing = nil then
  begin
    Editing := TLogItem.Create;
    Editing.Created := TTimeZone.Local.ToUniversalTime(Now);
  end;

  Editing.Updated := TTimeZone.Local.ToUniversalTime(Now);
  Editing.EntryDateTime := TTimeZone.Local.ToUniversalTime(dateEntryOn.Date + timeEntryAt.Time);
  Editing.TagName := cboTag.Selected.Text;
  Editing.TagValue := txtTagValue.Text;

  if (txtMemo.Text = 'Memo') and (txtMemo.FontColor = claDarkgray) then
  begin
    Editing.Memo := '';
  end else begin
    Editing.Memo := txtMemo.Text;
  end;

  dmMain.SaveItem(Editing);
  Hide;
end;

end.
