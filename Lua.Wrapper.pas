unit Lua.Wrapper;

interface
uses
  System.Classes,
  System.Generics.Collections,
  System.SysUtils,

  Lua;

type
  ELuaException = class(Exception);
  ELuaInitException = class(ELuaException);

  TLuaLibrary = (Base, Coroutine, Table, IO, OS, StringLib, Bit32, Math, Debug, Package, All);
  TLuaLibraries = set of TLuaLibrary;

  TLuaDataType = (LuaNone, LuaNil, LuaNumber, LuaBoolean, LuaString, LuaTable,
                  LuaCFunction, LuaUserData, LuaThread, LuaLightUserData);

  ILuaParameter = interface
    ['{ADA0D4FB-F0FB-4493-8FEC-6FC92C80117F}']
    function GetAsBoolean: Boolean;
    function GetAsInteger: Integer;
    function GetAsNumber: Double;
    function GetAsUserData: Pointer;
    function GetAsString: string;
    function GetDataType: TLuaDataType;
    function GetIndex: Integer;

    property AsBoolean: Boolean read GetAsBoolean;
    property AsInteger: Integer read GetAsInteger;
    property AsNumber: Double read GetAsNumber;
    property AsUserData: Pointer read GetAsUserData;
    property AsString: string read GetAsString;
    property DataType: TLuaDataType read GetDataType;

    property Index: Integer read GetIndex;
  end;


  ILuaParameters = interface
    ['{FB611D9E-B51D-460B-B5AB-B567EF853222}']
    function GetCount: Integer;
    function GetItem(Index: Integer): ILuaParameter;
    function GetState: lua_State;

    function ToString: string;

    property Count: Integer read GetCount;
    property Items[Index: Integer]: ILuaParameter read GetItem; default;

    property State: lua_State read GetState;
  end;


  ILuaResult = interface
    ['{5CEEB16B-158E-44BE-8CAD-DC2C330A244A}']
    function GetCount: Integer;

    procedure Push(ABoolean: Boolean); overload;
    procedure Push(AInteger: Integer); overload;
    procedure Push(ANumber: Double); overload;
    procedure Push(AUserData: Pointer); overload;
    procedure Push(const AString: string); overload;

    property Count: Integer read GetCount;
  end;


  ILuaContext = interface
    ['{1F999593-E3D1-4195-9463-A42025AE9830}']
    function GetParameters: ILuaParameters;
    function GetResult: ILuaResult;

    property Parameters: ILuaParameters read GetParameters;
    property Result: ILuaResult read GetResult;
  end;


  TLuaFunction = reference to procedure(Context: ILuaContext);


  TLuaRegisteredFunction = record
    Name: string;
    Callback: TLuaFunction;
  end;

  TLuaRegisteredFunctionDictionary = TDictionary<Integer, TLuaRegisteredFunction>;


  TLua = class(TObject)
  private
    FState: lua_State;
    FLoaded: Boolean;
    FRegisteredFunctions: TLuaRegisteredFunctionDictionary;
    FRegisteredFunctionCookie: Integer;
    FAutoOpenLibraries: TLuaLibraries;

    function GetHasState: Boolean;
    function GetState: lua_State;
    function GetRegisteredFunctions: TLuaRegisteredFunctionDictionary;
  protected
    function DoAlloc(APointer: Pointer; AOldSize, ANewSize: Cardinal): Pointer; virtual;

    procedure DoNewState; virtual;
    procedure DoClose; virtual;
    procedure DoRegisterFunction(ACookie: Integer); virtual;

    procedure SetAutoOpenLibraries(const Value: TLuaLibraries); virtual;
  protected
    procedure CheckState; virtual;
    procedure RaiseLastLuaError; virtual;
    procedure AfterLoad; virtual;

    function GetRegisteredFunctionCookie: Integer; virtual;
    function RunRegisteredFunction(ACookie: Integer): Integer; virtual;

    property Loaded: Boolean read FLoaded write FLoaded;
    property RegisteredFunctions: TLuaRegisteredFunctionDictionary read GetRegisteredFunctions;
  public
    constructor Create;
    destructor Destroy; override;

    procedure LoadFromString(const AData: string; const AChunkName: string = ''); virtual;
    procedure LoadFromStream(AStream: TStream; AOwnership: TStreamOwnership = soReference; const AChunkName: string = ''); virtual;

    procedure RegisterFunction(const AName: string; AFunction: TLuaFunction);

    procedure OpenLibraries(ALibraries: TLuaLibraries); virtual;
    procedure Call; virtual;

    property HasState: Boolean read GetHasState;
    property State: lua_State read GetState;

    property AutoOpenLibraries: TLuaLibraries read FAutoOpenLibraries write SetAutoOpenLibraries default [TLuaLibrary.All];
  end;


