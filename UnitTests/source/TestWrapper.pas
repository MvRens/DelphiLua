unit TestWrapper;

interface
uses
  System.SysUtils,

  TestFramework,

  Lua;


type
  TTestWrapper = class(TTestCase)
  private
    FLua: TLua;
    FPrinted: TStringBuilder;
  protected
    procedure SetUp; override;
    procedure TearDown; override;

    procedure Print(AContext: ILuaContext);

    property Lua: TLua read FLua;
    property Printed: TStringBuilder read FPrinted;
  published
    procedure NewState;
    procedure LoadAndRunFromString;
    procedure LoadAndRunFromStream;
    procedure LoadMultiple;
    procedure LoadMultipleSharedVariable;
    procedure ChunkNameInException;

    procedure Input;
    procedure Output;
    procedure DelphiFunction;
    procedure DelphiFunctionException;
    procedure LuaFunction;
    procedure LuaFunctionDefaultResult;
    procedure LuaFunctionString;

    procedure TableSetGet;
    procedure TableSetTwice;
    procedure TableSetDifferentTypes;

    procedure TableInput;
    procedure TableOutput;
    procedure TableDelphiFunction;
    procedure TableLuaFunction;

    procedure VariableFunction;
    procedure ByteCode;
    procedure Capture;
    procedure DenyRequire;

    procedure RegisterObject;
    procedure RegisterObjectTable;
  end;


implementation
uses
  System.Classes;


type
  TProtectedLua = class(TLua);


  TTestObject = class(TPersistent)
  private
    FOutput: TStringBuilder;
  public
    constructor Create(AOutput: TStringBuilder);
  published
    procedure Method1(AContext: ILuaContext);
    procedure Method2(AContext: ILuaContext);
  end;


{ TTestWrapper }
procedure TTestWrapper.SetUp;
begin
  inherited;

  FPrinted := TStringBuilder.Create;

  FLua := TLua.Create;
  FLua.AutoOpenLibraries := [StringLib];
  FLua.RegisterFunction('print', Print);
end;


procedure TTestWrapper.TearDown;
begin
  FreeAndNil(FPrinted);
  FreeAndNil(FLua);

  inherited;
end;


procedure TTestWrapper.Print(AContext: ILuaContext);
begin
  FPrinted.Append(AContext.Parameters.ToString);
end;


procedure TTestWrapper.NewState;
begin
  TProtectedLua(Lua).CheckState;
end;



procedure TTestWrapper.LoadAndRunFromString;
begin
  Lua.LoadFromString('print("Hello world!")');
  CheckEquals('Hello world!', Printed.ToString);
end;


procedure TTestWrapper.LoadAndRunFromStream;
begin
  Lua.LoadFromStream(TStringStream.Create('print("Hello world!")'), soOwned);
  CheckEquals('Hello world!', Printed.ToString);
end;


procedure TTestWrapper.LoadMultiple;
begin
  Lua.LoadFromString('print "Hello world!"', True, 'Script1');
  Lua.LoadFromString('print "Goodbye world!"', True, 'Script2');

  CheckEquals('Hello world!Goodbye world!', Printed.ToString);
end;


procedure TTestWrapper.LoadMultipleSharedVariable;
begin
  Lua.LoadFromString('message = "Hello world!"', True, 'Script1');
  Lua.LoadFromString('print(message)', True, 'Script2');

  CheckEquals('Hello world!', Printed.ToString);
end;

procedure TTestWrapper.Input;
begin
  Lua.SetGlobalVariable('thingy', 'world');
  Lua.LoadFromString('print("Hello "..thingy.."!")');

  CheckEquals('Hello world!', Printed.ToString);
end;


procedure TTestWrapper.Output;
var
  output: ILuaVariable;

begin
  Lua.LoadFromString('output = "Hello world!"');

  output := lua.GetGlobalVariable('output');
  CheckNotNull(output, 'output is nil');
  CheckEquals('Hello world!', output.AsString);
end;


procedure TTestWrapper.ChunkNameInException;
begin
  Lua.LoadFromString('print("This one''s alright")', True, 'Script1');

  try
    Lua.LoadFromString('print("This one isn''t"', True, 'Script2');
    Fail('ELuaException expected');
  except
    on E:Exception do
    begin
      CheckIs(E, ELuaException);
      CheckEquals('[string "Script2"]:1: '')'' expected near <eof>', E.Message);
    end;
  end;

  Lua.LoadFromString('print("Fine again!")', True, 'Script3');
  CheckEquals('This one''s alrightFine again!', Printed.ToString);
end;


