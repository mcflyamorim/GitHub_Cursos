program Test_Cache_Plan;

uses
  Forms,
  Unit1 in 'Unit1.pas' {Frm1};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TFrm1, Frm1);
  Application.Run;
end.
