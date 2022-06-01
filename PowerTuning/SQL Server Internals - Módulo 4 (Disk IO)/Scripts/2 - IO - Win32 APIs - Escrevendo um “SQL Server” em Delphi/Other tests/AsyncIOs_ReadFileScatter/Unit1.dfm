object Form1: TForm1
  Left = 457
  Top = 187
  Width = 1033
  Height = 490
  Caption = 'InternalsParte4_Win32API_AsyncIOs_ReadFileScatter'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 16
    Top = 120
    Width = 124
    Height = 13
    Caption = 'Tamanho do I/O em bytes'
  end
  object Label2: TLabel
    Left = 16
    Top = 80
    Width = 45
    Height = 13
    Caption = 'Arquivo...'
  end
  object Label5: TLabel
    Left = 16
    Top = 416
    Width = 97
    Height = 17
    Alignment = taCenter
    AutoSize = False
    Caption = 'MB - ms - MB/s'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
  end
  object Memo3: TMemo
    Left = 16
    Top = 144
    Width = 321
    Height = 265
    ScrollBars = ssBoth
    TabOrder = 0
  end
  object Button4: TButton
    Left = 16
    Top = 16
    Width = 457
    Height = 25
    Caption = 
      'Chama ReadFileScatter com  FILE_FLAG_OVERLAPPED + FILE_FLAG_NO_B' +
      'UFFERING'
    TabOrder = 1
    OnClick = Button4Click
  end
  object ProgressBar1: TProgressBar
    Left = 16
    Top = 48
    Width = 977
    Height = 17
    Min = 0
    Max = 100
    TabOrder = 2
  end
  object Edit1: TEdit
    Left = 152
    Top = 117
    Width = 97
    Height = 21
    TabOrder = 3
    Text = '65536'
  end
  object edtfPath: TEdit
    Left = 64
    Top = 77
    Width = 937
    Height = 21
    TabOrder = 4
    Text = 
      'D:\Fabiano\Trabalho\FabricioLima\Cursos\SQL Server Internals - M' +
      #243'dulo 4 (IO, Latches e Tempdb)\Scripts\Win32APIs\3 - InternalsPa' +
      'rte4_Win32API_AsyncIOs_ReadFileScatter\Test1.txt'
  end
end
