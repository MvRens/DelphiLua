unit TestAPI;

interface
uses
  TestFramework;


type
  TTestAPI = class(TTestCase)
  protected
    procedure SetUp; override;
  published
    procedure NewStateAndClose;
    procedure Load;
    procedure LoadAndCall;
  end;


implementation
uses
  Classes,
  SysUtils,

  Lua;


{ TTestAPI }
procedure TTestAPI.SetUp;
begin
  inherited;

  LoadLuaLib;
end;


procedure TTestAPI.NewStateAndClose;
var
  state: lua_State;

begin
  state := lua_newstate(@DefaultLuaAlloc, nil);
  try
    Check(Assigned(state), 'state is not assigned');
  finally
    lua_close(state);
  end;
end;



type
  PLuaScript = ^TLuaScript;
  TLuaScript = record
    Data: AnsiString;
    Remaining: Integer;

    constructor Create(const AData: string);
  end;


{ TLuaScript }
constructor TLuaScript.Create(const AData: string);
begin
  Data := AnsiString(AData);
  Remaining := Length(Data);
end;


function TestReaderProc(L: lua_State; ud: Pointer; var sz: size_t): PAnsiChar; cdecl;
var
  script: PLuaScript;

begin
  script := ud;
  if script^.Remaining = 0 then
  begin
    Result := nil;
    exit;
  end;

  sz := script^.Remaining;
  script^.Remaining := 0;

  Result := PAnsiChar(script^.Data);
end;


procedure TTestAPI.Load;
var
  state: lua_State;
  script: TLuaScript;

begin
  state := lua_newstate(@DefaultLuaAlloc, nil);
  try
    script := TLuaScript.Create('print("Hello world!")');
    CheckEquals(0, lua_load(state, @TestReaderProc, @script, nil, nil), 'lua_load result');
  finally
    lua_close(state);
  end;
end;


procedure TTestAPI.LoadAndCall;
var
  state: lua_State;
  script: TLuaScript;

begin
  state := lua_newstate(@DefaultLuaAlloc, nil);
  try
    luaopen_base(state);

    script := TLuaScript.Create('print("Hello world!")');
    CheckEquals(0, lua_load(state, @TestReaderProc, @script, nil, nil), 'lua_load result');

    if lua_pcall(state, 0, 0, 0) <> 0 then
      Fail(string(lua_tolstring(state, -1, nil)));
  finally
    lua_close(state);
  end;
end;


initialization
  RegisterTest(TTestAPI.Suite);

end.
