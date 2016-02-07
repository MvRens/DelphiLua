{
  Wrapper classes for Lua API

  Created by M. van Renswoude, April 2014:

  This software is provided 'as-is', without any express or implied
  warranty. In no event will the authors be held liable for any damages
  arising from the use of this software.

  Permission is granted to anyone to use this software for any purpose,
  including commercial applications, and to alter it and redistribute it
  freely, subject to the following restrictions:

     1. The origin of this software must not be misrepresented; you must not
     claim that you wrote the original software. If you use this software
     in a product, an acknowledgment in the product documentation would be
     appreciated but is not required.

     2. Altered source versions must be plainly marked as such, and must not be
     misrepresented as being the original software.

     3. This notice may not be removed or altered from any source
     distribution.
}
unit Lua;

interface
uses
  System.Classes,
  System.Generics.Collections,
  System.Generics.Defaults,
  System.Rtti,
  System.SysUtils,

  Lua.API;

type
  ELuaException = class(Exception);
  ELuaInitException = class(ELuaException);
  ELuaUnsupportedParameterException = class(ELuaException);
  ELuaUnsupportedVariableException = class(ELuaException);
  ELuaNoFunctionException = class(ELuaException);

  TLuaLibrary = (Base, Coroutine, Table, IO, OS, StringLib, Bit32, Math, Debug, Package, All);
  TLuaLibraries = set of TLuaLibrary;

  TLuaDataType = (LuaNone, LuaNil, LuaNumber, LuaBoolean, LuaString, LuaTable,
                  LuaFunction, LuaUserData, LuaThread, LuaLightUserData);

  TLuaVariableType = (VariableNone, VariableBoolean, VariableInteger,
                      VariableNumber, VariableUserData, VariableString,
                      VariableTable, VariableFunction);

  ILuaTable = interface;
  ILuaFunction = interface;


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
    function GetAsFunction: ILuaFunction;

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
    property AsFunction: ILuaFunction read GetAsFunction;
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


  ILuaReadParameters = interface(ILuaVariable)
    ['{FB611D9E-B51D-460B-B5AB-B567EF853222}']
    function GetCount: Integer;
    function GetItem(Index: Integer): ILuaVariable;

    function GetEnumerator: ILuaParametersEnumerator;
    function ToString: string;

    property Count: Integer read GetCount;
    property Items[Index: Integer]: ILuaVariable read GetItem; default;
  end;


  ILuaWriteParameters = interface
    ['{5CEEB16B-158E-44BE-8CAD-DC2C330A244A}']
    function GetCount: Integer;

    procedure Push(ABoolean: Boolean); overload;
    procedure Push(AInteger: Integer); overload;
    procedure Push(ANumber: Double); overload;
    procedure Push(AUserData: Pointer); overload;
    procedure Push(const AString: string); overload;
    procedure Push(ATable: ILuaTable); overload;

    property Count: Integer read GetCount;
  end;


  ILuaFunction = interface
    ['{1BE5E470-0318-410E-8D5B-94BFE04A3DBE}']
    function Call(): ILuaReadParameters; overload;
    function Call(AParameters: array of const): ILuaReadParameters; overload;
    function Call(AParameters: ILuaReadParameters): ILuaReadParameters; overload;
  end;


  ILuaContext = interface
    ['{1F999593-E3D1-4195-9463-A42025AE9830}']
    function GetParameters: ILuaReadParameters;
    function GetResult: ILuaWriteParameters;

    property Parameters: ILuaReadParameters read GetParameters;
    property Result: ILuaWriteParameters read GetResult;
  end;


  TLuaCFunction = reference to procedure(Context: ILuaContext);
  TLuaCMethod = procedure(Context: ILuaContext) of object;
  TLuaPushFunction = reference to procedure(AFunction: TLuaCFunction);


  TCustomLuaRegistration = class(TObject)
  private
    FName: string;
  protected
    property Name: string read FName write FName;
  public
    constructor Create(const AName: string);

    procedure Apply(AState: lua_State; APushFunction: TLuaPushFunction); virtual; abstract;
  end;


  TLuaFunctionRegistration = class(TCustomLuaRegistration)
  private
    FCallback: TLuaCFunction;
  protected
    property Callback: TLuaCFunction read FCallback;
  public
    constructor Create(const AName: string; ACallback: TLuaCFunction);

    procedure Apply(AState: lua_State; APushFunction: TLuaPushFunction); override;
  end;


  TLuaFunctionTable = TDictionary<string, TLuaCFunction>;

  TLuaTableRegistration = class(TCustomLuaRegistration)
  private
    FFunctionTable: TLuaFunctionTable;
  protected
    property FunctionTable: TLuaFunctionTable read FFunctionTable;
  public
    constructor Create(const AName: string);
    destructor Destroy; override;

    procedure RegisterFunction(const AName: string; AFunction: TLuaCFunction); virtual;
    procedure Apply(AState: lua_State; APushFunction: TLuaPushFunction); override;
  end;


  TLuaRegistrationList = TObjectList<TCustomLuaRegistration>;
  TLuaRegisteredFunctionDictionary = TDictionary<Integer, TLuaCFunction>;


  TLuaScript = class(TObject)
  private
    FStream: TStream;
    FStreamOwnership: TStreamOwnership;
    FBuffer: PAnsiChar;
  public
    constructor Create(const AData: string); overload;
    constructor Create(const AStream: TStream; AOwnership: TStreamOwnership = soReference); overload;
    destructor Destroy; override;

    function GetNextChunk(out ASize: NativeUint): PAnsiChar; virtual;
  end;


  TLua = class(TObject)
  private
    FState: lua_State;
    FLoaded: Boolean;
    FRegistrations: TLuaRegistrationList;
    FRegisteredFunctions: TLuaRegisteredFunctionDictionary;
    FRegisteredFunctionCookie: Integer;
    FAutoOpenLibraries: TLuaLibraries;
    FHasRun: Boolean;
    FRttiContext: TRttiContext;
  protected
    function GetHasState: Boolean; virtual;
    function GetState: lua_State; virtual;

    function DoAlloc(APointer: Pointer; AOldSize, ANewSize: NativeUint): Pointer; virtual;

    procedure DoNewState; virtual;
    procedure DoClose; virtual;
    procedure DoRegistration(ARegistration: TCustomLuaRegistration); virtual;

    procedure SetAutoOpenLibraries(const Value: TLuaLibraries); virtual;
  protected
    procedure CheckState; virtual;
    procedure CheckIsFunction; virtual;
    procedure AfterLoad; virtual;

    procedure AddRegistration(ARegistration: TCustomLuaRegistration); virtual;
    function GetRegisteredFunctionCookie: Integer; virtual;
    function RunRegisteredFunction(ACookie: Integer): Integer; virtual;

    property Loaded: Boolean read FLoaded write FLoaded;
    property HasRun: Boolean read FHasRun write FHasRun;
    property Registrations: TLuaRegistrationList read FRegistrations;
    property RegisteredFunctions: TLuaRegisteredFunctionDictionary read FRegisteredFunctions;
  public
    constructor Create;
    destructor Destroy; override;

    procedure LoadFromString(const AData: string; AAutoRun: Boolean = True; const AChunkName: string = ''); virtual;
    procedure LoadFromStream(AStream: TStream; AOwnership: TStreamOwnership = soReference; AAutoRun: Boolean = True; const AChunkName: string = ''); virtual;
    procedure LoadFromFile(const AFileName: string; AAutoRun: Boolean = True; const AChunkName: string = ''); virtual;
    procedure LoadFromScript(AScript: TLuaScript; AOwnership: TStreamOwnership = soReference; AAutoRun: Boolean = True; const AChunkName: string = ''); virtual;

    function GetGlobalVariable(const AName: string): ILuaVariable; virtual;
    procedure SetGlobalVariable(const AName: string; AVariable: TLuaImplicitVariable); virtual;
    procedure RegisterFunction(const AName: string; AFunction: TLuaCFunction); virtual;
