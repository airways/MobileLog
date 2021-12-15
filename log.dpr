program log;

uses
  System.StartUpCopy,
  FMX.Forms,
  main in 'main.pas' {frmMain},
  note in 'note.pas' {frmNote},
  ListViewSaveLoad in 'ListViewSaveLoad.pas',
  Model in 'Model.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfrmMain, frmMain);
  Application.CreateForm(TfrmNote, frmNote);
  Application.Run;
end.
