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
    ADOConnection2: TADOConnection;
    Button3: TButton;
    Button4: TButton;
    Button5: TButton;
    Button6: TButton;
    ADOQueryNormalQuery: TADOQuery;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure Button5Click(Sender: TObject);
    procedure Button6Click(Sender: TObject);
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
  ADOQuery1.Prepared := False;
  ADOConnection1.Close;
  ADOQuery1.Connection := ADOConnection1;
  ADOConnection1.Connected := True;
  Tempo := Now();
  while i <= 20 do
  begin
    inc(i);
    ADOQuery1.Connection := ADOConnection1;
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
  ADOQuery1.Prepared := True;
  ADOConnection1.Close;
  ADOQuery1.Connection := ADOConnection1;
  ADOConnection1.Connected := True;
  Tempo := Now();
  while i <= 20 do
  begin
    inc(i);

    ADOQuery1.Close;
    ADOQuery1.Parameters[0].Value := GenerateKey;
    ADOQuery1.Open;
  end;
  ShowMessage(FormatDateTime('hh:mm:ss.zzz', Tempo - Now()))
end;

procedure TForm1.Button3Click(Sender: TObject);
Var
  i : Int64;
  Tempo : TDateTime;
begin
  i := 0;
  ADOQuery1.Prepared := False;
  ADOConnection2.Close;
  ADOConnection2.ConnectionString := 'Provider=SQLNCLI11.1;Persist Security Info=False;User ID=fabiano;Password=@bc123456789;Initial Catalog=DB1;Data Source=tcp:dbserverfabiano.database.windows.net,1433;Initial File Name="";Server SPN=""';
  ADOConnection2.Connected := True;
  ADOQuery1.Connection := ADOConnection2;
  Tempo := Now();
  while i <= 20 do
  begin
    inc(i);

    ADOQuery1.Close;
    ADOQuery1.Parameters[0].Value := GenerateKey;
    ADOQuery1.Open;
  end;
  ShowMessage(FormatDateTime('hh:mm:ss.zzz', Tempo - Now()))
end;

procedure TForm1.Button4Click(Sender: TObject);
Var
  i : Int64;
  Tempo : TDateTime;
begin
  i := 0;
  ADOQuery1.Prepared := True;
  ADOConnection2.Close;
  ADOConnection2.ConnectionString := 'Provider=SQLNCLI11.1;Persist Security Info=False;User ID=fabiano;Password=@bc123456789;Initial Catalog=DB1;Data Source=tcp:dbserverfabiano.database.windows.net,1433;Initial File Name="";Server SPN=""';
  ADOConnection2.Connected := True;
  ADOQuery1.Connection := ADOConnection2;
  Tempo := Now();
  while i <= 20 do
  begin
    inc(i);

    ADOQuery1.Close;
    ADOQuery1.Parameters[0].Value := GenerateKey;
    ADOQuery1.Open;
  end;
  ShowMessage(FormatDateTime('hh:mm:ss.zzz', Tempo - Now()))
end;

procedure TForm1.Button5Click(Sender: TObject);
Var
  i : Int64;
  Tempo : TDateTime;
begin
  i := 0;
  ADOQueryNormalQuery.Prepared := False;
  ADOConnection2.Close;
  ADOConnection2.ConnectionString := 'Provider=SQLNCLI11.1;Persist Security Info=False;User ID=fabiano;Password=@bc123456789;Initial Catalog=DB1;Data Source=tcp:dbserverfabiano.database.windows.net,1433;Initial File Name="";Server SPN=""';
  ADOConnection2.Connected := True;
  ADOQueryNormalQuery.Connection := ADOConnection2;
  Tempo := Now();
  while i <= 20 do
  begin
    inc(i);

    ADOQueryNormalQuery.Close;
    ADOQueryNormalQuery.Parameters[0].Value := GenerateKey;
    ADOQueryNormalQuery.Open;
  end;
  ShowMessage(FormatDateTime('hh:mm:ss.zzz', Tempo - Now()))
end;

procedure TForm1.Button6Click(Sender: TObject);
Var
  i : Int64;
  Tempo : TDateTime;
begin
  i := 0;
  ADOQueryNormalQuery.Prepared := True;
  ADOConnection2.Close;
  ADOConnection2.ConnectionString := 'Provider=SQLNCLI11.1;Persist Security Info=False;User ID=fabiano;Password=@bc123456789;Initial Catalog=DB1;Data Source=tcp:dbserverfabiano.database.windows.net,1433;Initial File Name="";Server SPN=""';
  ADOConnection2.Connected := True;
  ADOQueryNormalQuery.Connection := ADOConnection2;
  Tempo := Now();
  while i <= 20 do
  begin
    inc(i);

    ADOQueryNormalQuery.Close;
    ADOQueryNormalQuery.Parameters[0].Value := GenerateKey;
    ADOQueryNormalQuery.Open;
  end;
  ShowMessage(FormatDateTime('hh:mm:ss.zzz', Tempo - Now()))
end;

end.