//    procedure UnregisterFunction();

    { Registers all published methods of the specified object. If ATableName
      is provided, the methods will be bundled in a global table and accessible as
      ATableName.Method(). If not provided, the methods are accessible directly
      as global functions. }
    procedure RegisterFunctions(AObject: TObject; const ATableName: string = ''; AIncludePublicVisibility: Boolean = False); virtual;
//    procedure UnregisterFunctions();

    procedure OpenLibraries(ALibraries: TLuaLibraries); virtual;

    { These methods should only be called right after one of the
      LoadFrom methods, which must have AutoRun set to False. }
    procedure Run; virtual;
    procedure GetByteCode(AStream: TStream; APop: Boolean = False); virtual;
    procedure Capture(const AName: string); virtual;

    function Call(const AFunctionName: string): ILuaReadParameters; overload; virtual;
    function Call(const AFunctionName: string; AParameters: array of const): ILuaReadParameters; overload; virtual;
    function Call(const AFunctionName: string; AParameters: ILuaReadParameters): ILuaReadParameters; overload; virtual;

    property HasState: Boolean read GetHasState;
    property State: lua_State read GetState;

    property AutoOpenLibraries: TLuaLibraries read FAutoOpenLibraries write SetAutoOpenLibraries default [TLuaLibrary.All];
  end;


  TLuaHelpers = class(TObject)
  private
    class var RegistryKeyCounter: Int64;
  public
    class function GetLuaDataType(AType: Integer): TLuaDataType;
    class function GetLuaVariableType(ADataType: TLuaDataType): TLuaVariableType;

    class function CreateParameters(AParameters: array of const): ILuaReadParameters;

    class procedure PushVariable(AState: lua_State; AVariable: ILuaVariable); overload;
    class procedure PushVariable(AState: lua_State; AVariable: ILuaVariable; AVariableType: TLuaVariableType); overload;
    class procedure PushString(AState: lua_State; const AValue: string);
    class procedure PushTable(AState: lua_State; ATable: ILuaTable);

    class function AllocLuaString(const AValue: string): PAnsiChar;
    class procedure FreeLuaString(AValue: PAnsiChar);

    class procedure RaiseLastLuaError(AState: lua_State);
    class function LuaToString(AState: lua_State; AIndex: Integer): string;
    class function CallFunction(AState: lua_State; AParameters: ILuaReadParameters): ILuaReadParameters;

    class function NewRegistryKey: string;
  end;



