unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, DB, ADODB, StdCtrls, Mask, DBCtrls, ExtCtrls, Grids, DBGrids,
  Provider, DBClient;

type
  TForm1 = class(TForm)
    ADOConnection1: TADOConnection;
    ADOQuery1: TADOQuery;
    DataSource1: TDataSource;
    Edit2: TEdit;
    Label2: TLabel;
    Button1: TButton;
    ADOQuery1ID_Cliente: TAutoIncField;
    ADOQuery1Nome: TStringField;
    ADOQuery1Col1: TStringField;
    ADOQuery1Col2: TStringField;
    ADOQuery1ID_Cidade: TIntegerField;
    Label1: TLabel;
    DBEdit1: TDBEdit;
    Label3: TLabel;
    DBEdit2: TDBEdit;
    Label4: TLabel;
    DBEdit3: TDBEdit;
    Label5: TLabel;
    DBEdit4: TDBEdit;
    DBNavigator1: TDBNavigator;
    DBGrid1: TDBGrid;
    DataSetProvider1: TDataSetProvider;
    ClientDataSet1: TClientDataSet;
    procedure Button1Click(Sender: TObject);
    procedure ClientDataSet1AfterPost(DataSet: TDataSet);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

procedure TForm1.Button1Click(Sender: TObject);
begin
  ADOConnection1.Connected := False;
  ADOConnection1.ConnectionString := Edit2.Text;
  ADOConnection1.Connected := true;
  ClientDataSet1.Open;
end;

procedure TForm1.ClientDataSet1AfterPost(DataSet: TDataSet);
begin
  ClientDataSet1.ApplyUpdates(-1);
end;

end.
