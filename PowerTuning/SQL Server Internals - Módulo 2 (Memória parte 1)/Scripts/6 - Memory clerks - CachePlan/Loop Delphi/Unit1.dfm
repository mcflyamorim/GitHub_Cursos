object Form1: TForm1
  Left = 746
  Top = 335
  Width = 265
  Height = 178
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
  object Button1: TButton
    Left = 32
    Top = 32
    Width = 75
    Height = 25
    Caption = 'Button1'
    TabOrder = 0
    OnClick = Button1Click
  end
  object Button2: TButton
    Left = 136
    Top = 32
    Width = 75
    Height = 25
    Caption = 'Button2'
    TabOrder = 1
    OnClick = Button2Click
  end
  object ADOConnection1: TADOConnection
    ConnectionString = 
      'Provider=SQLOLEDB.1;Integrated Security=SSPI;Persist Security In' +
      'fo=False;User ID=sa;Initial Catalog=Northwind;Data Source=razerf' +
      'abiano\sql2017'
    LoginPrompt = False
    Provider = 'SQLOLEDB.1'
    Left = 64
    Top = 72
  end
  object DataSource1: TDataSource
    DataSet = ADOQuery1
    Left = 104
    Top = 72
  end
  object ADOQuery1: TADOQuery
    Connection = ADOConnection1
    Parameters = <>
    Left = 144
    Top = 72
  end
end
