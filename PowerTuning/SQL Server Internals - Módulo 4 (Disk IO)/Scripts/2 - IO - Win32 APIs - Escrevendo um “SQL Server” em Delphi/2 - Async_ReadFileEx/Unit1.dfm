object Form1: TForm1
  Left = 457
  Top = 187
  Width = 514
  Height = 499
  Caption = 'InternalsParte4_Win32API_AsyncIOs_ReadFileEx'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object Memo3: TMemo
    Left = 88
    Top = 40
    Width = 297
    Height = 393
    ScrollBars = ssBoth
    TabOrder = 0
  end
  object Button4: TButton
    Left = 16
    Top = 8
    Width = 457
    Height = 25
    Caption = 
      'Chama ReadFileEx com Async I/O - Lendo arquivo com lenght de 10 ' +
      'e 8 threads'
    TabOrder = 1
    OnClick = Button4Click
  end
  object Panel1: TPanel
    Left = 736
    Top = 56
    Width = 441
    Height = 377
    TabOrder = 2
    Visible = False
  end
end
