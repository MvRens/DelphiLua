unit Lua.Wrapper;

interface
uses
  System.Classes,
  System.Generics.Collections,
  System.Generics.Defaults,
  System.SysUtils,

  Lua;

type
  ELuaException = class(Exception);
  ELuaInitException = class(ELuaException);
  ELuaUnsupportedParameterException = class(ELuaException);
  ELuaUnsupportedVariableException = class(ELuaException);

  TLuaLibrary = (Base, Coroutine, Table, IO, OS, StringLib, Bit32, Math, Debug, Package, All);
  TLuaLibraries = set of TLuaLibrary;

  TLuaDataType = (LuaNone, LuaNil, LuaNumber, LuaBoolean, LuaString, LuaTable,
                  LuaCFunction, LuaUserData, LuaThread, LuaLightUserData);

  TLuaVariableType = (VariableNone, VariableBoolean, VariableInteger,
                      VariableNumber, VariableUserData, VariableString,
                      VariableTable);

  ILuaTable = interface;


  ILuaVariable = interface
    ['{ADA0D4FB-F0FB-4493-8FEC-6FC92C80117F}']
    function GetVariableType: TLuaVariableType;
    function GetDataType: TLuaDataType;

    function GetAsBoolean: Boolean;
    function GetAsInteger: Integer;
    function GetAsNumber: Double;
    function GetAsUserData: Pointer;
    function GetAsString: string;
    function GetAsTable: ILuaTable;

    procedure SetAsBoolean(ABoolean: Boolean);
    procedure SetAsInteger(AInteger: Integer);
    procedure SetAsNumber(ANumber: Double);
    procedure SetAsUserData(AUserData: Pointer);
    procedure SetAsString(AString: string);
    procedure SetAsTable(ATable: ILuaTable);


    property VariableType: TLuaVariableType read GetVariableType;
    property DataType: TLuaDataType read GetDataType;

    property AsBoolean: Boolean read GetAsBoolean write SetAsBoolean;
    property AsInteger: Integer read GetAsInteger write SetAsInteger;
    property AsNumber: Double read GetAsNumber write SetAsNumber;
    property AsUserData: Pointer read GetAsUserData write SetAsUserData;
    property AsString: string read GetAsString write SetAsString;
    property AsTable: ILuaTable read GetAsTable write SetAsTable;
  end;


  TLuaImplicitVariable = record
    Variable: ILuaVariable;

    class operator Implicit(AValue: ILuaVariable): TLuaImplicitVariable;
    class operator Implicit(AValue: Boolean): TLuaImplicitVariable;
    class operator Implicit(AValue: Integer): TLuaImplicitVariable;
    class operator Implicit(AValue: Double): TLuaImplicitVariable;
    class operator Implicit(AValue: Pointer): TLuaImplicitVariable;
    class operator Implicit(const AValue: string): TLuaImplicitVariable;
    class operator Implicit(AValue: ILuaTable): TLuaImplicitVariable;
    class operator Implicit(AValue: TLuaImplicitVariable): ILuaVariable;
    class operator Implicit(AValue: TLuaImplicitVariable): Boolean;
    class operator Implicit(AValue: TLuaImplicitVariable): Integer;
    class operator Implicit(AValue: TLuaImplicitVariable): Double;
    class operator Implicit(AValue: TLuaImplicitVariable): Pointer;
    class operator Implicit(AValue: TLuaImplicitVariable): string;
    class operator Implicit(AValue: TLuaImplicitVariable): ILuaTable;
  end;


  TLuaKeyValuePair = record
    Key: ILuaVariable;
    Value: ILuaVariable;
  end;


  ILuaTableEnumerator = interface
    ['{4C3F4E20-F9E7-42E6-9446-78C535AF2E30}']
    function GetCurrent: TLuaKeyValuePair;
    function MoveNext: Boolean;

    property Current: TLuaKeyValuePair read GetCurrent;
  end;


  ILuaTable = interface
    ['{57FD52A1-7D53-485B-A630-29841C498387}']
    function GetEnumerator: ILuaTableEnumerator;

    function GetValue(AKey: TLuaImplicitVariable): ILuaVariable;
    procedure SetValue(AKey: TLuaImplicitVariable; AValue: TLuaImplicitVariable);
  end;


  TLuaTableEnumerator = class(TInterfacedObject, ILuaTableEnumerator)
  private
    FEnumerator: TEnumerator<TPair<ILuaVariable, ILuaVariable>>;
  public
    constructor Create(AEnumerator: TEnumerator<TPair<ILuaVariable, ILuaVariable>>);
    destructor Destroy; override;

    { ILuaTableEnumerator }
    function GetCurrent: TLuaKeyValuePair;
    function MoveNext: Boolean;

    property Current: TLuaKeyValuePair read GetCurrent;
  end;


  TLuaVariableEqualityComparer = class(TInterfacedObject, IEqualityComparer<ILuaVariable>)
  public
    { IEqualityComparer<ILuaVariable> }
    function Equals(const Left, Right: ILuaVariable): Boolean; reintroduce;
    function GetHashCode(const Value: ILuaVariable): Integer; reintroduce;
  end;


  TLuaTable = class(TInterfacedObject, ILuaTable)
  private
    FTable: TDictionary<ILuaVariable, ILuaVariable>;
  public
    constructor Create;
    destructor Destroy; override;

    { ILuaTable }
    function GetEnumerator: ILuaTableEnumerator;

    function GetValue(AKey: TLuaImplicitVariable): ILuaVariable;
    procedure SetValue(AKey: TLuaImplicitVariable; AValue: TLuaImplicitVariable);
  end;


  ILuaParametersEnumerator = interface
    function GetCurrent: ILuaVariable;
    function MoveNext: Boolean;
    property Current: ILuaVariable read GetCurrent;
  end;


  ILuaParameters = interface
    ['{A62D7837-D07F-470C-9AF0-8051B57EFCB7}']
    function GetCount: Integer;

    property Count: Integer read GetCount;
  end;


  ILuaReadParameters = interface(ILuaParameters)
    ['{FB611D9E-B51D-460B-B5AB-B567EF853222}']
    function GetItem(Index: Integer): ILuaVariable;

    function GetEnumerator: ILuaParametersEnumerator;
    function ToString: string;

    property Items[Index: Integer]: ILuaVariable read GetItem; default;
  end;


  ILuaWriteParameters = interface(ILuaParameters)
    ['{5CEEB16B-158E-44BE-8CAD-DC2C330A244A}']
    procedure Push(ABoolean: Boolean); overload;
    procedure Push(AInteger: Integer); overload;
    procedure Push(ANumber: Double); overload;
    procedure Push(AUserData: Pointer); overload;
    procedure Push(const AString: string); overload;
    procedure Push(ATable: ILuaTable); overload;
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


  TLuaScript = class(TObject)
  private
    FStream: TStream;
    FStreamOwnership: TStreamOwnership;
    FBuffer: PAnsiChar;
  public
    constructor Create(const AData: string); overload;
    constructor Create(const AStream: TStream; AOwnership: TStreamOwnership = soReference); overload;
    destructor Destroy; override;

    function GetNextChunk(out ASize: Cardinal): PAnsiChar; virtual;
  end;


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

    procedure LoadFromString(const AData: string; AAutoRun: Boolean = True; const AChunkName: string = ''); virtual;
    procedure LoadFromStream(AStream: TStream; AOwnership: TStreamOwnership = soReference; AAutoRun: Boolean = True; const AChunkName: string = ''); virtual;
    procedure LoadFromFile(const AFileName: string; AAutoRun: Boolean = True; const AChunkName: string = ''); virtual;
    procedure LoadFromScript(AScript: TLuaScript; AOwnership: TStreamOwnership = soReference; AAutoRun: Boolean = True; const AChunkName: string = ''); virtual;

    function GetGlobalVariable(const AName: string): ILuaVariable;
    procedure SetGlobalVariable(const AName: string; AVariable: TLuaImplicitVariable);
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
  function GetLuaVariableType(ADataType: TLuaDataType): TLuaVariableType;
  function CreateParameters(AParameters: array of const): ILuaReadParameters;
  procedure PushVariable(AState: lua_State; AVariable: ILuaVariable); overload;
  procedure PushVariable(AState: lua_State; AVariable: ILuaVariable; AVariableType: TLuaVariableType); overload;
  procedure PushTable(AState: lua_State; ATable: ILuaTable);

  function AllocLuaString(const AValue: string): PAnsiChar;
  procedure FreeLuaString(AValue: PAnsiChar);

  function LuaToString(AState: lua_State; AIndex: Integer): string;


