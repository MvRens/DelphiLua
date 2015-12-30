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
    procedure LoadMultiple;
    procedure ChunkNameInException;

    procedure Input;
    procedure Output;
    procedure DelphiFunction;
    procedure LuaFunction;
    procedure LuaFunctionString;

    procedure TableSetGet;
    procedure TableSetTwice;
    procedure TableSetDifferentTypes;

    procedure TableInput;
    procedure TableOutput;
    procedure TableDelphiFunction;
    procedure TableLuaFunction;
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



initialization
  RegisterTest(TTestWrapper.Suite);

end.
