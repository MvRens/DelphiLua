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
  ELuaUnsupportedParameterException = class(ELuaException);

  TLuaLibrary = (Base, Coroutine, Table, IO, OS, StringLib, Bit32, Math, Debug, Package, All);
  TLuaLibraries = set of TLuaLibrary;

  TLuaDataType = (LuaNone, LuaNil, LuaNumber, LuaBoolean, LuaString, LuaTable,
                  LuaCFunction, LuaUserData, LuaThread, LuaLightUserData);

  TLuaParameterType = (ParameterNone, ParameterBoolean, ParameterInteger,
                       ParameterNumber, ParameterUserData, ParameterString,
                       ParameterTable);

  ILuaParameter = interface
    ['{ADA0D4FB-F0FB-4493-8FEC-6FC92C80117F}']
    function GetAsBoolean: Boolean;
    function GetAsInteger: Integer;
    function GetAsNumber: Double;
    function GetAsUserData: Pointer;
    function GetAsString: string;
    function GetParameterType: TLuaParameterType;
    function GetDataType: TLuaDataType;
    function GetIndex: Integer;

    property AsBoolean: Boolean read GetAsBoolean;
    property AsInteger: Integer read GetAsInteger;
    property AsNumber: Double read GetAsNumber;
    property AsUserData: Pointer read GetAsUserData;
    property AsString: string read GetAsString;
    property ParameterType: TLuaParameterType read GetParameterType;
    property DataType: TLuaDataType read GetDataType;

    property Index: Integer read GetIndex;
  end;


  ILuaParametersEnumerator = interface
    function GetCurrent: ILuaParameter;
    function MoveNext: Boolean;
    property Current: ILuaParameter read GetCurrent;
  end;


  ILuaParameters = interface
    ['{A62D7837-D07F-470C-9AF0-8051B57EFCB7}']
    function GetCount: Integer;

    property Count: Integer read GetCount;
  end;


  ILuaReadParameters = interface(ILuaParameters)
    ['{FB611D9E-B51D-460B-B5AB-B567EF853222}']
    function GetItem(Index: Integer): ILuaParameter;

    function GetEnumerator: ILuaParametersEnumerator;
    function ToString: string;

    property Items[Index: Integer]: ILuaParameter read GetItem; default;
  end;


  ILuaWriteParameters = interface(ILuaParameters)
    ['{5CEEB16B-158E-44BE-8CAD-DC2C330A244A}']
    procedure Push(ABoolean: Boolean); overload;
    procedure Push(AInteger: Integer); overload;
    procedure Push(ANumber: Double); overload;
    procedure Push(AUserData: Pointer); overload;
    procedure Push(const AString: string); overload;
  end;


  ILuaContext = interface
    ['{1F999593-E3D1-4195-9463-A42025AE9830}']
    function GetParameters: ILuaReadParameters;
    function GetResult: ILuaWriteParameters;

    property Parameters: ILuaReadParameters read GetParameters;
    property Result: ILuaWriteParameters read GetResult;
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
    FHasRun: Boolean;

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
    property HasRun: Boolean read FHasRun write FHasRun;
    property RegisteredFunctions: TLuaRegisteredFunctionDictionary read GetRegisteredFunctions;
  public
    constructor Create;
    destructor Destroy; override;

    procedure LoadFromString(const AData: string; const AChunkName: string = ''); virtual;
    procedure LoadFromStream(AStream: TStream; AOwnership: TStreamOwnership = soReference; const AChunkName: string = ''); virtual;

    procedure RegisterFunction(const AName: string; AFunction: TLuaFunction);

    procedure OpenLibraries(ALibraries: TLuaLibraries); virtual;
    procedure Run; virtual;
    function Call(const AFunctionName: string): ILuaReadParameters; overload; virtual;
    function Call(const AFunctionName: string; AParameters: array of const): ILuaReadParameters; overload; virtual;
    function Call(const AFunctionName: string; AParameters: ILuaReadParameters): ILuaReadParameters; overload; virtual;

    property HasState: Boolean read GetHasState;
    property State: lua_State read GetState;

    property AutoOpenLibraries: TLuaLibraries read FAutoOpenLibraries write SetAutoOpenLibraries default [TLuaLibrary.All];
  end;


  function GetLuaDataType(AType: Integer): TLuaDataType;
  function GetLuaParameterType(ADataType: TLuaDataType): TLuaParameterType;
  function CreateParameters(AParameters: array of const): ILuaReadParameters;


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


  TLuaParametersEnumerator = class(TInterfacedObject, ILuaParametersEnumerator)
  private
    FParameters: ILuaReadParameters;
    FIndex: Integer;
  protected
    property Parameters: ILuaReadParameters read FParameters;
  public
    constructor Create(AParameters: ILuaReadParameters);

    function GetCurrent: ILuaParameter;
    function MoveNext: Boolean;
  end;


  TCustomLuaParameters = class(TInterfacedObject, ILuaParameters, ILuaReadParameters)
  public
    { ILuaParameters }
    function GetCount: Integer; virtual; abstract;
    function GetItem(Index: Integer): ILuaParameter; virtual; abstract;

    function GetEnumerator: ILuaParametersEnumerator;
    function ToString: string; override;
  end;


  TLuaCFunctionParameters = class(TCustomLuaParameters)
  private
    FState: lua_State;
    FCount: Integer;
  protected
    property State: lua_State read FState;
  public
    constructor Create(AState: lua_State);

    { ILuaParameters }
    function GetCount: Integer; override;
    function GetItem(Index: Integer): ILuaParameter; override;
  end;


  TLuaCFunctionParameter = class(TInterfacedObject, ILuaParameter)
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
    function GetParameterType: TLuaParameterType;
    function GetIndex: Integer;
  end;


  TLuaResultParameters = class(TCustomLuaParameters)
  private
    FParameters: TList<ILuaParameter>;
  public
    constructor Create(AState: lua_State; ACount: Integer);
    destructor Destroy; override;

    function GetCount: Integer; override;
    function GetItem(Index: Integer): ILuaParameter; override;
  end;


  TCustomLuaParameter = class(TInterfacedObject, ILuaParameter)
  protected
    FIndex: Integer;
    FDataType: TLuaDataType;
    FParameterType: TLuaParameterType;
    FAsBoolean: Boolean;
    FAsInteger: Integer;
    FAsNumber: Double;
    FAsUserData: Pointer;
    FAsString: string;
  public
    { ILuaParameter }
    function GetAsBoolean: Boolean;
    function GetAsInteger: Integer;
    function GetAsNumber: Double;
    function GetAsUserData: Pointer;
    function GetAsString: string;
    function GetDataType: TLuaDataType;
    function GetParameterType: TLuaParameterType;
    function GetIndex: Integer;
  end;


  TLuaResultParameter = class(TCustomLuaParameter)
  public
    constructor Create(AState: lua_State; AIndex: Integer);
  end;


  TLuaReadWriteParameters = class(TCustomLuaParameters, ILuaWriteParameters)
  private
    FParameters: TList<ILuaParameter>;
  public
    constructor Create;
    destructor Destroy; override;

    function GetCount: Integer; override;
    function GetItem(Index: Integer): ILuaParameter; override;

    { ILuaWriteParameters }
    procedure Push(ABoolean: Boolean); overload;
    procedure Push(AInteger: Integer); overload;
    procedure Push(ANumber: Double); overload;
    procedure Push(AUserData: Pointer); overload;
    procedure Push(const AString: string); overload;
  end;


  TLuaReadWriteParameter = class(TCustomLuaParameter)
  public
    constructor Create(ABoolean: Boolean); overload;
    constructor Create(AInteger: Integer); overload;
    constructor Create(ANumber: Double); overload;
    constructor Create(AUserData: Pointer); overload;
    constructor Create(const AString: string); overload;
  end;


  TLuaWriteParameters = class(TInterfacedObject, ILuaParameters, ILuaWriteParameters)
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
    FParameters: ILuaReadParameters;
    FResult: ILuaWriteParameters;
  public
    constructor Create(AState: lua_State);

    { ILuaContext }
    function GetParameters: ILuaReadParameters;
    function GetResult: ILuaWriteParameters;
  end;