implementation
uses
  System.Math,
  System.SyncObjs,
  System.TypInfo;


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


  TCustomLuaParameters = class(TInterfacedObject, ILuaVariable, ILuaReadParameters)
  protected
    function GetDefaultVariable: ILuaVariable;
  public
    { ILuaVariable }
    function GetVariableType: TLuaVariableType;
    function GetDataType: TLuaDataType;

    function GetAsBoolean: Boolean;
    function GetAsInteger: Integer;
    function GetAsNumber: Double;
    function GetAsUserData: Pointer;
    function GetAsString: string;
    function GetAsTable: ILuaTable;
    function GetAsFunction: ILuaFunction;

    procedure SetAsBoolean(ABoolean: Boolean);
    procedure SetAsInteger(AInteger: Integer);
    procedure SetAsNumber(ANumber: Double);
    procedure SetAsUserData(AUserData: Pointer);
    procedure SetAsString(AString: string);
    procedure SetAsTable(ATable: ILuaTable);

    { ILuaReadParameters }
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

    { ILuaReadParameters }
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
    function GetAsFunction: ILuaFunction;

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
    FFunctionValue: ILuaFunction;
  protected
    property VariableType: TLuaVariableType read FVariableType write FVariableType;
    property DataType: TLuaDataType read FDataType write FDataType;
    property BooleanValue: Boolean read FBooleanValue write FBooleanValue;
    property IntegerValue: Integer read FIntegerValue write FIntegerValue;
    property NumberValue: Double read FNumberValue write FNumberValue;
    property UserDataValue: Pointer read FUserDataValue write FUserDataValue;
    property StringValue: string read FStringValue write FStringValue;
    property TableValue: ILuaTable read FTableValue write FTableValue;
    property FunctionValue: ILuaFunction read FFunctionValue write FFunctionValue;
  public
    constructor Create; overload;
    constructor Create(ABoolean: Boolean); overload;
    constructor Create(AInteger: Integer); overload;
    constructor Create(ANumber: Double); overload;
    constructor Create(AUserData: Pointer); overload;
    constructor Create(const AString: string); overload;
    constructor Create(ATable: ILuaTable); overload;
    constructor Create(AFunction: ILuaFunction); overload;

    { ILuaParameter }
    function GetVariableType: TLuaVariableType;
    function GetDataType: TLuaDataType;

    function GetAsBoolean: Boolean;
    function GetAsInteger: Integer;
    function GetAsNumber: Double;
    function GetAsUserData: Pointer;
    function GetAsString: string;
    function GetAsTable: ILuaTable;
    function GetAsFunction: ILuaFunction;

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


  TLuaStackWriteParameters = class(TInterfacedObject, ILuaWriteParameters)
  private
    FState: lua_State;
    FCount: Integer;
  protected
    procedure Pushed;

    property State: lua_State read FState;
  public
    constructor Create(AState: lua_State);

    { ILuaWriteParameters }
    function GetCount: Integer;

    procedure Push(ABoolean: Boolean); overload;
    procedure Push(AInteger: Integer); overload;
    procedure Push(ANumber: Double); overload;
    procedure Push(AUserData: Pointer); overload;
    procedure Push(const AString: string); overload;
    procedure Push(ATable: ILuaTable); overload;
  end;


  TLuaFunction = class(TInterfacedObject, ILuaFunction)
  private
    FState: lua_State;
    FRegistryKey: string;
  protected
    property State: lua_State read FState;
    property RegistryKey: string read FRegistryKey;
  public
    constructor Create(AState: lua_State; AIndex: Integer);
    destructor Destroy; override;

    { ILuaFunction }
    function Call(): ILuaReadParameters; overload;
    function Call(AParameters: array of const): ILuaReadParameters; overload;
    function Call(AParameters: ILuaReadParameters): ILuaReadParameters; overload;
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