implementation
uses
  System.Math;


type
  PLuaScript = ^TLuaScript;

  TLuaParametersEnumerator = class(TInterfacedObject, ILuaParametersEnumerator)
  private
    FParameters: ILuaReadParameters;
    FIndex: Integer;
  protected
    property Parameters: ILuaReadParameters read FParameters;
  public
    constructor Create(AParameters: ILuaReadParameters);

    function GetCurrent: ILuaVariable;
    function MoveNext: Boolean;
  end;


  TCustomLuaParameters = class(TInterfacedObject, ILuaParameters, ILuaReadParameters)
  public
    { ILuaParameters }
    function GetCount: Integer; virtual; abstract;
    function GetItem(Index: Integer): ILuaVariable; virtual; abstract;

    function GetEnumerator: ILuaParametersEnumerator;
    function ToString: string; override;
  end;


  TLuaStackParameters = class(TCustomLuaParameters)
  private
    FState: lua_State;
    FCount: Integer;
  protected
    property State: lua_State read FState;
  public
    constructor Create(AState: lua_State; ACount: Integer = -1);

    { ILuaParameters }
    function GetCount: Integer; override;
    function GetItem(Index: Integer): ILuaVariable; override;
  end;


  TLuaStackVariable = class(TInterfacedObject, ILuaVariable)
  private
    FState: lua_State;
    FIndex: Integer;
    FTable: ILuaTable;
  protected
    property State: lua_State read FState;
    property Index: Integer read FIndex;
  public
    constructor Create(AState: lua_State; AIndex: Integer);

    { ILuaVariable }
    function GetDataType: TLuaDataType;
    function GetVariableType: TLuaVariableType;

    function GetAsBoolean: Boolean;
    function GetAsInteger: Integer;
    function GetAsNumber: Double;
    function GetAsUserData: Pointer;
    function GetAsString: string;
    function GetAsTable: ILuaTable;

    procedure SetAsBoolean(ABoolean: Boolean);
    procedure SetAsInteger(AInteger: Integer);
    procedure SetAsNumber(ANumber: Double);
    procedure SetAsUserData(AUserData: Pointer);
    procedure SetAsString(AString: string);
    procedure SetAsTable(ATable: ILuaTable);
  end;


  TLuaResultParameters = class(TCustomLuaParameters)
  private
    FParameters: TList<ILuaVariable>;
  public
    constructor Create(AState: lua_State; ACount: Integer);
    destructor Destroy; override;

    function GetCount: Integer; override;
    function GetItem(Index: Integer): ILuaVariable; override;
  end;


  TLuaVariable = class(TInterfacedObject, ILuaVariable)
  private
    FVariableType: TLuaVariableType;
    FDataType: TLuaDataType;
    FBooleanValue: Boolean;
    FIntegerValue: Integer;
    FNumberValue: Double;
    FUserDataValue: Pointer;
    FStringValue: string;
    FTableValue: ILuaTable;
  protected
    property VariableType: TLuaVariableType read FVariableType write FVariableType;
    property DataType: TLuaDataType read FDataType write FDataType;
    property BooleanValue: Boolean read FBooleanValue write FBooleanValue;
    property IntegerValue: Integer read FIntegerValue write FIntegerValue;
    property NumberValue: Double read FNumberValue write FNumberValue;
    property UserDataValue: Pointer read FUserDataValue write FUserDataValue;
    property StringValue: string read FStringValue write FStringValue;
    property TableValue: ILuaTable read FTableValue write FTableValue;
  public
    constructor Create; overload;
    constructor Create(ABoolean: Boolean); overload;
    constructor Create(AInteger: Integer); overload;
    constructor Create(ANumber: Double); overload;
    constructor Create(AUserData: Pointer); overload;
    constructor Create(const AString: string); overload;
    constructor Create(ATable: ILuaTable); overload;

    { ILuaParameter }
    function GetVariableType: TLuaVariableType;
    function GetDataType: TLuaDataType;

    function GetAsBoolean: Boolean;
    function GetAsInteger: Integer;
    function GetAsNumber: Double;
    function GetAsUserData: Pointer;
    function GetAsString: string;
    function GetAsTable: ILuaTable;

    procedure SetAsBoolean(ABoolean: Boolean);
    procedure SetAsInteger(AInteger: Integer);
    procedure SetAsNumber(ANumber: Double);
    procedure SetAsUserData(AUserData: Pointer);
    procedure SetAsString(AString: string);
    procedure SetAsTable(ATable: ILuaTable);
  end;


  TLuaCachedVariable = class(TLuaVariable)
  public
    constructor Create(AState: lua_State; AIndex: Integer);
  end;


  TLuaCachedTable = class(TLuaTable)
  public
    constructor Create(AState: lua_State; AIndex: Integer);
  end;


  TLuaReadWriteParameters = class(TCustomLuaParameters, ILuaWriteParameters)
  private
    FParameters: TList<ILuaVariable>;
  public
    constructor Create;
    destructor Destroy; override;

    function GetCount: Integer; override;
    function GetItem(Index: Integer): ILuaVariable; override;

    { ILuaWriteParameters }
    procedure Push(ABoolean: Boolean); overload;
    procedure Push(AInteger: Integer); overload;
    procedure Push(ANumber: Double); overload;
    procedure Push(AUserData: Pointer); overload;
    procedure Push(const AString: string); overload;
    procedure Push(ATable: ILuaTable); overload;
  end;


  TLuaStackWriteParameters = class(TInterfacedObject, ILuaParameters, ILuaWriteParameters)
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
    procedure Push(ATable: ILuaTable); overload;
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
// Casting strings directly to PAnsiChar (via AnsiString) causes corruption
// with table values, at least in Delphi XE2. Can't really explain why, seems
// the input string goes out of scope, so let's just go through the motions
// to create a copy and be safe.
function AllocLuaString(const AValue: string): PAnsiChar;
begin
  if Length(AValue) > 0 then
  begin
    GetMem(Result, Length(AValue) + 1);
    StrPCopy(Result, AnsiString(AValue));
  end else
    Result := nil;
