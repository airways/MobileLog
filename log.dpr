program log;

uses
  System.StartUpCopy,
  FMX.Forms,
  Main in 'Main.pas' {frmMain},
  Note in 'Note.pas' {frmNote},
  ListViewUtils in 'ListViewUtils.pas',
  Model in 'Model.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfrmMain, frmMain);
  Application.CreateForm(TfrmNote, frmNote);
  Application.Run;
end.
