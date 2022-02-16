program log;

uses
  System.StartUpCopy,
  FMX.Forms,
  Main in 'Main.pas' {frmMain},
  Note in 'Note.pas' {frmNote},
  Model in 'Model.pas',
  MainController in 'MainController.pas' {dmMain: TDataModule},
  Interfaces in 'Interfaces.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TdmMain, dmMain);
  Application.CreateForm(TfrmMain, frmMain);
  Application.CreateForm(TfrmNote, frmNote);
  Application.Run;
end.