implementation
uses
  System.Math;


type
  PLuaScript = ^TLuaScript;
  TLuaScript = class(TObject)
  private
    FStream: TStream;
    FStreamOwnership: TStreamOwnership;
    FBuffer: PAnsiChar;
  public
    constructor Create(const AData: string); overload;
    constructor Create(const AStream: TStream; AOwnership: TStreamOwnership = soReference); overload;
    destructor Destroy; override;

    function GetNextChunk(out ASize: Cardinal): PAnsiChar;
  end;


  TLuaParameters = class(TInterfacedObject, ILuaParameters)
  private
    FState: lua_State;
    FCount: Integer;
  protected
    property State: lua_State read FState;
  public
    constructor Create(AState: lua_State);

    function PushResultParameters: Integer;
  public
    { ILuaParameters }
    function GetCount: Integer;
    function GetItem(Index: Integer): ILuaParameter;
    function GetState: lua_State;

    function ToString: string; override;
  end;


  TLuaParameter = class(TInterfacedObject, ILuaParameter)
  private
    FState: lua_State;
    FIndex: Integer;
  protected
    property State: lua_State read FState;
  public
    constructor Create(AState: lua_State; AIndex: Integer);

    { ILuaParameter }
    function GetAsBoolean: Boolean;
    function GetAsInteger: Integer;
    function GetAsNumber: Double;
    function GetAsUserData: Pointer;
    function GetAsString: string;
    function GetDataType: TLuaDataType;
    function GetIndex: Integer;
  end;


  TLuaResult = class(TInterfacedObject, ILuaResult)
  private
    FState: lua_State;
    FCount: Integer;
  protected
    procedure Pushed;

    property State: lua_State read FState;
  public
    constructor Create(AState: lua_State);

    { ILuaResult }
    function GetCount: Integer;

    procedure Push(ABoolean: Boolean); overload;
    procedure Push(AInteger: Integer); overload;
    procedure Push(ANumber: Double); overload;
    procedure Push(AUserData: Pointer); overload;
    procedure Push(const AString: string); overload;
  end;


  TLuaContext = class(TInterfacedObject, ILuaContext)
  private
    FParameters: ILuaParameters;
    FResult: ILuaResult;
  public
    constructor Create(AState: lua_State);

    { ILuaContext }
    function GetParameters: ILuaParameters;
    function GetResult: ILuaResult;
  end;



{ TLuaScript }
constructor TLuaScript.Create(const AData: string);
begin
  Create(TStringStream.Create(AData), soOwned);
end;


constructor TLuaScript.Create(const AStream: TStream; AOwnership: TStreamOwnership);
begin
  inherited Create;

  FStream := AStream;
  FStreamOwnership := AOwnership;
end;


destructor TLuaScript.Destroy;
begin
  if Assigned(FBuffer) then
    FreeMem(FBuffer);

  if FStreamOwnership = soOwned then
    FreeAndNil(FStream);

  inherited Destroy;
end;


function TLuaScript.GetNextChunk(out ASize: Cardinal): PAnsiChar;
const
  BufferSize = 4096;

begin
  if not Assigned(FBuffer) then
    GetMem(FBuffer, BufferSize);

  ASize := FStream.Read(FBuffer^, BufferSize);
  if ASize > 0 then
    Result := FBuffer
  else
    Result := nil;
end;



{ Callback functions }
function LuaWrapperAlloc(ud, ptr: Pointer; osize, nsize: size_t): Pointer; cdecl;
begin
  Result := TLua(ud).DoAlloc(ptr, osize, nsize);
end;


function LuaWrapperReader(L: lua_State; ud: Pointer; var sz: size_t): PAnsiChar; cdecl;
var
  script: PLuaScript;

begin
  script := ud;
  Result := script^.GetNextChunk(sz);
end;


function LuaWrapperFunction(L: lua_State): Integer; cdecl;
var
  lua: TLua;
  cookie: Integer;

begin
  Result := 0;

  lua := TLua(lua_touserdata(L, lua_upvalueindex(1)));
  cookie := lua_tointeger(L, lua_upvalueindex(2));

  if Assigned(lua) then
    Result := lua.RunRegisteredFunction(cookie);
end;


function NilPAnsiChar(const AValue: string): PAnsiChar;
begin
  if Length(AValue) > 0 then
    Result := PAnsiChar(AnsiString(AValue))
  else
    Result := nil;
end;


{ TLua }
constructor TLua.Create;
begin
  inherited Create;

  FAutoOpenLibraries := [TLuaLibrary.All];
end;