end;


procedure FreeLuaString(AValue: PAnsiChar);
begin
  FreeMem(AValue);
end;

// If someone cares to reproduce this issue and optimize the code, use these
// two and the TableLuaFunction test should fail with a corrupted value
// (#11#0#0#0#11#0#0#0#11#0#0#0#11#0#0#0#11).
(*
function AllocLuaString(const AValue: string): PAnsiChar;
begin
  if Length(AValue) > 0 then
    Result := PAnsiChar(AnsiString(AValue))
  else
    Result := nil;
end;

procedure FreeLuaString(AValue: PAnsiChar);
begin
end;
*)


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


function GetLuaVariableType(ADataType: TLuaDataType): TLuaVariableType;
begin
  case ADataType of
    LuaNumber:        Result := VariableNumber;
    LuaBoolean:       Result := VariableBoolean;
    LuaString:        Result := VariableString;
    LuaTable:         Result := VariableTable;
    LuaUserData:      Result := VariableUserData;
    LuaLightUserData: Result := VariableUserData;
  else
                      Result := VariableNone;
  end;
end;


function CreateParameters(AParameters: array of const): ILuaReadParameters;
var
  parameterIndex: Integer;
  parameter: TVarRec;
  resultParameters: TLuaReadWriteParameters;
  table: ILuaTable;

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
        vtObject:
          if parameter.VObject is TLuaTable then
            resultParameters.Push(TLuaTable(parameter.VObject));

        vtWideChar:       resultParameters.Push(string(parameter.VWideChar));
        vtPWideChar:      resultParameters.Push(string(parameter.VPWideChar));
        vtAnsiString:     resultParameters.Push(string(PAnsiChar(parameter.VAnsiString)));
        vtCurrency:       resultParameters.Push(parameter.VCurrency^);