{ Helpers }
function GetLuaDataType(AType: Integer): TLuaDataType;
begin
  case AType of
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


function GetLuaParameterType(ADataType: TLuaDataType): TLuaParameterType;
begin
  case ADataType of
    LuaNumber:        Result := ParameterNumber;
    LuaBoolean:       Result := ParameterBoolean;
    LuaString:        Result := ParameterString;
    LuaTable:         Result := ParameterTable;
    LuaUserData:      Result := ParameterUserData;
    LuaLightUserData: Result := ParameterUserData;
  else
                      Result := ParameterNone;
  end;
end;


function CreateParameters(AParameters: array of const): ILuaReadParameters;
var
  parameterIndex: Integer;
  parameter: TVarRec;
  resultParameters: TLuaReadWriteParameters;

begin
  resultParameters := TLuaReadWriteParameters.Create;

  for parameterIndex := Low(AParameters) to High(AParameters) do
  begin
    parameter := AParameters[parameterIndex];
    case parameter.VType of
        vtInteger:        resultParameters.Push(parameter.VInteger);
        vtBoolean:        resultParameters.Push(parameter.VBoolean);
        vtChar:           resultParameters.Push(string(parameter.VChar));
        vtExtended:       resultParameters.Push(parameter.VExtended^);
        vtString:         resultParameters.Push(string(parameter.VString));
        vtPointer:        resultParameters.Push(parameter.VPointer);
        vtPChar:          resultParameters.Push(string(parameter.VPChar));
        vtObject:         resultParameters.Push(parameter.VObject);
        vtClass:          resultParameters.Push(parameter.VClass);
        vtWideChar:       resultParameters.Push(string(parameter.VWideChar));
        vtPWideChar:      resultParameters.Push(string(parameter.VPWideChar));
        vtAnsiString:     resultParameters.Push(string(PAnsiChar(parameter.VAnsiString)));
        vtCurrency:       resultParameters.Push(parameter.VCurrency^);