destructor TLua.Destroy;
begin
  FreeAndNil(FRegisteredFunctions);

  if HasState then
    DoClose;

  inherited Destroy;
end;


procedure TLua.LoadFromString(const AData: string; const AChunkName: string);
var
  script: TLuaScript;

begin
  script := TLuaScript.Create(AData);
  try
    if lua_load(State, LuaWrapperReader, @script, NilPAnsiChar(AChunkName), nil) <> 0 then
      RaiseLastLuaError;

    AfterLoad;
  finally
    FreeAndNil(script);
  end;
end;


procedure TLua.LoadFromStream(AStream: TStream; AOwnership: TStreamOwnership; const AChunkName: string);
var
  script: TLuaScript;

begin
  script := TLuaScript.Create(AStream, AOwnership);
  try
    if lua_load(State, LuaWrapperReader, @script, NilPAnsiChar(AChunkName), nil) <> 0 then
      RaiseLastLuaError;

    AfterLoad;
  finally
    FreeAndNil(script);
  end;
end;


procedure TLua.OpenLibraries(ALibraries: TLuaLibraries);
begin
  if TLuaLibrary.All in ALibraries then
    luaL_openlibs(State)
  else
  begin
    if TLuaLibrary.Base in ALibraries then
      luaopen_base(State);

    if TLuaLibrary.Coroutine in ALibraries then
      luaopen_coroutine(State);

    if TLuaLibrary.Table in ALibraries then
      luaopen_table(State);

    if TLuaLibrary.IO in ALibraries then
      luaopen_io(State);

    if TLuaLibrary.OS in ALibraries then
      luaopen_os(State);

    if TLuaLibrary.StringLib in ALibraries then
      luaopen_string(State);

    if TLuaLibrary.Bit32 in ALibraries then
      luaopen_bit32(State);

    if TLuaLibrary.Math in ALibraries then
      luaopen_math(State);

    if TLuaLibrary.Debug in ALibraries then
      luaopen_debug(State);

    if TLuaLibrary.Package in ALibraries then
      luaopen_package(State);
  end;
end;


procedure TLua.Call;
begin
  if lua_pcall(State, 0, 0, 0) <> 0 then
    RaiseLastLuaError;
end;


procedure TLua.CheckState;
begin
  if not LuaLibLoaded then
    LoadLuaLib;

  if not HasState then
    DoNewState;
end;


procedure TLua.RaiseLastLuaError;
begin
  raise ELuaException.Create(string(lua_tolstring(State, -1, nil)));
end;


procedure TLua.AfterLoad;
var
  cookie: Integer;

begin
  Loaded := True;

  { Register functions in the current environment }
  for cookie in RegisteredFunctions.Keys do
    DoRegisterFunction(cookie);
end;


procedure TLua.RegisterFunction(const AName: string; AFunction: TLuaFunction);
var
  registeredFunction: TLuaRegisteredFunction;
  cookie: Integer;