{ TLuaHelpers }
class function TLuaHelpers.GetLuaDataType(AType: Integer): TLuaDataType;
begin
  case AType of
    LUA_TNIL: Result := LuaNil;
    LUA_TNUMBER: Result := LuaNumber;
    LUA_TBOOLEAN: Result := LuaBoolean;
    LUA_TSTRING: Result := LuaString;
    LUA_TTABLE: Result := LuaTable;
    LUA_TFUNCTION: Result := LuaFunction;
    LUA_TUSERDATA: Result := LuaUserData;
    LUA_TTHREAD: Result := LuaThread;
    LUA_TLIGHTUSERDATA: Result := LuaLightUserData;
  else
    Result := LuaNone;
  end;
end;


class function TLuaHelpers.GetLuaVariableType(ADataType: TLuaDataType): TLuaVariableType;
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


class function TLuaHelpers.CreateParameters(AParameters: array of const): ILuaReadParameters;
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


class procedure TLuaHelpers.PushVariable(AState: lua_State; AVariable: ILuaVariable);
begin
  PushVariable(AState, AVariable, AVariable.VariableType);
end;


class procedure TLuaHelpers.PushVariable(AState: lua_State; AVariable: ILuaVariable; AVariableType: TLuaVariableType);
begin
  case AVariableType of
    VariableNone:     lua_pushnil(AState);
    VariableBoolean:  lua_pushboolean(AState, IfThen(AVariable.AsBoolean, 1, 0));
    VariableInteger:  lua_pushinteger(AState, AVariable.AsInteger);
    VariableNumber:   lua_pushnumber(AState, AVariable.AsNumber);
    VariableUserData: lua_pushlightuserdata(AState, AVariable.AsUserData);
    VariableString:   PushString(AState, AVariable.AsString);
    VariableTable:    PushTable(AState, AVariable.AsTable);
  else
    raise ELuaUnsupportedVariableException.CreateFmt('Variable type not supported: %d', [Ord(AVariableType)]);
  end;
end;


class procedure TLuaHelpers.PushString(AState: lua_State; const AValue: string);
var
  stringValue: PAnsiChar;

begin
  stringValue := AllocLuaString(AValue);
  try
    lua_pushlstring(AState, stringValue, Length(AValue));
  finally
    FreeLuaString(stringValue);
  end;
end;


class procedure TLuaHelpers.PushTable(AState: lua_State; ATable: ILuaTable);
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


// Casting strings directly to PAnsiChar (via AnsiString) causes corruption
// with table values, at least in Delphi XE2. Can't really explain why, seems
// the input string goes out of scope, so let's just go through the motions
// to create a copy and be safe.
class function TLuaHelpers.AllocLuaString(const AValue: string): PAnsiChar;
begin
  if Length(AValue) > 0 then
  begin
    GetMem(Result, Length(AValue) + 1);
    StrPCopy(Result, AnsiString(AValue));
  end else
    Result := nil;
end;


class procedure TLuaHelpers.FreeLuaString(AValue: PAnsiChar);
begin
  FreeMem(AValue);
end;

// If someone cares to reproduce this issue and optimize the code, use these
// two and the TableLuaFunction test should fail with a corrupted value
// (#11#0#0#0#11#0#0#0#11#0#0#0#11#0#0#0#11).
(*
class function TLuaHelpers.AllocLuaString(const AValue: string): PAnsiChar;
begin
  if Length(AValue) > 0 then
    Result := PAnsiChar(AnsiString(AValue))
  else
    Result := nil;
end;

class procedure TLuaHelpers.FreeLuaString(AValue: PAnsiChar);
begin
end;
*)




class procedure TLuaHelpers.RaiseLastLuaError(AState: lua_State);
var
  errorMessage: string;

begin
  errorMessage := LuaToString(AState, -1);
  lua_pop(AState, 1);

  raise ELuaException.Create(errorMessage);
end;


class function TLuaHelpers.LuaToString(AState: lua_State; AIndex: Integer): string;
var
  len: NativeUint;
  value: PAnsiChar;
  stringValue: RawByteString;

begin
  value := lua_tolstring(AState, AIndex, @len);
  SetString(stringValue, value, len);

  Result := string(stringValue);
end;


class function TLuaHelpers.CallFunction(AState: lua_State; AParameters: ILuaReadParameters): ILuaReadParameters;
var
  stackIndex: Integer;
  parameterCount: Integer;
  parameter: ILuaVariable;

begin
  { Assumption: the function to call is the top item on the stack }
  stackIndex := Pred(lua_gettop(AState));

  parameterCount := 0;
  if Assigned(AParameters) then
  begin
    parameterCount := AParameters.Count;
    for parameter in AParameters do
      PushVariable(AState, parameter);
  end;

  if lua_pcall(AState, parameterCount, LUA_MULTRET, 0) <> 0 then
    RaiseLastLuaError(AState);

  Result := TLuaResultParameters.Create(AState, lua_gettop(AState) - stackIndex);