//        vtVariant:       resultParameters.Push(parameter.VVariant);
//        vtInterface:     resultParameters.Push(parameter.VInterface);
        vtWideString:     resultParameters.Push(string(PWideString(parameter.VWideString)));
        vtInt64:          resultParameters.Push(parameter.VInt64^);
        vtUnicodeString:  resultParameters.Push(string(PUnicodeString(parameter.VUnicodeString)));
    else
      raise ELuaUnsupportedParameterException.CreateFmt('Parameter type %d not supported (index: %d)', [parameter.VType, parameterIndex]);
    end;
  end;

  Result := resultParameters;
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


procedure TLua.Run;
begin
  if lua_pcall(State, 0, 0, 0) <> 0 then
    RaiseLastLuaError;

  HasRun := True;
end;


function TLua.Call(const AFunctionName: string): ILuaReadParameters;
begin
  Result := Call(AFunctionName, nil);
end;


function TLua.Call(const AFunctionName: string; AParameters: array of const): ILuaReadParameters;
begin
  Result := Call(AFunctionName, CreateParameters(AParameters));
end;


function TLua.Call(const AFunctionName: string; AParameters: ILuaReadParameters): ILuaReadParameters;
var
  stackIndex: Integer;
  parameterCount: Integer;
  parameter: ILuaParameter;
  parameterIndex: Integer;