begin
  { Since anonymous methods are basically interfaces, we need to keep a reference around }
  registeredFunction.Name := AName;
  registeredFunction.Callback := AFunction;

  cookie := GetRegisteredFunctionCookie;
  RegisteredFunctions.Add(cookie, registeredFunction);

  { Only register functions after Load, otherwise they'll not be available in the environment }
  if Loaded then
    DoRegisterFunction(cookie);
end;


function TLua.DoAlloc(APointer: Pointer; AOldSize, ANewSize: Cardinal): Pointer;
begin
  Result := DefaultLuaAlloc(nil, APointer, AOldSize, ANewSize);
end;


procedure TLua.DoNewState;
begin
  FState := lua_newstate(@LuaWrapperAlloc, Pointer(Self));
  if not HasState then
    raise ELuaInitException.Create('Failed to initialize new state');

  OpenLibraries(AutoOpenLibraries);
end;


procedure TLua.DoClose;
begin
  lua_close(FState);
  FState := nil;
end;


procedure TLua.DoRegisterFunction(ACookie: Integer);
var
  name: string;

begin
  name := RegisteredFunctions[ACookie].Name;

  lua_pushlightuserdata(State, Self);
  lua_pushinteger(State, ACookie);

  lua_pushcclosure(State, @LuaWrapperFunction, 2);
  lua_setglobal(State, NilPAnsiChar(name));
end;


function TLua.GetRegisteredFunctionCookie: Integer;
begin
  Inc(FRegisteredFunctionCookie);
  Result := FRegisteredFunctionCookie;
end;


function TLua.RunRegisteredFunction(ACookie: Integer): Integer;
var
  context: ILuaContext;

begin
  Result := 0;

  if RegisteredFunctions.ContainsKey(ACookie) then
  begin
    context := TLuaContext.Create(State);

    RegisteredFunctions[ACookie].Callback(context);
    Result := context.Result.Count;
  end;
end;


function TLua.GetHasState: Boolean;
begin
  Result := Assigned(FState);
end;


function TLua.GetState: lua_State;
begin
  CheckState;
  Result := FState;
end;


function TLua.GetRegisteredFunctions: TLuaRegisteredFunctionDictionary;
begin
  if not Assigned(FRegisteredFunctions) then
    FRegisteredFunctions := TLuaRegisteredFunctionDictionary.Create;

  Result := FRegisteredFunctions;
end;


procedure TLua.SetAutoOpenLibraries(const Value: TLuaLibraries);
begin
  FAutoOpenLibraries := Value;
end;


{ TLuaParameters }
constructor TLuaParameters.Create(AState: lua_State);
begin
  inherited Create;

  FState := AState;
  FCount := lua_gettop(FState);
end;


function TLuaParameters.PushResultParameters: Integer;
begin
  Result := 0;
end;


function TLuaParameters.GetCount: Integer;
begin
  Result := FCount;
end;


function TLuaParameters.GetItem(Index: Integer): ILuaParameter;
begin
  Result := TLuaParameter.Create(State, Succ(Index));
end;


function TLuaParameters.GetState: lua_State;
begin
  Result := FState;
end;


function TLuaParameters.ToString: string;
var
  parameterIndex: Integer;

begin
  Result := '';

  for parameterIndex := 0 to Pred(GetCount) do
    Result := Result + GetItem(parameterIndex).AsString;
end;


{ TLuaParameter }
constructor TLuaParameter.Create(AState: lua_State; AIndex: Integer);
begin
  inherited Create;

  FState := AState;
  FIndex := AIndex;
end;


function TLuaParameter.GetAsBoolean: Boolean;
begin
  Result := (lua_toboolean(State, GetIndex) <> 0);
end;


function TLuaParameter.GetAsInteger: Integer;
begin
  Result := lua_tointeger(State, GetIndex);
end;


function TLuaParameter.GetAsNumber: Double;
begin
  Result := lua_tonumber(State, GetIndex);
end;


function TLuaParameter.GetAsUserData: Pointer;
begin
  Result := lua_touserdata(State, GetIndex);
end;


function TLuaParameter.GetAsString: string;
begin
  Result := string(lua_tostring(State, GetIndex));
end;


function TLuaParameter.GetDataType: TLuaDataType;
begin
  case lua_type(State, GetIndex) of
    LUA_TNIL: Result := LuaNil;
    LUA_TNUMBER: Result := LuaNumber;
    LUA_TBOOLEAN: Result := LuaBoolean;
    LUA_TSTRING: Result := LuaString;
    LUA_TTABLE: Result := LuaTable;
    LUA_TFUNCTION: Result := LuaCFunction;
    LUA_TUSERDATA: Result := LuaUserData;
    LUA_TTHREAD: Result := LuaThread;
    LUA_TLIGHTUSERDATA: Result := LuaLightUserData;
  else
    Result := LuaNone;
  end;
end;


function TLuaParameter.GetIndex: Integer;
begin
  Result := FIndex;
end;


{ TLuaContext }
constructor TLuaContext.Create(AState: lua_State);
begin
  inherited Create;

  FParameters := TLuaParameters.Create(AState);
  FResult := TLuaResult.Create(AState);
end;


function TLuaContext.GetParameters: ILuaParameters;
begin
  Result := FParameters;
end;


function TLuaContext.GetResult: ILuaResult;
begin
  Result := FResult;
end;


{ TLuaResult }
constructor TLuaResult.Create(AState: lua_State);
begin
  inherited Create;

  FState := AState;
end;


function TLuaResult.GetCount: Integer;
begin
  Result := FCount;
end;


procedure TLuaResult.Push(ABoolean: Boolean);
begin
  lua_pushboolean(State, IfThen(ABoolean, 1, 0));
  Pushed;
end;


procedure TLuaResult.Push(AInteger: Integer);
begin
  lua_pushinteger(State, AInteger);
  Pushed;
end;


procedure TLuaResult.Push(ANumber: Double);
begin
  lua_pushnumber(State, ANumber);
  Pushed;
end;


procedure TLuaResult.Push(AUserData: Pointer);
begin
  lua_pushlightuserdata(State, AUserData);
  Pushed;
end;


procedure TLuaResult.Push(const AString: string);
begin
  lua_pushstring(State, NilPAnsiChar(AString));
  Pushed;
end;


procedure TLuaResult.Pushed;
begin
  Inc(FCount);
end;


end.