end;


class function TLuaHelpers.NewRegistryKey: string;
begin
  // This could be incremented on a per-State basis, but this'll do for now.
  Result := Format('DelphiLuaWrapper_%d', [TInterlocked.Increment(RegistryKeyCounter)]);
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
      begin
        p := Pointer(Value.AsTable);
        Result := BobJenkinsHash(p, SizeOf(p), 0);
      end;
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


{ TCustomLuaRegistration }
constructor TCustomLuaRegistration.Create(const AName: string);
begin
  inherited Create;

  FName := AName;
end;


{ TLuaFunctionRegistration }
procedure TLuaFunctionRegistration.Apply(AState: lua_State; APushFunction: TLuaPushFunction);
var
  functionName: PAnsiChar;

begin
  functionName := TLuaHelpers.AllocLuaString(Name);
  try
    APushFunction(Callback);
    lua_setglobal(AState, functionName);
  finally
    TLuaHelpers.FreeLuaString(functionName);
  end;
end;

constructor TLuaFunctionRegistration.Create(const AName: string; ACallback: TLuaCFunction);
begin
  inherited Create(AName);

  FCallback := ACallback;
end;


{ TLuaTableRegistration }
constructor TLuaTableRegistration.Create(const AName: string);
begin
  inherited Create(AName);

  FFunctionTable := TLuaFunctionTable.Create;
end;


destructor TLuaTableRegistration.Destroy;
begin
  FreeAndNil(FFunctionTable);

  inherited Destroy;
end;


procedure TLuaTableRegistration.RegisterFunction(const AName: string; AFunction: TLuaCFunction);
begin
  FunctionTable.AddOrSetValue(AName, AFunction);
end;


procedure TLuaTableRegistration.Apply(AState: lua_State; APushFunction: TLuaPushFunction);
var
  pair: TPair<string, TLuaCFunction>;
  functionName: PAnsiChar;
  tableName: PAnsiChar;

begin
  lua_newtable(AState);

  for pair in FunctionTable do
  begin
    functionName := TLuaHelpers.AllocLuaString(pair.Key);
    try
      lua_pushstring(AState, functionName);
      APushFunction(pair.Value);
      lua_settable(AState, -3);
    finally
      TLuaHelpers.FreeLuaString(functionName);
    end;
  end;

  tableName := TLuaHelpers.AllocLuaString(Name);
  try
    lua_setglobal(AState, tableName);
  finally
    TLuaHelpers.FreeLuaString(tableName);
  end;
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


function TLuaScript.GetNextChunk(out ASize: NativeUint): PAnsiChar;
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


function LuaWrapperReader(L: lua_State; ud: Pointer; var sz: Lua.size_t): PAnsiChar; cdecl;
var
  script: PLuaScript;

begin
  script := ud;
  Result := script^.GetNextChunk(sz);
end;


function LuaWrapperWriter(L: lua_State; p: Pointer; sz: size_t; ud: Pointer): Integer; cdecl;
var
  stream: TStream;

begin
  stream := TStream(ud^);
  try
    stream.WriteBuffer(p^, sz);
    Result := 0;
  except
    on E:EStreamError do
      Result := 1;
  end;
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
  FRegistrations := TLuaRegistrationList.Create(True);
  FRegisteredFunctions := TLuaRegisteredFunctionDictionary.Create;
end;


destructor TLua.Destroy;
begin
  FreeAndNil(FRegisteredFunctions);
  FreeAndNil(FRegistrations);

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
    chunkName := TLuaHelpers.AllocLuaString(AChunkName);
    try
      if lua_load(State, LuaWrapperReader, @AScript, chunkName, nil) <> 0 then
        TLuaHelpers.RaiseLastLuaError(State);
    finally
      TLuaHelpers.FreeLuaString(chunkName);
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
      luaL_requiref(State, 'base', luaopen_base, 1);

    if TLuaLibrary.Coroutine in ALibraries then
      luaL_requiref(State, 'coroutine', luaopen_coroutine, 1);

    if TLuaLibrary.Table in ALibraries then
      luaL_requiref(State, 'table', luaopen_table, 1);

    if TLuaLibrary.IO in ALibraries then
      luaL_requiref(State, 'io', luaopen_io, 1);

    if TLuaLibrary.OS in ALibraries then
      luaL_requiref(State, 'os', luaopen_os, 1);

    if TLuaLibrary.StringLib in ALibraries then
      luaL_requiref(State, 'string', luaopen_string, 1);

    if TLuaLibrary.Bit32 in ALibraries then
      luaL_requiref(State, 'bit32', luaopen_bit32, 1);

    if TLuaLibrary.Math in ALibraries then
      luaL_requiref(State, 'math', luaopen_math, 1);

    if TLuaLibrary.Debug in ALibraries then
      luaL_requiref(State, 'debug', luaopen_debug, 1);

    if TLuaLibrary.Package in ALibraries then
      luaL_requiref(State, 'package', luaopen_package, 1);
  end;
