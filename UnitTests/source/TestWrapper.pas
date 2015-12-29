unit TestWrapper;

interface
uses
  System.SysUtils,

  TestFramework,

  Lua.Wrapper;


type
  TTestWrapper = class(TTestCase)
  private
    FLua: TLua;
    FPrinted: TStringBuilder;
  protected
    procedure SetUp; override;
    procedure TearDown; override;

    property Lua: TLua read FLua;
    property Printed: TStringBuilder read FPrinted;
  published
    procedure NewState;
    procedure LoadAndRunFromString;
    procedure LoadAndRunFromStream;

    procedure FunctionResult;
    procedure CallLuaFunction;
  end;


implementation
uses
  System.Classes;


type
  TProtectedLua = class(TLua);


{ TTestWrapper }
procedure TTestWrapper.SetUp;
begin
  inherited;

  FPrinted := TStringBuilder.Create;

  FLua := TLua.Create;
  FLua.RegisterFunction('print',
    procedure(AContext: ILuaContext)
    begin
      FPrinted.Append(AContext.Parameters.ToString);
    end);
end;


procedure TTestWrapper.TearDown;
begin
  FreeAndNil(FPrinted);
  FreeAndNil(FLua);

  inherited;
end;


procedure TTestWrapper.NewState;
begin
  TProtectedLua(Lua).CheckState;
end;



procedure TTestWrapper.LoadAndRunFromString;
begin
  Lua.LoadFromString('print("Hello world!")');
  Lua.Run;
  CheckEquals('Hello world!', Printed.ToString);
end;


procedure TTestWrapper.LoadAndRunFromStream;
begin
  Lua.LoadFromStream(TStringStream.Create('print("Hello world!")'));
  Lua.Run;
  CheckEquals('Hello world!', Printed.ToString);
end;


procedure TTestWrapper.FunctionResult;
begin
  Lua.RegisterFunction('myuppercase',
    procedure(AContext: ILuaContext)
    begin
      AContext.Result.Push(UpperCase(AContext.Parameters[0].AsString));
    end);

  Lua.LoadFromString('print(myuppercase("Hello world!"))');
  Lua.Run;
  CheckEquals('HELLO WORLD!', Printed.ToString);
end;


procedure TTestWrapper.CallLuaFunction;
var
  returnValues: ILuaReadParameters;

begin
  Lua.LoadFromString('function sum(a, b)'#13#10 +
                     '  return a + b'#13#10 +
                     'end');

  returnValues := Lua.Call('sum', [1, 2]);
  CheckEquals(1, returnValues.Count, 'returnValues Count');
  CheckEquals(3, returnValues[0].AsInteger, 'returnValues[0]');
end;


initialization
  RegisterTest(TTestWrapper.Suite);

end.
