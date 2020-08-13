unit MainFrm;

interface
uses
  System.Classes,
  Vcl.ComCtrls,
  Vcl.Controls,
  Vcl.ExtCtrls,
  Vcl.Forms,
  Vcl.StdCtrls,

  Lua;


type
  TMainForm = class(TForm)
    PageControl: TPageControl;
    FunctionReferenceTab: TTabSheet;
    FunctionReferenceRichEdit: TRichEdit;
    LogRichEdit: TRichEdit;
    FunctionReferenceButtonPanel: TPanel;
    FunctionReferenceGetButton: TButton;
    FunctionReferenceCallStartupButton: TButton;

    procedure FormDestroy(Sender: TObject);
    procedure FunctionReferenceGetButtonClick(Sender: TObject);
    procedure FunctionReferenceCallStartupButtonClick(Sender: TObject);
  private
    FFunctionReferenceLua: TLua;
    FFunctionReferenceEngine: ILuaTable;
    FFunctionReferenceEngineDisplay: ILuaTable;
    FFunctionReferenceStartup: ILuaFunction;

    procedure CreateLua(var ALua: TLua; ACode: TStrings);

    procedure Log(const AMessage: string);
    procedure Print(AContext: ILuaContext);
  end;


implementation
uses
  System.SysUtils;


{$R *.dfm}

{ TMainForm }
procedure TMainForm.FormDestroy(Sender: TObject);
begin
  FFunctionReferenceEngineDisplay := nil;
  FFunctionReferenceEngine := nil;
  FFunctionReferenceStartup := nil;
  FreeAndNil(FFunctionReferenceLua);
end;


procedure TMainForm.FunctionReferenceGetButtonClick(Sender: TObject);
begin
  try
    CreateLua(FFunctionReferenceLua, FunctionReferenceRichEdit.Lines);

    Log('Initializing global variable "engine"...');
    FFunctionReferenceEngineDisplay := TLuaTable.Create;
    FFunctionReferenceEngineDisplay.SetValue('log',
      procedure(Context: ILuaContext)
      begin
        Log(Context.Parameters.ToString);
      end);

    FFunctionReferenceEngine := TLuaTable.Create;
    FFunctionReferenceEngine.SetValue('display', FFunctionReferenceEngineDisplay);

    FFunctionReferenceLua.SetGlobalVariable('engine', FFunctionReferenceEngine);

    Log('Running code...');
    FFunctionReferenceLua.Run;

    Log('Reading back global variable "engine"...');
    FFunctionReferenceEngine := FFunctionReferenceLua.GetGlobalVariable('engine').AsTable;

    Log('Reading engine.onStartup...');
    FFunctionReferenceStartup := FFunctionReferenceEngine.GetValue('onStartup').AsFunction;
    if not Assigned(FFunctionReferenceStartup) then
    begin
      Log('Error: onStartup not found!');
      Exit;
    end;

    Log('Done.');
  except
    on E:Exception do
      Log(E.ClassName + ': ' + E.Message);
  end;
end;


procedure TMainForm.FunctionReferenceCallStartupButtonClick(Sender: TObject);
begin
  FFunctionReferenceStartup.Call();
end;


procedure TMainForm.CreateLua(var ALua: TLua; ACode: TStrings);
begin
  FreeAndNil(ALua);
  Log('Loading Lua code...');

  ALua := TLua.Create;
  ALua.RegisterFunction('print', Print);

  ALua.LoadFromString(ACode.Text, False);
end;


procedure TMainForm.Log(const AMessage: string);
begin
  LogRichEdit.Lines.Add(AMessage);
  LogRichEdit.SelStart := MaxInt;
end;


procedure TMainForm.Print(AContext: ILuaContext);
begin
  Log(AContext.Parameters.ToString);
end;

end.