end;


procedure TLua.Run;
begin
  CheckIsFunction;

  if lua_pcall(State, 0, 0, 0) <> 0 then
    TLuaHelpers.RaiseLastLuaError(State);

  HasRun := True;
end;


procedure TLua.GetByteCode(AStream: TStream; APop: Boolean);
var
  returnCode: Integer;

begin
  CheckIsFunction;

  try
    returnCode := lua_dump(State, LuaWrapperWriter, @AStream);
    if returnCode <> 0 then
      raise ELuaException.CreateFmt('lua_dump returned code %d', [returnCode]);
  finally
    if APop then
      lua_pop(State, 1);
  end;
end;


procedure TLua.Capture(const AName: string);
var
  name: PAnsiChar;

begin
  CheckIsFunction;

  // Create a new table to serve as the environment
  lua_newtable(State);

  // Set the global AName to the new table
  lua_pushvalue(State, -1);
  name := TLuaHelpers.AllocLuaString(AName);
  try
    lua_setglobal(State, name);
  finally
    TLuaHelpers.FreeLuaString(name);
  end;

  // Set the global environment as the table's metatable index, so calls to
  // global functions and variables still work
  lua_newtable(State);
  TLuaHelpers.PushString(State, '__index');
  lua_pushglobaltable(State);
  lua_settable(State, -3);

  lua_setmetatable(State, -2);

  // Set the new table as the environment (upvalue at index 1)
  lua_setupvalue(State, -2, 1);

  if lua_pcall(State, 0, 0, 0) <> 0 then
    TLuaHelpers.RaiseLastLuaError(State);
end;


function TLua.Call(const AFunctionName: string): ILuaReadParameters;
begin
  Result := Call(AFunctionName, nil);
end;


function TLua.Call(const AFunctionName: string; AParameters: array of const): ILuaReadParameters;
begin
  Result := Call(AFunctionName, TLuaHelpers.CreateParameters(AParameters));
end;


function TLua.Call(const AFunctionName: string; AParameters: ILuaReadParameters): ILuaReadParameters;
var
  functionName: PAnsiChar;

