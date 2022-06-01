object Form1: TForm1
  Left = 407
  Top = 176
  Width = 846
  Height = 421
  Caption = '#SQLSat147'
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
    Left = 24
    Top = 216
    Width = 142
    Height = 13
    Caption = 'Comando que ser'#225' executado'
  end
  object Edit1: TEdit
    Left = 240
    Top = 24
    Width = 321
    Height = 21
    TabOrder = 0
  end
  object DBGrid1: TDBGrid
    Left = 240
    Top = 88
    Width = 320
    Height = 120
    DataSource = DataSource1
    TabOrder = 2
    TitleFont.Charset = DEFAULT_CHARSET
    TitleFont.Color = clWindowText
    TitleFont.Height = -11
    TitleFont.Name = 'MS Sans Serif'
    TitleFont.Style = []
  end
  object Button1: TButton
    Left = 480
    Top = 56
    Width = 75
    Height = 25
    Caption = 'Buscar'
    TabOrder = 1
    OnClick = Button1Click
  end
  object Memo1: TMemo
    Left = 24
    Top = 232
    Width = 793
    Height = 145
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -24
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 3
  end
  object DataSource1: TDataSource
    DataSet = ADOQuery1
    Left = 128
    Top = 136
  end
  object ADOConnection1: TADOConnection
    ConnectionString = 
      'Provider=SQLNCLI11.1;Integrated Security=SSPI;Persist Security I' +
      'nfo=False;User ID="";Initial Catalog=Northwind;Data Source=LGFab' +
      'iano\SQL2014;Initial File Name="";Server SPN=""'
    LoginPrompt = False
    Provider = 'SQLNCLI11.1'
    Left = 88
    Top = 136
  end
  object ADOQuery1: TADOQuery
    Connection = ADOConnection1
    Parameters = <>
    Left = 168
    Top = 136
  end
end
