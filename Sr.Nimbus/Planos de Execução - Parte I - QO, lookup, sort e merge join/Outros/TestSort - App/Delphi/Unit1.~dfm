object Form1: TForm1
  Left = 321
  Top = 154
  Width = 529
  Height = 264
  Caption = 'Form1'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object DBGrid1: TDBGrid
    Left = 8
    Top = 8
    Width = 393
    Height = 177
    DataSource = DataSource1
    TabOrder = 0
    TitleFont.Charset = DEFAULT_CHARSET
    TitleFont.Color = clWindowText
    TitleFont.Height = -11
    TitleFont.Name = 'MS Sans Serif'
    TitleFont.Style = []
    Columns = <
      item
        Expanded = False
        FieldName = 'OrderID'
        Width = 79
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'CustomerID'
        Width = 93
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'OrderDate'
        Width = 101
        Visible = True
      end>
  end
  object DBNavigator1: TDBNavigator
    Left = 32
    Top = 192
    Width = 360
    Height = 25
    DataSource = DataSource1
    TabOrder = 1
  end
  object Button1: TButton
    Left = 408
    Top = 32
    Width = 97
    Height = 25
    Caption = 'COM OrderBy'
    TabOrder = 2
    OnClick = Button1Click
  end
  object Button2: TButton
    Left = 408
    Top = 64
    Width = 97
    Height = 25
    Caption = 'SEM OrderBy'
    TabOrder = 3
    OnClick = Button2Click
  end
  object DataSource1: TDataSource
    DataSet = ADOQuery1
    Left = 184
    Top = 104
  end
  object ADOConnection1: TADOConnection
    ConnectionString = 
      'Provider=SQLOLEDB.1;Integrated Security=SSPI;Persist Security In' +
      'fo=False;Initial Catalog=Northwind;Data Source=hpfabiano\sql2012' +
      ';'
    LoginPrompt = False
    Provider = 'SQLOLEDB.1'
    Left = 216
    Top = 104
  end
  object ADOQuery1: TADOQuery
    Connection = ADOConnection1
    Parameters = <>
    SQL.Strings = (
      'SELECT OrderID, CustomerID, OrderDate FROM OrdersBig')
    Left = 248
    Top = 104
    object ADOQuery1OrderID: TAutoIncField
      FieldName = 'OrderID'
      ReadOnly = True
    end
    object ADOQuery1CustomerID: TIntegerField
      FieldName = 'CustomerID'
    end
    object ADOQuery1OrderDate: TWideStringField
      FieldName = 'OrderDate'
      Size = 10
    end
  end
end
