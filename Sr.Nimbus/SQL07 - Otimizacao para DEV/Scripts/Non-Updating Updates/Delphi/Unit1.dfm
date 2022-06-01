object Form1: TForm1
  Left = 291
  Top = 167
  Width = 631
  Height = 329
  Caption = 'Non-Updating Updates - Solid Quality Mentors'
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
  object Label2: TLabel
    Left = 12
    Top = 12
    Width = 87
    Height = 13
    Caption = 'Connection String:'
  end
  object Label1: TLabel
    Left = 8
    Top = 88
    Width = 49
    Height = 13
    Caption = 'ID_Cliente'
    FocusControl = DBEdit1
  end
  object Label3: TLabel
    Left = 8
    Top = 128
    Width = 28
    Height = 13
    Caption = 'Nome'
    FocusControl = DBEdit2
  end
  object Label4: TLabel
    Left = 8
    Top = 168
    Width = 21
    Height = 13
    Caption = 'Col1'
    FocusControl = DBEdit3
  end
  object Label5: TLabel
    Left = 8
    Top = 208
    Width = 21
    Height = 13
    Caption = 'Col2'
    FocusControl = DBEdit4
  end
  object Edit2: TEdit
    Left = 9
    Top = 27
    Width = 552
    Height = 21
    TabOrder = 0
    Text = 
      'Provider=SQLNCLI10.1;Integrated Security=SSPI;Persist Security I' +
      'nfo=False;User ID="";Initial Catalog=Treinamento;Data Source=NB_' +
      'Fabiano\SQL2008R2_1;Initial File Name="";Server SPN=""'
  end
  object Button1: TButton
    Left = 8
    Top = 56
    Width = 75
    Height = 25
    Caption = 'Conectar'
    TabOrder = 1
    OnClick = Button1Click
  end
  object DBEdit1: TDBEdit
    Left = 8
    Top = 104
    Width = 134
    Height = 21
    DataField = 'ID_Cliente'
    DataSource = DataSource1
    TabOrder = 2
  end
  object DBEdit2: TDBEdit
    Left = 8
    Top = 144
    Width = 257
    Height = 21
    DataField = 'Nome'
    DataSource = DataSource1
    TabOrder = 3
  end
  object DBEdit3: TDBEdit
    Left = 8
    Top = 184
    Width = 257
    Height = 21
    DataField = 'Col1'
    DataSource = DataSource1
    TabOrder = 4
  end
  object DBEdit4: TDBEdit
    Left = 8
    Top = 224
    Width = 257
    Height = 21
    DataField = 'Col2'
    DataSource = DataSource1
    TabOrder = 5
  end
  object DBNavigator1: TDBNavigator
    Left = 16
    Top = 248
    Width = 240
    Height = 25
    DataSource = DataSource1
    TabOrder = 6
  end
  object DBGrid1: TDBGrid
    Left = 280
    Top = 72
    Width = 320
    Height = 201
    DataSource = DataSource1
    TabOrder = 7
    TitleFont.Charset = DEFAULT_CHARSET
    TitleFont.Color = clWindowText
    TitleFont.Height = -11
    TitleFont.Name = 'MS Sans Serif'
    TitleFont.Style = []
    Columns = <
      item
        Expanded = False
        FieldName = 'ID_Cliente'
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'Nome'
        Width = 91
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'Col1'
        Width = 61
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'Col2'
        Width = 57
        Visible = True
      end>
  end
  object ADOConnection1: TADOConnection
    ConnectionString = 
      'Provider=SQLNCLI10.1;Integrated Security=SSPI;Persist Security I' +
      'nfo=False;User ID="";Initial Catalog=Northwind;Data Source=dellf' +
      'abiano\sql2019;Initial File Name="";Server SPN=""'
    LoginPrompt = False
    Provider = 'SQLNCLI10.1'
    Left = 120
    Top = 8
  end
  object ADOQuery1: TADOQuery
    Connection = ADOConnection1
    Parameters = <>
    SQL.Strings = (
      'select * from clientes')
    Left = 152
    Top = 8
    object ADOQuery1ID_Cliente: TAutoIncField
      FieldName = 'ID_Cliente'
      ProviderFlags = [pfInKey]
      ReadOnly = True
    end
    object ADOQuery1Nome: TStringField
      FieldName = 'Nome'
      ProviderFlags = [pfInUpdate]
      Size = 255
    end
    object ADOQuery1Col1: TStringField
      FieldName = 'Col1'
      ProviderFlags = [pfInUpdate]
      Size = 255
    end
    object ADOQuery1Col2: TStringField
      FieldName = 'Col2'
      ProviderFlags = [pfInUpdate]
      Size = 250
    end
    object ADOQuery1ID_Cidade: TIntegerField
      FieldName = 'ID_Cidade'
      ProviderFlags = [pfInUpdate]
    end
  end
  object DataSource1: TDataSource
    DataSet = ClientDataSet1
    Left = 248
    Top = 8
  end
  object DataSetProvider1: TDataSetProvider
    DataSet = ADOQuery1
    Constraints = True
    UpdateMode = upWhereKeyOnly
    Left = 184
    Top = 8
  end
  object ClientDataSet1: TClientDataSet
    Aggregates = <>
    Params = <>
    ProviderName = 'DataSetProvider1'
    AfterPost = ClientDataSet1AfterPost
    Left = 216
    Top = 8
  end
end