begin
  { Global functions are only present after the has run once:
      http://lua-users.org/lists/lua-l/2011-01/msg01154.html }
  if not HasRun then
    Run;

  stackIndex := lua_gettop(State);

  lua_getglobal(State, PAnsiChar(AnsiString(AFunctionName)));

  parameterCount := 0;
  if Assigned(AParameters) then
  begin
    parameterCount := AParameters.Count;
    for parameterIndex := 0 to Pred(AParameters.Count) do
    begin
      parameter := AParameters[parameterIndex];
      case parameter.ParameterType of
        ParameterBoolean:   lua_pushboolean(State, IfThen(parameter.AsBoolean, 1, 0));
        ParameterInteger:   lua_pushinteger(State, parameter.AsInteger);
        ParameterNumber:    lua_pushnumber(State, parameter.AsNumber);
        ParameterUserData:  lua_pushlightuserdata(State, parameter.AsUserData);
        ParameterString:    lua_pushstring(State, PAnsiChar(AnsiString(parameter.AsString)));
      else
        raise ELuaUnsupportedParameterException.CreateFmt('Parameter type not supported: %d (index: %d)', [Ord(parameter.ParameterType), parameterIndex]);
      end;
    end;
  end;

  if lua_pcall(State, parameterCount, LUA_MULTRET, 0) <> 0 then
    RaiseLastLuaError;

  Result := TLuaResultParameters.Create(State, lua_gettop(State) - stackIndex);
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
  // TODO shouldn't we pop the error messag efrom the stack?
  raise ELuaException.Create(string(lua_tolstring(State, -1, nil)));
end;


procedure TLua.AfterLoad;
var
  cookie: Integer;

begin
  Loaded := True;
  HasRun := False;

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


{ TLuaParametersEnumerator }
constructor TLuaParametersEnumerator.Create(AParameters: ILuaReadParameters);
begin
  inherited Create;
  FParameters := AParameters;
  FIndex := -1;
end;

function TLuaParametersEnumerator.GetCurrent: ILuaParameter;
begin
  Result := Parameters.Items[FIndex];
end;


function TLuaParametersEnumerator.MoveNext: Boolean;
begin
  Inc(FIndex);
  Result := FIndex < Parameters.Count;
end;


{ TCustomLuaParameters }
function TCustomLuaParameters.GetEnumerator: ILuaParametersEnumerator;
begin
  Result := TLuaParametersEnumerator.Create(Self);
end;


function TCustomLuaParameters.ToString: string;
var
  parameterIndex: Integer;

begin
  Result := '';

  for parameterIndex := 0 to Pred(GetCount) do
    Result := Result + GetItem(parameterIndex).AsString;
end;


{ TLuaCFunctionParameters }
constructor TLuaCFunctionParameters.Create(AState: lua_State);
begin
  inherited Create;

  FState := AState;
  FCount := lua_gettop(State);
end;


function TLuaCFunctionParameters.GetCount: Integer;
begin
  Result := FCount;
end;


function TLuaCFunctionParameters.GetItem(Index: Integer): ILuaParameter;
begin
  Result := TLuaCFunctionParameter.Create(State, Succ(Index));
end;


{ TLuaCFunctionParameter }
constructor TLuaCFunctionParameter.Create(AState: lua_State; AIndex: Integer);
begin
  inherited Create;

  FState := AState;
  FIndex := AIndex;
end;


function TLuaCFunctionParameter.GetAsBoolean: Boolean;
begin
  Result := (lua_toboolean(State, GetIndex) <> 0);
end;


function TLuaCFunctionParameter.GetAsInteger: Integer;
begin
  Result := lua_tointeger(State, GetIndex);
end;


function TLuaCFunctionParameter.GetAsNumber: Double;
begin
  Result := lua_tonumber(State, GetIndex);
end;


function TLuaCFunctionParameter.GetAsUserData: Pointer;
begin
  Result := lua_touserdata(State, GetIndex);
end;


function TLuaCFunctionParameter.GetAsString: string;
begin
  Result := string(lua_tostring(State, GetIndex));
end;


function TLuaCFunctionParameter.GetDataType: TLuaDataType;
begin
  Result := GetLuaDataType(lua_type(State, GetIndex));
end;


function TLuaCFunctionParameter.GetIndex: Integer;
begin
  Result := FIndex;
end;


function TLuaCFunctionParameter.GetParameterType: TLuaParameterType;
begin
  Result := GetLuaParameterType(GetDataType);
end;


{ TLuaResultParameters }
constructor TLuaResultParameters.Create(AState: lua_State; ACount: Integer);
var
  parameterIndex: Integer;

begin
  inherited Create;

  FParameters := TList<ILuaParameter>.Create;

  if ACount > 0 then
  begin
    FParameters.Capacity := ACount;

    for parameterIndex := ACount downto 1 do
      FParameters.Add(TLuaResultParameter.Create(AState, -ACount));

    lua_pop(AState, ACount);
  end;
end;


destructor TLuaResultParameters.Destroy;
begin
  FreeAndNil(FParameters);

  inherited Destroy;
end;


function TLuaResultParameters.GetCount: Integer;
begin
  Result := FParameters.Count;
end;


function TLuaResultParameters.GetItem(Index: Integer): ILuaParameter;
begin
  Result := FParameters[Index];
end;


{ TCustomLuaParameter }
function TCustomLuaParameter.GetAsBoolean: Boolean;
begin
  Result := FAsBoolean;
end;


function TCustomLuaParameter.GetAsInteger: Integer;
begin
  Result := FAsInteger;
end;


function TCustomLuaParameter.GetAsNumber: Double;
begin
  Result := FAsNumber;
end;


function TCustomLuaParameter.GetAsUserData: Pointer;
begin
  Result := FAsUserData;
end;


function TCustomLuaParameter.GetAsString: string;
begin
  Result := FAsString;
end;


function TCustomLuaParameter.GetDataType: TLuaDataType;
begin
  Result := FDataType;
end;


function TCustomLuaParameter.GetParameterType: TLuaParameterType;
begin
  Result := FParameterType;
end;


function TCustomLuaParameter.GetIndex: Integer;
begin
  Result := FIndex;
end;


{ TLuaResultParameter }
constructor TLuaResultParameter.Create(AState: lua_State; AIndex: Integer);
begin
  inherited Create;

  FIndex := AIndex;
  FDataType := GetLuaDataType(lua_type(AState, AIndex));
  FParameterType := GetLuaParameterType(FDataType);
  FAsBoolean := (lua_toboolean(AState, AIndex) <> 0);
  FAsInteger := lua_tointeger(AState, AIndex);
  FAsNumber := lua_tonumber(AState, AIndex);
  FAsUserData := lua_touserdata(AState, AIndex);
  FAsString := string(lua_tostring(AState, AIndex));
end;


{ TLuaReadWriteParameters }
constructor TLuaReadWriteParameters.Create;
begin
  inherited Create;

  FParameters := TList<ILuaParameter>.Create;
end;


destructor TLuaReadWriteParameters.Destroy;
begin
  FreeAndNil(FParameters);

  inherited Destroy;
end;


function TLuaReadWriteParameters.GetCount: Integer;
begin
  Result := FParameters.Count;
end;


function TLuaReadWriteParameters.GetItem(Index: Integer): ILuaParameter;
begin
  Result := FParameters[Index];
end;


procedure TLuaReadWriteParameters.Push(ABoolean: Boolean);
begin
  FParameters.Add(TLuaReadWriteParameter.Create(ABoolean));
end;


procedure TLuaReadWriteParameters.Push(AInteger: Integer);
begin
  FParameters.Add(TLuaReadWriteParameter.Create(AInteger));
end;


procedure TLuaReadWriteParameters.Push(ANumber: Double);
begin
  FParameters.Add(TLuaReadWriteParameter.Create(ANumber));
end;


procedure TLuaReadWriteParameters.Push(AUserData: Pointer);
begin
  FParameters.Add(TLuaReadWriteParameter.Create(AUserData));
end;


procedure TLuaReadWriteParameters.Push(const AString: string);
begin
  FParameters.Add(TLuaReadWriteParameter.Create(AString));
end;


{ TLuaReadWriteParameter }
constructor TLuaReadWriteParameter.Create(ABoolean: Boolean);
begin
  FAsBoolean := ABoolean;
  FDataType := LuaBoolean;
  FParameterType := ParameterBoolean;
end;


constructor TLuaReadWriteParameter.Create(AInteger: Integer);
begin
  FAsInteger := AInteger;
  FDataType := LuaString;
  FParameterType := ParameterInteger;
end;


constructor TLuaReadWriteParameter.Create(ANumber: Double);
begin
  FAsNumber := ANumber;
  FDataType := LuaNumber;
  FParameterType := ParameterNumber;
end;


constructor TLuaReadWriteParameter.Create(AUserData: Pointer);
begin
  FAsUserData := AUserData;
  FDataType := LuaUserData;
  FParameterType := ParameterUserData;
end;


constructor TLuaReadWriteParameter.Create(const AString: string);
begin
  FAsString := AString;
  FDataType := LuaString;
  FParameterType := ParameterString;
end;


{ TLuaContext }
constructor TLuaContext.Create(AState: lua_State);
begin
  inherited Create;

  FParameters := TLuaCFunctionParameters.Create(AState);
  FResult := TLuaWriteParameters.Create(AState);
end;


function TLuaContext.GetParameters: ILuaReadParameters;
begin
  Result := FParameters;
end;


function TLuaContext.GetResult: ILuaWriteParameters;
begin
  Result := FResult;
end;


{ TLuaResult }
constructor TLuaWriteParameters.Create(AState: lua_State);
begin
  inherited Create;

  FState := AState;
end;


function TLuaWriteParameters.GetCount: Integer;
begin
  Result := FCount;
end;


procedure TLuaWriteParameters.Push(ABoolean: Boolean);
begin
  lua_pushboolean(State, IfThen(ABoolean, 1, 0));
  Pushed;
end;


procedure TLuaWriteParameters.Push(AInteger: Integer);
begin
  lua_pushinteger(State, AInteger);
  Pushed;
end;


procedure TLuaWriteParameters.Push(ANumber: Double);
begin
  lua_pushnumber(State, ANumber);
  Pushed;
end;


procedure TLuaWriteParameters.Push(AUserData: Pointer);
begin
  lua_pushlightuserdata(State, AUserData);
  Pushed;
end;


procedure TLuaWriteParameters.Push(const AString: string);
begin
  lua_pushstring(State, NilPAnsiChar(AString));
  Pushed;
end;


procedure TLuaWriteParameters.Pushed;
begin
  Inc(FCount);
end;

end.