//        vtVariant:       resultParameters.Push(parameter.VVariant);
        vtInterface:
          if Supports(IInterface(parameter.VInterface), ILuaTable, table) then
            resultParameters.Push(table);

        vtWideString:     resultParameters.Push(string(PWideString(parameter.VWideString)));
        vtInt64:          resultParameters.Push(parameter.VInt64^);
        vtUnicodeString:  resultParameters.Push(string(PUnicodeString(parameter.VUnicodeString)));
    else
      raise ELuaUnsupportedParameterException.CreateFmt('Parameter type %d not supported (index: %d)', [parameter.VType, parameterIndex]);
    end;
  end;

  Result := resultParameters;
end;


procedure PushVariable(AState: lua_State; AVariable: ILuaVariable);
begin
  PushVariable(AState, AVariable, AVariable.VariableType);
end;


procedure PushVariable(AState: lua_State; AVariable: ILuaVariable; AVariableType: TLuaVariableType);
var
  stringValue: PAnsiChar;

begin
  case AVariableType of
    VariableNone:     lua_pushnil(AState);
    VariableBoolean:  lua_pushboolean(AState, IfThen(AVariable.AsBoolean, 1, 0));
    VariableInteger:  lua_pushinteger(AState, AVariable.AsInteger);
    VariableNumber:   lua_pushnumber(AState, AVariable.AsNumber);
    VariableUserData: lua_pushlightuserdata(AState, AVariable.AsUserData);
    VariableString:
      begin
        stringValue := AllocLuaString(AVariable.AsString);
        try
          lua_pushlstring(AState, stringValue, Length(AVariable.AsString));
        finally
          FreeLuaString(stringValue);
        end;
      end;
    VariableTable:    PushTable(AState, AVariable.AsTable);
  else
    raise ELuaUnsupportedVariableException.CreateFmt('Variable type not supported: %d', [Ord(AVariableType)]);
  end;
end;


procedure PushTable(AState: lua_State; ATable: ILuaTable);
var
  pair: TLuaKeyValuePair;

begin
  lua_newtable(AState);

  for pair in ATable do
  begin
    PushVariable(AState, pair.Key);
    PushVariable(AState, pair.Value);
    lua_settable(AState, -3);
  end;
end;


function LuaToString(AState: lua_State; AIndex: Integer): string;
var
  len: Cardinal;
  value: PAnsiChar;
  stringValue: RawByteString;

begin
  value := lua_tolstring(AState, AIndex, @len);
  SetString(stringValue, value, len);

  Result := string(stringValue);
end;


{ TLuaImplicitVariable }
class operator TLuaImplicitVariable.Implicit(AValue: ILuaVariable): TLuaImplicitVariable;
begin
  Result.Variable := AValue;
end;


class operator TLuaImplicitVariable.Implicit(AValue: Boolean): TLuaImplicitVariable;
begin
  Result.Variable := TLuaVariable.Create(AValue);
end;


class operator TLuaImplicitVariable.Implicit(AValue: Integer): TLuaImplicitVariable;
begin
  Result.Variable := TLuaVariable.Create(AValue);
end;


class operator TLuaImplicitVariable.Implicit(AValue: Double): TLuaImplicitVariable;
begin
  Result.Variable := TLuaVariable.Create(AValue);