procedure TTestWrapper.DelphiFunction;
begin
  Lua.RegisterFunction('myuppercase',
    procedure(AContext: ILuaContext)
    begin
      AContext.Result.Push(UpperCase(AContext.Parameters[0].AsString));
    end);

  Lua.LoadFromString('print(myuppercase("Hello world!"))');
  CheckEquals('HELLO WORLD!', Printed.ToString);
end;


procedure TTestWrapper.DelphiFunctionException;
begin
  Lua.RegisterFunction('crazyharry',
    procedure(AContext: ILuaContext)
    begin
      raise Exception.Create('Boom!');
    end);

  try
    Lua.LoadFromString('print(crazyharry("Did somebody say dynamite?"))');
    Fail('ELuaNativeCodeException expected');
  except
    on E:Exception do
    begin
      CheckIs(E, ELuaException);
      CheckEquals('[string "?"]:1: Boom!', E.Message);
    end;
  end;
end;


procedure TTestWrapper.LuaFunction;
var
  returnValues: ILuaReadParameters;

begin
  Lua.LoadFromString('function sum(a, b)'#13#10 +
                     '  return a + b'#13#10 +
                     'end');

  returnValues := Lua.Call('sum', [1, 2]);
  CheckEquals(1, returnValues.Count, 'returnValues Count');
  CheckEquals(3, returnValues[0].AsInteger, 'returnValues[0]');

  returnValues := Lua.Call('sum', [4, 12]);
  CheckEquals(1, returnValues.Count, 'returnValues Count');
  CheckEquals(16, returnValues[0].AsInteger, 'returnValues[0]');
end;


procedure TTestWrapper.LuaFunctionDefaultResult;
var
  returnValues: ILuaReadParameters;

begin
  Lua.LoadFromString('function sum(a, b)'#13#10 +
                     '  return a + b'#13#10 +
                     'end');

  returnValues := Lua.Call('sum', [1, 2]);
  CheckEquals(1, returnValues.Count, 'returnValues Count');
  CheckEquals(3, returnValues.AsInteger, 'returnValues');
end;


procedure TTestWrapper.LuaFunctionString;
var
  returnValues: ILuaReadParameters;

begin
  Lua.LoadFromString('function echo(sound)'#13#10 +
                     '  return string.sub(sound, 2)'#13#10 +
                     'end');

  returnValues := Lua.Call('echo', ['hello?']);
  CheckEquals(1, returnValues.Count, 'returnValues Count');
  CheckEquals('ello?', returnValues[0].AsString, 'returnValues[0]');
end;

procedure TTestWrapper.TableSetGet;
var
  table: ILuaTable;

begin
  table := TLuaTable.Create;
  table.SetValue('key', 'value');
  CheckEquals('value', table.GetValue('key').AsString);
end;


procedure TTestWrapper.TableSetTwice;
var
  table: ILuaTable;

begin
  table := TLuaTable.Create;
  table.SetValue('key', 'value');
  table.SetValue('key', 'newvalue');
  CheckEquals('newvalue', table.GetValue('key').AsString);
end;


procedure TTestWrapper.TableSetDifferentTypes;
var
  table: ILuaTable;

begin
  // Automatic number conversion is not applicable to table keys in Lua
  table := TLuaTable.Create;
  table.SetValue('1', 'stringValue');
  table.SetValue(1, 'numberValue');
  CheckEquals('stringValue', table.GetValue('1').AsString);
  CheckEquals('numberValue', table.GetValue(1).AsString);
end;


procedure TTestWrapper.TableInput;
var
  input: ILuaTable;

begin
  input := TLuaTable.Create;
  input.SetValue('text', 'Hello world!');

  Lua.LoadFromString('print(message.text)', False);
  Lua.SetGlobalVariable('message', input);
  Lua.Run;

  CheckEquals('Hello world!', Printed.ToString);
end;


procedure TTestWrapper.TableOutput;
var
  output: ILuaVariable;
  answer: ILuaVariable;

begin
  Lua.LoadFromString('output = { answer = 42 }');

  output := lua.GetGlobalVariable('output');
  CheckNotNull(output, 'output is nil');
  CheckNotNull(output.AsTable, 'output.AsTable is nil');

  answer := output.AsTable.GetValue('answer');
  CheckNotNull(answer, 'answer is nil');
  CheckEquals(42, answer.AsInteger);
end;


procedure TTestWrapper.TableDelphiFunction;
begin
  Lua.RegisterFunction('invertTable',
    procedure(AContext: ILuaContext)
    var
      input: ILuaTable;
      output: ILuaTable;
      pair: TLuaKeyValuePair;

    begin
      input := AContext.Parameters[0].AsTable;
      output := TLuaTable.Create;

      for pair in input do
        output.SetValue(pair.Value, pair.Key);

      AContext.Result.Push(output);
    end);

  Lua.LoadFromString('table = invertTable({ value = "key" })'#13#10 +
                     'print(table.key)');
  CheckEquals('value', Printed.ToString);
