object Form1: TForm1
  Left = 586
  Top = 222
  Width = 467
  Height = 343
  Caption = 'Demo19 App'
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
    Left = 32
    Top = 240
    Width = 115
    Height = 13
    Caption = 'Time to run query: 0'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clRed
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object Label2: TLabel
    Left = 368
    Top = 240
    Width = 41
    Height = 13
    Caption = 'Page 0'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clRed
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object DBGrid1: TDBGrid
    Left = 32
    Top = 48
    Width = 385
    Height = 185
    DataSource = DataSource1
    TabOrder = 1
    TitleFont.Charset = DEFAULT_CHARSET
    TitleFont.Color = clWindowText
    TitleFont.Height = -11
    TitleFont.Name = 'MS Sans Serif'
    TitleFont.Style = []
  end
  object Button1: TButton
    Left = 336
    Top = 16
    Width = 75
    Height = 25
    Caption = 'Run query'
    TabOrder = 0
    OnClick = Button1Click
  end
  object Button2: TButton
    Left = 104
    Top = 264
    Width = 107
    Height = 25
    Caption = 'Previews page'
    TabOrder = 2
    OnClick = Button2Click
  end
  object Button3: TButton
    Left = 232
    Top = 264
    Width = 105
    Height = 25
    Caption = 'Next page'
    TabOrder = 3
    OnClick = Button3Click
  end
  object DataSource1: TDataSource
    DataSet = ADOQuery1
    Left = 48
    Top = 8
  end
  object ADOConnection1: TADOConnection
    ConnectionString = 
      'Provider=SQLNCLI11.1;Integrated Security=SSPI;Persist Security I' +
      'nfo=False;User ID="";Initial Catalog=Northwind;Data Source=razer' +
      'fabiano\SQL2017;Initial File Name="";Server SPN="";'
    LoginPrompt = False
    Provider = 'SQLNCLI11.1'
    Left = 8
    Top = 8
  end
  object ADOQuery1: TADOQuery
    Connection = ADOConnection1
    Parameters = <
      item
        Name = 'PageNumber'
        Attributes = [paSigned, paNullable]
        DataType = ftInteger
        Precision = 10
        Size = 4
        Value = Null
      end
      item
        Name = 'RowsPerPage'
        Attributes = [paSigned, paNullable]
        DataType = ftInteger
        Precision = 10
        Size = 4
        Value = Null
      end>
    SQL.Strings = (
      
        'EXEC st_ReturnData @PageNumber = :PageNumber, @RowsPerPage = :Ro' +
        'wsPerPage')
    Left = 88
    Top = 8
  end
  object ADOStoredProc1: TADOStoredProc
    Connection = ADOConnection1
    ProcedureName = 'st_ReturnData'
    Parameters = <
      item
        Name = '@RETURN_VALUE'
        DataType = ftInteger
        Direction = pdReturnValue
        Precision = 10
      end
      item
        Name = '@PageNumber'
        Attributes = [paNullable]
        DataType = ftInteger
        Precision = 10
      end
      item
        Name = '@RowsPerPage'
        Attributes = [paNullable]
        DataType = ftInteger
        Precision = 10
      end>
    Left = 128
    Top = 8
  end
end
