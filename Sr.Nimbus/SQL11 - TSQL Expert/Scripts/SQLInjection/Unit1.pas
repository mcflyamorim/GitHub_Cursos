unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, DB, ADODB, Grids, DBGrids;

type
  TForm1 = class(TForm)
    Edit1: TEdit;
    DataSource1: TDataSource;
    DBGrid1: TDBGrid;
    ADOConnection1: TADOConnection;
    ADOQuery1: TADOQuery;
    Button1: TButton;
    Memo1: TMemo;
    Label1: TLabel;
    procedure Button1Click(Sender: TObject);
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
  ADOConnection1.Connected := True;
  ADOQuery1.Close;
  ADOQuery1.SQL.Text := 'SELECT CustomerID AS Cod, ContactName AS Nome FROM Customers WHERE ContactName = ' + '''' + Edit1.Text + '''';
  Memo1.Text := ADOQuery1.SQL.Text;
  ADOQuery1.Open;
end;

end.