begin
  { Global functions are only present after the has run once:
      http://lua-users.org/lists/lua-l/2011-01/msg01154.html }
  if not HasRun then
    Run;

  functionName := TLuaHelpers.AllocLuaString(AFunctionName);
  try
    lua_getglobal(State, functionName);
  finally
    TLuaHelpers.FreeLuaString(functionName);
  end;

  Result := TLuaHelpers.CallFunction(State, AParameters);
end;


procedure TLua.CheckState;
begin
  if not LuaLibLoaded then
    LoadLuaLib;

  if not HasState then
    DoNewState;
end;


procedure TLua.CheckIsFunction;
begin
  if not lua_isfunction(State, -1) then
    raise ELuaNoFunctionException.Create('No function on top of the stack, use the LoadFrom methods first');
end;


procedure TLua.AfterLoad;
var
  registration: TCustomLuaRegistration;

begin
  Loaded := True;
  HasRun := False;

  { Register functions in the current environment }
  for registration in Registrations do
    DoRegistration(registration);
end;


function TLua.GetGlobalVariable(const AName: string): ILuaVariable;
var
  name: PAnsiChar;

begin
  name := TLuaHelpers.AllocLuaString(AName);
  try
    lua_getglobal(State, name);

    Result := TLuaCachedVariable.Create(State, -1);
    lua_pop(State, 1);
  finally
    TLuaHelpers.FreeLuaString(name);
  end;
end;


procedure TLua.SetGlobalVariable(const AName: string; AVariable: TLuaImplicitVariable);
var
  name: PAnsiChar;

begin
  name := TLuaHelpers.AllocLuaString(AName);
  try
    TLuaHelpers.PushVariable(State, AVariable);
    lua_setglobal(State, name);
  finally
    TLuaHelpers.FreeLuaString(name);
  end;
end;


procedure TLua.RegisterFunction(const AName: string; AFunction: TLuaCFunction);
begin
  { Since anonymous methods are basically interfaces, we need to keep a reference around }
  AddRegistration(TLuaFunctionRegistration.Create(AName, AFunction));
end;


procedure TLua.RegisterFunctions(AObject: TObject; const ATableName: string; AIncludePublicVisibility: Boolean);

  { This wrapper is needed because Delphi's anonymous functions capture
    variables, not values. We need a stable 'callback' here. }
  function CaptureCallback(AMethod: TMethod): TLuaCFunction; inline;
  begin
    Result := TLuaCMethod(AMethod);
  end;

var
  rttiType: TRttiType;
  rttiMethod: TRttiMethod;
  rttiParameters: TArray<System.Rtti.TRttiParameter>;
  callback: TMethod;
  tableRegistration: TLuaTableRegistration;

begin
  tableRegistration := nil;
  if Length(ATableName) > 0 then
    tableRegistration := TLuaTableRegistration.Create(ATableName);

  rttiType := FRttiContext.GetType(AObject.ClassType);
  for rttiMethod in rttiType.GetMethods do
  begin
    if (rttiMethod.Visibility = mvPublished) or
       (AIncludePublicVisibility and (rttiMethod.Visibility = mvPublic)) then
    begin
      rttiParameters := rttiMethod.GetParameters;

      { Check if one parameter of type ILuaContext is present }
      if (Length(rttiParameters) = 1) and
         (Assigned(rttiParameters[0].ParamType)) and
         (rttiParameters[0].ParamType.TypeKind = tkInterface) and
         (TRttiInterfaceType(rttiParameters[0].ParamType).GUID = ILuaContext) then
      begin
        callback.Code := rttiMethod.CodeAddress;
        callback.Data := AObject;

        if Assigned(tableRegistration) then
          tableRegistration.RegisterFunction(rttiMethod.Name, CaptureCallback(callback))
        else
          AddRegistration(TLuaFunctionRegistration.Create(rttiMethod.Name, CaptureCallback(callback)));
      end;
    end;
  end;

  if Assigned(tableRegistration) then
    AddRegistration(tableRegistration);
end;


function TLua.DoAlloc(APointer: Pointer; AOldSize, ANewSize: NativeUint): Pointer;
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


procedure TLua.DoRegistration(ARegistration: TCustomLuaRegistration);
var
  this: TLua;

begin
  this := Self;

  ARegistration.Apply(State,
    procedure(AFunction: TLuaCFunction)
    var
      cookie: Integer;

    begin
      cookie := GetRegisteredFunctionCookie;
      RegisteredFunctions.Add(cookie, AFunction);

      lua_pushlightuserdata(State, this);
      lua_pushinteger(State, Cookie);
      lua_pushcclosure(State, @LuaWrapperFunction, 2);
    end);
end;

procedure TLua.AddRegistration(ARegistration: TCustomLuaRegistration);
begin
  Registrations.Add(ARegistration);

  { Only register functions after Load, otherwise they'll not be available in the environment }
  if Loaded then
    DoRegistration(ARegistration);
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

    RegisteredFunctions[ACookie](context);
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


function TCustomLuaParameters.GetVariableType: TLuaVariableType;
begin
  Result := GetDefaultVariable.GetVariableType;
end;


function TCustomLuaParameters.GetDataType: TLuaDataType;
begin
  Result := GetDefaultVariable.GetDataType;
end;


function TCustomLuaParameters.GetAsBoolean: Boolean;
begin
  Result := GetDefaultVariable.GetAsBoolean;
end;


function TCustomLuaParameters.GetAsInteger: Integer;
begin
  Result := GetDefaultVariable.GetAsInteger;
end;


function TCustomLuaParameters.GetAsNumber: Double;
begin
  Result := GetDefaultVariable.GetAsNumber;
end;


function TCustomLuaParameters.GetAsUserData: Pointer;
begin
  Result := GetDefaultVariable.GetAsUserData;
end;


function TCustomLuaParameters.GetAsString: string;
begin
  Result := GetDefaultVariable.GetAsString;
end;


function TCustomLuaParameters.GetAsTable: ILuaTable;
begin
  Result := GetDefaultVariable.GetAsTable;
end;


function TCustomLuaParameters.GetAsFunction: ILuaFunction;
begin
  Result := GetDefaultVariable.GetAsFunction;
end;


procedure TCustomLuaParameters.SetAsBoolean(ABoolean: Boolean);
begin
  GetDefaultVariable.SetAsBoolean(ABoolean);
end;


procedure TCustomLuaParameters.SetAsInteger(AInteger: Integer);
begin
  GetDefaultVariable.SetAsInteger(AInteger);
end;


procedure TCustomLuaParameters.SetAsNumber(ANumber: Double);
begin
  GetDefaultVariable.SetAsNumber(ANumber);
end;


procedure TCustomLuaParameters.SetAsUserData(AUserData: Pointer);
begin
  GetDefaultVariable.SetAsUserData(AUserData);
end;


procedure TCustomLuaParameters.SetAsString(AString: string);
begin
  GetDefaultVariable.SetAsString(AString);
end;


procedure TCustomLuaParameters.SetAsTable(ATable: ILuaTable);
begin
  GetDefaultVariable.SetAsTable(ATable);
end;


function TCustomLuaParameters.GetDefaultVariable: ILuaVariable;
begin
  Result := GetItem(0);
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
  Result := TLuaHelpers.GetLuaVariableType(GetDataType);
end;


function TLuaStackVariable.GetDataType: TLuaDataType;
begin
  Result := TLuaHelpers.GetLuaDataType(lua_type(State, Index));
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
  Result := TLuaHelpers.LuaToString(State, Index);
end;


function TLuaStackVariable.GetAsTable: ILuaTable;
begin
  if not lua_istable(State, Index) then
    Result := nil;

  if not Assigned(FTable) then
    FTable := TLuaCachedTable.Create(State, Index);

  Result := FTable;
end;


function TLuaStackVariable.GetAsFunction: ILuaFunction;
begin
  if not lua_isfunction(State, Index) then
    Result := nil;

  Result := TLuaFunction.Create(State, Index);
end;


procedure TLuaStackVariable.SetAsBoolean(ABoolean: Boolean);
begin
  lua_pushboolean(State, IfThen(ABoolean, 1, 0));
  lua_replace(State, Index);
end;


procedure TLuaStackVariable.SetAsInteger(AInteger: Integer);
begin
  TLuaHelpers.PushVariable(State, Self, VariableInteger);
  lua_replace(State, Index);
end;


procedure TLuaStackVariable.SetAsNumber(ANumber: Double);
begin
  TLuaHelpers.PushVariable(State, Self, VariableNumber);
  lua_replace(State, Index);
end;


procedure TLuaStackVariable.SetAsString(AString: string);
begin
  TLuaHelpers.PushVariable(State, Self, VariableString);
  lua_replace(State, Index);
end;


procedure TLuaStackVariable.SetAsTable(ATable: ILuaTable);
begin
  TLuaHelpers.PushVariable(State, Self, VariableTable);
  lua_replace(State, Index);
end;


procedure TLuaStackVariable.SetAsUserData(AUserData: Pointer);
begin
  TLuaHelpers.PushVariable(State, Self, VariableUserData);
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


constructor TLuaVariable.Create(AFunction: ILuaFunction);
begin
  Create;
  VariableType := VariableFunction;
  DataType := LuaFunction;
  FunctionValue := AFunction;
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


function TLuaVariable.GetAsFunction: ILuaFunction;
begin
  Result := FunctionValue;
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

  DataType := TLuaHelpers.GetLuaDataType(lua_type(AState, AIndex));
  VariableType := TLuaHelpers.GetLuaVariableType(FDataType);

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
    LUA_TSTRING:  StringValue := TLuaHelpers.LuaToString(AState, AIndex);
    LUA_TNUMBER:  StringValue := FloatToStr(NumberValue);
  end;

  if lua_istable(AState, AIndex) then
    TableValue := TLuaCachedTable.Create(AState, AIndex);

  if lua_isfunction(AState, AIndex) then
    FunctionValue := TLuaFunction.Create(AState, AIndex);
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
  value := TLuaHelpers.AllocLuaString(AString);
  try
    lua_pushlstring(State, value, Length(AString));
    Pushed;
  finally
    TLuaHelpers.FreeLuaString(value);
  end;
end;


procedure TLuaStackWriteParameters.Push(ATable: ILuaTable);
begin
  TLuaHelpers.PushTable(State, ATable);
  Pushed;
end;


procedure TLuaStackWriteParameters.Pushed;
begin
  Inc(FCount);
end;


{ TLuaCFunction }
constructor TLuaFunction.Create(AState: lua_State; AIndex: Integer);
var
  actualIndex: Integer;

begin
  inherited Create;

  FState := AState;

  // There is no way to retrieve the function in a way that allows pushing
  // it back later. Instead, make use of Lua's registry:
  // http://stackoverflow.com/questions/1416797/reference-to-lua-function-in-c-c
  FRegistryKey := TLuaHelpers.NewRegistryKey;
  actualIndex := AIndex;

  // If the index is relative to the top, compensate for pushing the key
  if actualIndex < 0 then
    Dec(actualIndex);

  TLuaHelpers.PushString(AState, RegistryKey);
  lua_pushvalue(AState, actualIndex);
  lua_rawset(AState, LUA_REGISTRYINDEX);
end;


destructor TLuaFunction.Destroy;
begin
  TLuaHelpers.PushString(State, RegistryKey);
  lua_pushnil(State);
  lua_rawset(State, LUA_REGISTRYINDEX);

  inherited Destroy;
end;


function TLuaFunction.Call: ILuaReadParameters;
begin
  Result := Call(nil);
end;


function TLuaFunction.Call(AParameters: array of const): ILuaReadParameters;
begin
  Result := Call(TLuaHelpers.CreateParameters(AParameters));
end;


function TLuaFunction.Call(AParameters: ILuaReadParameters): ILuaReadParameters;
begin
  TLuaHelpers.PushString(State, RegistryKey);
  lua_rawget(State, LUA_REGISTRYINDEX);

  Result := TLuaHelpers.CallFunction(State, AParameters);
end;

end.
