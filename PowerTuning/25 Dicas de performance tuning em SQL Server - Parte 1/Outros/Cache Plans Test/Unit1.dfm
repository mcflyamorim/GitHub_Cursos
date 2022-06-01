object Frm1: TFrm1
  Left = 393
  Top = 187
  BorderStyle = bsDialog
  Caption = 'Test Cache Plan'
  ClientHeight = 441
  ClientWidth = 579
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 12
    Top = 56
    Width = 30
    Height = 13
    Caption = 'Value:'
  end
  object Label2: TLabel
    Left = 12
    Top = 12
    Width = 87
    Height = 13
    Caption = 'Connection String:'
  end
  object Label3: TLabel
    Left = 12
    Top = 136
    Width = 49
    Height = 13
    Caption = 'SearchFor'
  end
  object Label4: TLabel
    Left = 148
    Top = 56
    Width = 33
    Height = 13
    Caption = 'Result:'
  end
  object DBGrid1: TDBGrid
    Left = 149
    Top = 72
    Width = 412
    Height = 169
    DataSource = DataSource1
    TabOrder = 0
    TitleFont.Charset = DEFAULT_CHARSET
    TitleFont.Color = clWindowText
    TitleFont.Height = -11
    TitleFont.Name = 'MS Sans Serif'
    TitleFont.Style = []
  end
  object Edit1: TEdit
    Left = 9
    Top = 70
    Width = 112
    Height = 21
    TabOrder = 1
    Text = 'Liu Wong'
  end
  object Button1: TButton
    Left = 53
    Top = 99
    Width = 75
    Height = 25
    Caption = 'Search'
    TabOrder = 2
    OnClick = Button1Click
  end
  object Edit2: TEdit
    Left = 9
    Top = 27
    Width = 552
    Height = 21
    TabOrder = 3
    Text = 
      'Provider=SQLNCLI10.1;Integrated Security=SSPI;Persist Security I' +
      'nfo=False;User ID="";Initial Catalog=NorthWind;Data Source=dellf' +
      'abiano\sql2016;Initial File Name="";Server SPN=""'
  end
  object ListBox1: TListBox
    Left = 9
    Top = 152
    Width = 121
    Height = 161
    ItemHeight = 13
    Items.Strings = (
      'Xu'
      'Ana'
      'Jos'#233
      'Fabio'
      'Gilmar'
      'Gabriel'
      'Vinicius'
      'Alexandre'
      'Wellington'
      'Ana Claudia'
      'Jos'#233' Ricardo'
      'Marco Antonio')
    TabOrder = 4
  end
  object Button2: TButton
    Left = 53
    Top = 315
    Width = 75
    Height = 25
    Caption = 'Search'
    TabOrder = 5
    OnClick = Button2Click
  end
  object DBNavigator1: TDBNavigator
    Left = 152
    Top = 248
    Width = 410
    Height = 89
    DataSource = DataSource1
    TabOrder = 6
  end
  object Memo1: TMemo
    Left = 152
    Top = 344
    Width = 417
    Height = 89
    Lines.Strings = (
      'SELECT * FROM Orders'
      'INNER JOIN Customers'
      '   ON Orders.CustomerID = Customers.CustomerID'
      'INNER JOIN Order_Details'
      '   ON Orders.OrderID = Order_Details.OrderID'
      'WHERE Customers.ContactName = :Contact')
    TabOrder = 7
  end
  object ADOConnection1: TADOConnection
    LoginPrompt = False
    Provider = 'SQLNCLI10.1'
    Left = 40
    Top = 176
  end
  object DataSource1: TDataSource
    DataSet = ADOQuery1
    Left = 128
    Top = 176
  end
  object ADOQuery1: TADOQuery
    Connection = ADOConnection1
    Parameters = <
      item
        Name = 'Contact'
        Size = -1
        Value = Null
      end>
    SQL.Strings = (
      'SELECT * FROM Orders'
      'INNER JOIN Customers'
      '   ON Orders.CustomerID = Customers.CustomerID'
      'INNER JOIN Order_Details'
      '   ON Orders.OrderID = Order_Details.OrderID'
      'WHERE Customers.ContactName = :Contact')
    Left = 80
    Top = 176
  end
end
