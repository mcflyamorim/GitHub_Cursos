unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, DB, ADODB, ActiveX;

type
  TForm1 = class(TForm)
    Button1: TButton;
    ADOConnection1: TADOConnection;
    DataSource1: TDataSource;
    ADOQuery1: TADOQuery;
    Button2: TButton;
    ADOQuery2: TADOQuery;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}


Function GenerateKey: String;
var
  MyGUID: TGUID;
  MyWideChar: array[0..100] of WideChar;
begin
  {First, generate the GUID:}
  CoCreateGUID(MyGUID);
  {Now convert it to a wide-character string:}
  StringFromGUID2(MyGUID, MyWideChar, 39);
  {Now convert it to a Delphi string:}
  Result := WideCharToString(MyWideChar);
  {Get rid of the three dashes that StringFromGUID2() puts in the result 
  string:}
  while Pos( '-', Result ) > 0 do
    Delete( Result, Pos( '-', Result ), 1 );
  {Get rid of the left and right brackets in the string:}
  while Pos( '{', Result ) > 0 do
    Delete( Result, Pos( '{', Result ), 1 );
  while Pos( '}', Result ) > 0 do
    Delete( Result, Pos( '}', Result ), 1 );
end;

procedure TForm1.Button1Click(Sender: TObject);
Var
  i : Int64;
  Tempo : TDateTime;
begin
  i := 0;
  Tempo := Now();
  while i <= 10 do
  begin
    inc(i);
    ADOConnection1.Connected := True;
    ADOQuery1.Close;
    ADOQuery1.Parameters[0].Value := GenerateKey;
    ADOQuery1.Open;
  end;
  ShowMessage(FormatDateTime('hh:mm:ss.zzz', Tempo - Now()))
end;

procedure TForm1.Button2Click(Sender: TObject);
Var
  i : Int64;
  Tempo : TDateTime;
begin
  i := 0;
  Tempo := Now();
  while i <= 10 do
  begin
    inc(i);
    ADOConnection1.Connected := True;
    ADOQuery2.Close;
    ADOQuery2.Parameters[0].Value := GenerateKey;
    ADOQuery2.Open;
  end;
  ShowMessage(FormatDateTime('hh:mm:ss.zzz', Tempo - Now()))
end;

end.
