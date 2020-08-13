object MainForm: TMainForm
  Left = 0
  Top = 0
  Caption = 'DelphiLua Interactive Test'
  ClientHeight = 547
  ClientWidth = 678
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poDesktopCenter
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object PageControl: TPageControl
    AlignWithMargins = True
    Left = 8
    Top = 8
    Width = 662
    Height = 416
    Margins.Left = 8
    Margins.Top = 8
    Margins.Right = 8
    Margins.Bottom = 8
    ActivePage = FunctionReferenceTab
    Align = alClient
    TabOrder = 0
    object FunctionReferenceTab: TTabSheet
      Caption = 'Function reference'
      object FunctionReferenceRichEdit: TRichEdit
        AlignWithMargins = True
        Left = 8
        Top = 49
        Width = 638
        Height = 331
        Margins.Left = 8
        Margins.Top = 8
        Margins.Right = 8
        Margins.Bottom = 8
        Align = alClient
        Font.Charset = ANSI_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Courier New'
        Font.Style = []
        Lines.Strings = (
          'function engine.onStartup()'
          '  engine.myFunction()'
          '  engine.display.log("Hello from display.log!")'
          'end'
          ''
          ''
          'function engine.myFunction()'
          '  print("Hello from myFunction!")'
          '  engine.display.log("Hello from myFunction'#39's display.log!")'
          'end')
        ParentFont = False
        ScrollBars = ssBoth
        TabOrder = 1
      end
      object FunctionReferenceButtonPanel: TPanel
        Left = 0
        Top = 0
        Width = 654
        Height = 41
        Align = alTop
        BevelOuter = bvNone
        TabOrder = 0
        object FunctionReferenceGetButton: TButton
          Left = 8
          Top = 13
          Width = 121
          Height = 25
          Caption = 'Lookup functions'
          TabOrder = 0
          OnClick = FunctionReferenceGetButtonClick
        end
        object FunctionReferenceCallStartupButton: TButton
          Left = 135
          Top = 13
          Width = 121
          Height = 25
          Caption = 'Call onStartup'
          TabOrder = 1
          OnClick = FunctionReferenceCallStartupButtonClick
        end
      end
    end
  end
  object LogRichEdit: TRichEdit
    AlignWithMargins = True
    Left = 8
    Top = 432
    Width = 662
    Height = 107
    Margins.Left = 8
    Margins.Top = 0
    Margins.Right = 8
    Margins.Bottom = 8
    Align = alBottom
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
    ReadOnly = True
    ScrollBars = ssVertical
    TabOrder = 1
  end
end