end;


class operator TLuaImplicitVariable.Implicit(AValue: Pointer): TLuaImplicitVariable;
begin
  Result.Variable := TLuaVariable.Create(AValue);
end;


class operator TLuaImplicitVariable.Implicit(const AValue: string): TLuaImplicitVariable;
begin
  Result.Variable := TLuaVariable.Create(AValue);
end;


class operator TLuaImplicitVariable.Implicit(AValue: ILuaTable): TLuaImplicitVariable;
begin
  Result.Variable := TLuaVariable.Create(AValue);
end;


class operator TLuaImplicitVariable.Implicit(AValue: TLuaImplicitVariable): ILuaVariable;
begin
  Result := AValue.Variable;
end;


class operator TLuaImplicitVariable.Implicit(AValue: TLuaImplicitVariable): Boolean;
begin
  Result := AValue.Variable.AsBoolean;
end;


class operator TLuaImplicitVariable.Implicit(AValue: TLuaImplicitVariable): Integer;
begin
  Result := AValue.Variable.AsInteger;
end;


class operator TLuaImplicitVariable.Implicit(AValue: TLuaImplicitVariable): Double;
begin
  Result := AValue.Variable.AsNumber;
end;


class operator TLuaImplicitVariable.Implicit(AValue: TLuaImplicitVariable): Pointer;
begin
  Result := AValue.Variable.AsUserData;
end;


class operator TLuaImplicitVariable.Implicit(AValue: TLuaImplicitVariable): string;
begin
  Result := AValue.Variable.AsString;
end;


class operator TLuaImplicitVariable.Implicit(AValue: TLuaImplicitVariable): ILuaTable;
begin
  Result := AValue.Variable.AsTable;
end;


{ TLuaTableEnumerator }
constructor TLuaTableEnumerator.Create(AEnumerator: TEnumerator<TPair<ILuaVariable, ILuaVariable>>);
begin
  inherited Create;

  FEnumerator := AEnumerator;
end;


destructor TLuaTableEnumerator.Destroy;
begin
  FreeAndNil(FEnumerator);

  inherited Destroy;
end;


function TLuaTableEnumerator.GetCurrent: TLuaKeyValuePair;
var
  current: TPair<ILuaVariable, ILuaVariable>;

begin
  current := FEnumerator.Current;

  Result.Key := current.Key;
  Result.Value := current.Value;
end;


function TLuaTableEnumerator.MoveNext: Boolean;
begin
  Result := FEnumerator.MoveNext;
end;


{ TLuaVariableEqualityComparer }
function TLuaVariableEqualityComparer.Equals(const Left, Right: ILuaVariable): Boolean;
begin
  Result := (Left.VariableType = Right.VariableType);
  if Result then
  begin
    case Left.VariableType of
      VariableBoolean:  Result := (Left.AsBoolean = Right.AsBoolean);
      VariableInteger:  Result := (Left.AsInteger = Right.AsInteger);
      VariableNumber:   Result := SameValue(Left.AsNumber, Right.AsNumber);
      VariableUserData: Result := (Left.AsUserData = Right.AsUserData);
      VariableString:   Result := (Left.AsString = Right.AsString);
      VariableTable:    Result := (Left.AsTable = Right.AsTable);
    end;
  end;
end;

function TLuaVariableEqualityComparer.GetHashCode(const Value: ILuaVariable): Integer;
var
  i: Integer;
  m: Extended;
  e: Integer;
  p: Pointer;
  s: string;

begin
  Result := 0;

  // System.Generics.Defaults has a decent set of GetHashCode_ functions...
  // ...which are of course private.
  case Value.VariableType of
    VariableBoolean:
      Result := Ord(Value.AsBoolean);
    VariableInteger:
      begin
        i := Value.AsInteger;
        Result := BobJenkinsHash(i, SizeOf(i), 0);
      end;
    VariableNumber:
      begin
        // Denormalized floats and positive/negative 0.0 complicate things.
        Frexp(Value.AsNumber, m, e);
        if m = 0 then
          m := Abs(m);
        Result := BobJenkinsHash(m, SizeOf(m), 0);
        Result := BobJenkinsHash(e, SizeOf(e), Result);
      end;
    VariableUserData:
      begin
        p := Value.AsUserData;
        Result := BobJenkinsHash(p, SizeOf(p), 0);
      end;
    VariableString:
      begin
        s := Value.AsString;
        if Length(s) > 0 then
          Result := BobJenkinsHash(s[1], Length(s) * SizeOf(s[1]), 0);
      end;
    VariableTable:
      Result := Integer(Value.AsTable);
  end;
end;


{ TLuaTable }
constructor TLuaTable.Create;
begin
  inherited Create;

  FTable := TDictionary<ILuaVariable, ILuaVariable>.Create(TLuaVariableEqualityComparer.Create);
end;


destructor TLuaTable.Destroy;
begin
  FreeAndNil(FTable);

  inherited Destroy;
end;