end;


procedure TTestWrapper.TableLuaFunction;
var
  input: ILuaTable;
  returnValues: ILuaReadParameters;

begin
  input := TLuaTable.Create;
  input.SetValue('bob', 'release roderick!');

  Lua.LoadFromString('function pilate(crowd)'#13#10 +
                     '  local value, count = string.gsub(crowd.bob, "r", "w")'#13#10 +
                     '  return value'#13#10 +
                     'end');

  returnValues := Lua.Call('pilate', [input]);
  CheckEquals(1, returnValues.Count, 'returnValues Count');
  CheckEquals('welease wodewick!', returnValues[0].AsString, 'returnValue[0]');
end;


procedure TTestWrapper.VariableFunction;
var
  functions: ILuaTable;
  returnValues: ILuaReadParameters;

begin
  Lua.LoadFromString('functions = {}'#13#10 +
                     'functions.callme = function(name)'#13#10 +
                     '  return "Hello "..name'#13#10 +
                     'end'#13#10 +
                     'functions.callmetoo = function()'#13#10 +
                     '  print("So long, and thanks for all the fish.")'#13#10 +
                     'end'#13#10);

  functions := Lua.GetGlobalVariable('functions').AsTable;
  returnValues := functions.GetValue('callme').AsFunction.Call(['Jack']);

  CheckEquals('Hello Jack', returnValues.AsString);
end;


procedure TTestWrapper.ByteCode;
var
  compileLua: TLua;
  byteCode: TMemoryStream;

begin
  byteCode := TMemoryStream.Create;
  try
    compileLua := TLua.Create;
    try
      compileLua.LoadFromString('print("Hello world!")', False);
      compileLua.GetByteCode(byteCode, True);
    finally
      FreeAndNil(compileLua);
    end;

    byteCode.Position := 0;
    Lua.LoadFromStream(byteCode);
    CheckEquals('Hello world!', Printed.ToString);
  finally
    FreeAndNil(byteCode);
  end;
end;


procedure TTestWrapper.Capture;
begin
  // Capture is a convenience method which puts a script's variables and
  // functions in a global table variable. Useful for example when
  // implementing a sandboxed API.
  Lua.LoadFromString('message = "Hello world!"'#13#10 +
                     'function outputMessage()'#13#10 +
                     '  print(message)'#13#10 +
                     'end', False, 'Script1');
  Lua.Capture('Captured');

  Lua.LoadFromString('print(Captured.message)'#13#10 +
                     'Captured.message = "Goodbye world!"'#13#10 +
                     'Captured.outputMessage()', True, 'Script2');

  CheckEquals('Hello world!Goodbye world!', Printed.ToString);
end;


procedure TTestWrapper.DenyRequire;
begin
  try
    // This should fail, since we're not loading the Package library which
    // adds the require function that can be considered a security risk.
    Lua.LoadFromString('require("Test")');
    Fail('ELuaException expected');
  except
    on E:Exception do
    begin
      CheckIs(E, ELuaException);
    end;
  end;
end;


procedure TTestWrapper.RegisterObject;
var
  testObject: TTestObject;

begin
  testObject := TTestObject.Create(FPrinted);
  try
    Lua.RegisterFunctions(testObject);
    Lua.LoadFromString('Method1("Hello")'#13#10 +
                       'Method2("world!")');

    CheckEquals('Method1:HelloMethod2:world!', Printed.ToString);
  finally
    FreeAndNil(testObject);
  end;
end;


procedure TTestWrapper.RegisterObjectTable;
var
  testObject: TTestObject;

begin
  testObject := TTestObject.Create(FPrinted);
  try
    Lua.RegisterFunctions(testObject, 'Test');
    Lua.LoadFromString('Test.Method1("Hello")'#13#10 +
                       'Test.Method2("world!")');

    CheckEquals('Method1:HelloMethod2:world!', Printed.ToString);
  finally
    FreeAndNil(testObject);
  end;
end;


{ TTestObject }
constructor TTestObject.Create(AOutput: TStringBuilder);
begin
  inherited Create;

  FOutput := AOutput;
end;


procedure TTestObject.Method1(AContext: ILuaContext);
begin
  FOutput.Append('Method1:' + AContext.Parameters[0].AsString);
end;

procedure TTestObject.Method2(AContext: ILuaContext);
begin
  FOutput.Append('Method2:' + AContext.Parameters[0].AsString);
end;

initialization
  RegisterTest(TTestWrapper.Suite);

end.
