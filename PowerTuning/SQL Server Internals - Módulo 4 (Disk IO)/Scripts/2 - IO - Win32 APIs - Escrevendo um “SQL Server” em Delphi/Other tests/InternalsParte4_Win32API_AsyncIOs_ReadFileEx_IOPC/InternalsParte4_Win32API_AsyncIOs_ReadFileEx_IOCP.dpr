program InternalsParte4_Win32API_AsyncIOs_ReadFileEx_IOCP;

uses
  Forms,
  Unit1 in 'Unit1.pas' {Form1},
  ThreadUtilities in 'ThreadUtilities.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'InternalsParte4_Win32API_AsyncIOs_ReadFileEx_IOCP';
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