function TLuaTable.GetEnumerator: ILuaTableEnumerator;
begin
  Result := TLuaTableEnumerator.Create(FTable.GetEnumerator);
end;


function TLuaTable.GetValue(AKey: TLuaImplicitVariable): ILuaVariable;
begin
  Result := FTable[AKey];
end;


procedure TLuaTable.SetValue(AKey, AValue: TLuaImplicitVariable);
begin
  FTable.AddOrSetValue(AKey, AValue);
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


procedure TLua.LoadFromString(const AData: string; AAutoRun: Boolean; const AChunkName: string);
begin
  LoadFromScript(TLuaScript.Create(AData), soOwned, AAutoRun, AChunkName);
end;


procedure TLua.LoadFromStream(AStream: TStream; AOwnership: TStreamOwnership; AAutoRun: Boolean; const AChunkName: string);
begin
  LoadFromScript(TLuaScript.Create(AStream, AOwnership), soOwned, AAutoRun, AChunkName);
end;


procedure TLua.LoadFromFile(const AFileName: string; AAutoRun: Boolean; const AChunkName: string);
begin
  LoadFromScript(TLuaScript.Create(TFileStream.Create(AFileName, fmOpenRead or fmShareDenyNone), soOwned), soOwned, AAutoRun, AChunkName);
end;


procedure TLua.LoadFromScript(AScript: TLuaScript; AOwnership: TStreamOwnership; AAutoRun: Boolean; const AChunkName: string);
var
  chunkName: PAnsiChar;

begin
  try
    chunkName := AllocLuaString(AChunkName);
    try
      if lua_load(State, LuaWrapperReader, @AScript, chunkName, nil) <> 0 then
        RaiseLastLuaError;
    finally
      FreeLuaString(chunkName);
    end;

    if not Loaded then
      AfterLoad;

    if AAutoRun then
      Run;
  finally
    if AOwnership = soOwned then
      FreeAndNil(AScript);
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
  parameter: ILuaVariable;
  functionName: PAnsiChar;

begin
  { Global functions are only present after the has run once:
      http://lua-users.org/lists/lua-l/2011-01/msg01154.html }
  if not HasRun then
    Run;

  stackIndex := lua_gettop(State);

  functionName := AllocLuaString(AFunctionName);
  try
    lua_getglobal(State, functionName);
  finally
    FreeLuaString(functionName);
  end;

  parameterCount := 0;
  if Assigned(AParameters) then
  begin
    parameterCount := AParameters.Count;
    for parameter in AParameters do
      PushVariable(State, parameter);
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
var
  errorMessage: string;

begin
  errorMessage := LuaToString(State, -1);
  lua_pop(State, 1);

  raise ELuaException.Create(errorMessage);
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


function TLua.GetGlobalVariable(const AName: string): ILuaVariable;
var
  name: PAnsiChar;

begin
  name := AllocLuaString(AName);
  try
    lua_getglobal(State, name);

    Result := TLuaCachedVariable.Create(State, -1);
    lua_pop(State, 1);
  finally
    FreeLuaString(name);
  end;
end;


procedure TLua.SetGlobalVariable(const AName: string; AVariable: TLuaImplicitVariable);
var
  name: PAnsiChar;

begin
  name := AllocLuaString(AName);
  try
    PushVariable(State, AVariable);
    lua_setglobal(State, name);
  finally
    FreeLuaString(name);
  end;
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
  name: PAnsiChar;

begin
  name := AllocLuaString(RegisteredFunctions[ACookie].Name);
  try
    lua_pushlightuserdata(State, Self);
    lua_pushinteger(State, ACookie);

    lua_pushcclosure(State, @LuaWrapperFunction, 2);
    lua_setglobal(State, name);
  finally
    FreeLuaString(name);
  end;
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

function TLuaParametersEnumerator.GetCurrent: ILuaVariable;
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
constructor TLuaStackParameters.Create(AState: lua_State; ACount: Integer);
begin
  inherited Create;

  FState := AState;
  FCount := ACount;

  if FCount = -1 then
    FCount := lua_gettop(State);
end;


function TLuaStackParameters.GetCount: Integer;
begin
  Result := FCount;
end;


function TLuaStackParameters.GetItem(Index: Integer): ILuaVariable;
begin
  if (Index < 0) or (Index >= GetCount) then
    raise ERangeError.CreateFmt('Invalid parameter index: %d', [Index]);

  Result := TLuaStackVariable.Create(State, Succ(Index));
end;


{ TLuaCFunctionParameter }
constructor TLuaStackVariable.Create(AState: lua_State; AIndex: Integer);
begin
  inherited Create;

  FState := AState;
  FIndex := AIndex;
end;


function TLuaStackVariable.GetVariableType: TLuaVariableType;
begin
  Result := GetLuaVariableType(GetDataType);
end;


function TLuaStackVariable.GetDataType: TLuaDataType;
begin
  Result := GetLuaDataType(lua_type(State, Index));
end;


function TLuaStackVariable.GetAsBoolean: Boolean;
begin
  Result := (lua_toboolean(State, Index) <> 0);
end;


function TLuaStackVariable.GetAsInteger: Integer;
begin
  Result := lua_tointeger(State, Index);
end;


function TLuaStackVariable.GetAsNumber: Double;
begin
  Result := lua_tonumber(State, Index);
end;


function TLuaStackVariable.GetAsUserData: Pointer;
begin
  Result := lua_touserdata(State, Index);
end;


function TLuaStackVariable.GetAsString: string;
begin
  Result := LuaToString(State, Index);
end;


function TLuaStackVariable.GetAsTable: ILuaTable;
begin
  if not lua_istable(State, Index) then
    Result := nil;

  if not Assigned(FTable) then
    FTable := TLuaCachedTable.Create(State, Index);

  Result := FTable;
end;


procedure TLuaStackVariable.SetAsBoolean(ABoolean: Boolean);
begin
  lua_pushboolean(State, IfThen(ABoolean, 1, 0));
  lua_replace(State, Index);
end;


procedure TLuaStackVariable.SetAsInteger(AInteger: Integer);
begin
  PushVariable(State, Self, VariableInteger);
  lua_replace(State, Index);
end;


procedure TLuaStackVariable.SetAsNumber(ANumber: Double);
begin
  PushVariable(State, Self, VariableNumber);
  lua_replace(State, Index);
end;


procedure TLuaStackVariable.SetAsString(AString: string);
begin
  PushVariable(State, Self, VariableString);
  lua_replace(State, Index);
end;


procedure TLuaStackVariable.SetAsTable(ATable: ILuaTable);
begin
  PushVariable(State, Self, VariableTable);
  lua_replace(State, Index);
end;


procedure TLuaStackVariable.SetAsUserData(AUserData: Pointer);
begin
  PushVariable(State, Self, VariableUserData);
  lua_replace(State, Index);
end;


{ TLuaResultParameters }
constructor TLuaResultParameters.Create(AState: lua_State; ACount: Integer);
var
  parameterIndex: Integer;

begin
  inherited Create;

  FParameters := TList<ILuaVariable>.Create;

  if ACount > 0 then
  begin
    FParameters.Capacity := ACount;

    for parameterIndex := ACount downto 1 do
      FParameters.Add(TLuaCachedVariable.Create(AState, -ACount));

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


function TLuaResultParameters.GetItem(Index: Integer): ILuaVariable;
begin
  Result := FParameters[Index];
end;


{ TLuaVariable }
constructor TLuaVariable.Create;
begin
end;


constructor TLuaVariable.Create(ABoolean: Boolean);
begin
  Create;
  SetAsBoolean(ABoolean);
end;


constructor TLuaVariable.Create(AInteger: Integer);
begin
  Create;
  SetAsInteger(AInteger);
end;


constructor TLuaVariable.Create(ANumber: Double);
begin
  Create;
  SetAsNumber(ANumber);
end;


constructor TLuaVariable.Create(AUserData: Pointer);
begin
  Create;
  SetAsUserData(AUserData);
end;


constructor TLuaVariable.Create(const AString: string);
begin
  Create;
  SetAsString(AString);
end;


constructor TLuaVariable.Create(ATable: ILuaTable);
begin
  Create;
  SetAsTable(ATable);
end;


function TLuaVariable.GetVariableType: TLuaVariableType;
begin
  Result := VariableType;
end;


function TLuaVariable.GetDataType: TLuaDataType;
begin
  Result := DataType;
end;


function TLuaVariable.GetAsBoolean: Boolean;
begin
  Result := BooleanValue;
end;


function TLuaVariable.GetAsInteger: Integer;
begin
  Result := IntegerValue;
end;


function TLuaVariable.GetAsNumber: Double;
begin
  Result := NumberValue;
end;


function TLuaVariable.GetAsUserData: Pointer;
begin
  Result := UserDataValue;
end;


function TLuaVariable.GetAsString: string;
begin
  Result := StringValue;
end;


function TLuaVariable.GetAsTable: ILuaTable;
begin
  Result := TableValue;
end;


procedure TLuaVariable.SetAsBoolean(ABoolean: Boolean);
begin
  VariableType := VariableBoolean;
  DataType := LuaBoolean;
  BooleanValue := ABoolean;
end;


procedure TLuaVariable.SetAsInteger(AInteger: Integer);
begin
  VariableType := VariableInteger;
  DataType := LuaString;
  IntegerValue := AInteger;
end;


procedure TLuaVariable.SetAsNumber(ANumber: Double);
begin
  VariableType := VariableNumber;
  DataType := LuaNumber;
  NumberValue := ANumber;
end;


procedure TLuaVariable.SetAsUserData(AUserData: Pointer);
begin
  VariableType := VariableUserData;
  DataType := LuaLightUserData;
  UserDataValue := AUserData;
end;


procedure TLuaVariable.SetAsString(AString: string);
begin
  VariableType := VariableString;
  DataType := LuaString;
  StringValue := AString;
end;


procedure TLuaVariable.SetAsTable(ATable: ILuaTable);
begin
  VariableType := VariableTable;
  DataType := LuaTable;
  TableValue := ATable;
end;


{ TLuaCachedVariable }
constructor TLuaCachedVariable.Create(AState: lua_State; AIndex: Integer);
begin
  inherited Create;

  DataType := GetLuaDataType(lua_type(AState, AIndex));
  VariableType := GetLuaVariableType(FDataType);

  BooleanValue := (lua_toboolean(AState, AIndex) <> 0);
  IntegerValue := lua_tointeger(AState, AIndex);
  NumberValue := lua_tonumber(AState, AIndex);
  UserDataValue := lua_touserdata(AState, AIndex);

  { While traversing a table, do not call lua_tolstring directly on a key,
    unless you know that the key is actually a string. Recall that lua_tolstring
    may change the value at the given index; this confuses the next call to
    lua_next.

    http://www.lua.org/manual/5.2/manual.html#lua_next }
  case lua_type(AState, AIndex) of
    LUA_TSTRING:  StringValue := LuaToString(AState, AIndex);
    LUA_TNUMBER:  StringValue := FloatToStr(NumberValue);
  end;

  if lua_istable(AState, AIndex) then
    TableValue := TLuaCachedTable.Create(AState, AIndex);
end;


{ TLuaCachedTable }
constructor TLuaCachedTable.Create(AState: lua_State; AIndex: Integer);
var
  tableIndex: Integer;
  key: ILuaVariable;
  value: ILuaVariable;

begin
  inherited Create;

  lua_pushnil(AState);

  tableIndex := AIndex;
  if AIndex < 0 then
    Dec(tableIndex);

  while (lua_next(AState, tableIndex) <> 0) do
  begin
    key := TLuaCachedVariable.Create(AState, -2);
    value := TLuaCachedVariable.Create(AState, -1);

    SetValue(key, value);

    { Remove value, keep key for the next iteration }
    lua_pop(AState, 1);
  end;
end;


{ TLuaReadWriteParameters }
constructor TLuaReadWriteParameters.Create;
begin
  inherited Create;

  FParameters := TList<ILuaVariable>.Create;
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


function TLuaReadWriteParameters.GetItem(Index: Integer): ILuaVariable;
begin
  Result := FParameters[Index];
end;


procedure TLuaReadWriteParameters.Push(ABoolean: Boolean);
begin
  FParameters.Add(TLuaVariable.Create(ABoolean));
end;


procedure TLuaReadWriteParameters.Push(AInteger: Integer);
begin
  FParameters.Add(TLuaVariable.Create(AInteger));
end;


procedure TLuaReadWriteParameters.Push(ANumber: Double);
begin
  FParameters.Add(TLuaVariable.Create(ANumber));
end;


procedure TLuaReadWriteParameters.Push(AUserData: Pointer);
begin
  FParameters.Add(TLuaVariable.Create(AUserData));
end;


procedure TLuaReadWriteParameters.Push(const AString: string);
begin
  FParameters.Add(TLuaVariable.Create(AString));
end;


procedure TLuaReadWriteParameters.Push(ATable: ILuaTable);
begin
  FParameters.Add(TLuaVariable.Create(ATable));
end;


{ TLuaContext }
constructor TLuaContext.Create(AState: lua_State);
begin
  inherited Create;

  FParameters := TLuaStackParameters.Create(AState);
  FResult := TLuaStackWriteParameters.Create(AState);
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
constructor TLuaStackWriteParameters.Create(AState: lua_State);
begin
  inherited Create;

  FState := AState;
end;


function TLuaStackWriteParameters.GetCount: Integer;
begin
  Result := FCount;
end;


procedure TLuaStackWriteParameters.Push(ABoolean: Boolean);
begin
  lua_pushboolean(State, IfThen(ABoolean, 1, 0));
  Pushed;
end;


procedure TLuaStackWriteParameters.Push(AInteger: Integer);
begin
  lua_pushinteger(State, AInteger);
  Pushed;
end;


procedure TLuaStackWriteParameters.Push(ANumber: Double);
begin
  lua_pushnumber(State, ANumber);
  Pushed;
end;


procedure TLuaStackWriteParameters.Push(AUserData: Pointer);
begin
  lua_pushlightuserdata(State, AUserData);
  Pushed;
end;


procedure TLuaStackWriteParameters.Push(const AString: string);
var
  value: PAnsiChar;

begin
  value := AllocLuaString(AString);
  try
    lua_pushlstring(State, value, Length(AString));
    Pushed;
  finally
    FreeLuaString(value);
  end;
end;


procedure TLuaStackWriteParameters.Push(ATable: ILuaTable);
begin
  PushTable(State, ATable);
  Pushed;
end;


procedure TLuaStackWriteParameters.Pushed;
begin
  Inc(FCount);
end;

end.
