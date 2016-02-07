{
  Header for Lua 5.2.1 Binaries DLL
    http://luabinaries.sourceforge.net/

  Delphi conversion by M. van Renswoude, April 2014:

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
unit Lua.API;

interface
uses
  System.SysUtils;


const
  LUA_VERSION_MAJOR   = '5';
  LUA_VERSION_MINOR	  = '2';
  LUA_VERSION_NUM	    = 502;
  LUA_VERSION_RELEASE = '1';

  LUA_VERSION_  = 'Lua ' + LUA_VERSION_MAJOR + '.' + LUA_VERSION_MINOR;
  LUA_RELEASE   = LUA_VERSION_ + '.' + LUA_VERSION_RELEASE;
  LUA_COPYRIGHT = LUA_RELEASE + '  Copyright (C) 1994-2012 Lua.org, PUC-Rio';
  LUA_AUTHORS   = 'R. Ierusalimschy, L. H. de Figueiredo, W. Celes';


  { mark for precompiled code ('<esc>Lua') }
  LUA_SIGNATURE	= #33'Lua';

  { option for multiple returns in 'lua_pcall' and 'lua_call' }
  LUA_MULTRET = -1;

  { reserve some space for error handling }
  LUAI_MAXSTACK	= 1000000;
  LUAI_FIRSTPSEUDOIDX	= (-LUAI_MAXSTACK - 1000);

  { pseudo-indices }
  LUA_REGISTRYINDEX = LUAI_FIRSTPSEUDOIDX;

  function lua_upvalueindex(idx: Integer): Integer; inline;

const
  { thread status }
  LUA_OK        = 0;
  LUA_YIELD_    = 1;
  LUA_ERRRUN	  = 2;
  LUA_ERRSYNTAX = 3;
  LUA_ERRMEM	  = 4;
  LUA_ERRGCMM	  = 5;
  LUA_ERRERR	  = 6;


type
  size_t = Cardinal;
  psize_t = ^size_t;

  lua_State = type Pointer;
  lua_CFunction = function(L: lua_State): Integer; cdecl;

  { functions that read/write blocks when loading/dumping Lua chunks }
  lua_Reader = function(L: lua_State; ud: Pointer; var sz: size_t): PAnsiChar; cdecl;
  lua_Writer = function(L: lua_State; p: Pointer; sz: size_t; ud: Pointer): Integer; cdecl;

  { prototype for memory-allocation functions }
  lua_Alloc = function(ud, ptr: Pointer; osize, nsize: size_t): Pointer; cdecl;

const
  { basic types }
  LUA_TNONE = (-1);

  LUA_TNIL = 0;
  LUA_TBOOLEAN = 1;
  LUA_TLIGHTUSERDATA = 2;
  LUA_TNUMBER = 3;
  LUA_TSTRING	= 4;
  LUA_TTABLE = 5;
  LUA_TFUNCTION = 6;
  LUA_TUSERDATA = 7;
  LUA_TTHREAD = 8;

  LUA_NUMTAGS = 9;

  { minimum Lua stack available to a C function }
  LUA_MINSTACK = 20;


  { predefined values in the registry }
  LUA_RIDX_MAINTHREAD = 1;
  LUA_RIDX_GLOBALS = 2;
  LUA_RIDX_LAST = LUA_RIDX_GLOBALS;


type
  { type of numbers in Lua }
  lua_Number = type Double;

  { type for integer functions }
  lua_Integer = type Integer;

  { unsigned integer type }
  lua_Unsigned = type Cardinal;


var
  { state manipulation }
  lua_newstate: function(f: lua_Alloc; ud: Pointer): lua_State; cdecl;
  lua_close: procedure(L: lua_State); cdecl;
  lua_newthread: function(L: lua_State): lua_State; cdecl;

  lua_atpanic: function(L: lua_State; panicf: lua_CFunction): lua_CFunction; cdecl;
  lua_version: function(L: lua_State): lua_Number; cdecl;

  { basic stack manipulation }
  lua_absindex: function(L: lua_State; idx: Integer): Integer; cdecl;
  lua_gettop: function(L: lua_State): Integer; cdecl;

  lua_settop: procedure(L: lua_State; idx: Integer); cdecl;
  lua_pushvalue: procedure(L: lua_State; idx: Integer); cdecl;
  lua_remove: procedure(L: lua_State; idx: Integer); cdecl;
  lua_insert: procedure(L: lua_State; idx: Integer); cdecl;
  lua_replace: procedure(L: lua_State; idx: Integer); cdecl;
  lua_copy: procedure(L: lua_State; fromidx, toidx: Integer); cdecl;
  lua_checkstack: function(L: lua_State; sz: Integer): Integer; cdecl;

  lua_xmove: procedure(from: lua_State; _to: lua_State; n: Integer); cdecl;

  { access functions (stack -> C) }
  lua_isnumber: function (L: lua_State; idx: Integer): Integer; cdecl;
  lua_isstring: function (L: lua_State; idx: Integer): Integer; cdecl;
  lua_iscfunction: function (L: lua_State; idx: Integer): Integer; cdecl;
  lua_isuserdata: function (L: lua_State; idx: Integer): Integer; cdecl;
  lua_type: function (L: lua_State; idx: Integer): Integer; cdecl;
  lua_typename: function (L: lua_State; tp: Integer): PAnsiChar; cdecl;
  lua_tonumberx: function (L: lua_State; idx: Integer; isnum: PInteger): lua_Number; cdecl;
  lua_tointegerx: function (L: lua_State; idx: Integer; isnum: PInteger): lua_Integer; cdecl;
  lua_tounsignedx: function (L: lua_State; idx: Integer; isnum: PInteger): lua_Unsigned; cdecl;
  lua_toboolean: function (L: lua_State; idx: Integer): Integer; cdecl;
  lua_tolstring: function(L: lua_State; idx: Integer; len: psize_t): PAnsiChar; cdecl;
  lua_rawlen: function (L: lua_State; idx: Integer): size_t; cdecl;
  lua_tocfunction: function (L: lua_State; idx: Integer): lua_CFunction; cdecl;
  lua_touserdata: function (L: lua_State; idx: Integer): Pointer; cdecl;
  lua_tothread: function (L: lua_State; idx: Integer): lua_State; cdecl;
  lua_topointer: function (L: lua_State; idx: Integer): Pointer; cdecl;


const
  { Comparison and arithmetic functions }
  LUA_OPADD = 0; { ORDER TM }
  LUA_OPSUB = 1;
  LUA_OPMUL = 2;
  LUA_OPDIV = 3;
  LUA_OPMOD = 4;
  LUA_OPPOW = 5;
  LUA_OPUNM = 6;


var
  lua_arith: procedure(L: lua_State; op: Integer); cdecl;


const
  LUA_OPEQ = 0;
  LUA_OPLT = 1;
  LUA_OPLE = 2;


var
  lua_rawequal: function(L: lua_State; idx1, idx2: Integer): Integer; cdecl;
  lua_compare: function(L: lua_State; idx1, idx2, op: Integer): Integer; cdecl;


  { push functions (C -> stack) }
  lua_pushnil: procedure(L: lua_State); cdecl;
  lua_pushnumber: procedure(L: lua_State; n: lua_Number); cdecl;
  lua_pushinteger: procedure(L: lua_State; n: lua_Integer); cdecl;
  lua_pushunsigned: procedure(L: lua_State; n: lua_Unsigned); cdecl;
  lua_pushlstring: function (L: lua_State; s: PAnsiChar; l_: size_t): PAnsiChar; cdecl;
  lua_pushstring: function (L: lua_State; s: PAnsiChar): PAnsiChar; cdecl;
  lua_pushvfstring: function (L: lua_State; fmt: PAnsiChar; argp: array of const): PAnsiChar; cdecl;
  lua_pushfstring: function (L: lua_State; fmt: PAnsiChar): PAnsiChar; cdecl;
  lua_pushcclosure: procedure(L: lua_State; fn: lua_CFunction; n: Integer); cdecl;
  lua_pushboolean: procedure(L: lua_State; b: Integer); cdecl;
  lua_pushlightuserdata: procedure(L: lua_State; p: Pointer); cdecl;
  lua_pushthread: function (L: lua_State): Integer; cdecl;

  { get functions (Lua -> stack) }
  lua_getglobal: procedure(L: lua_State; value: PAnsiChar); cdecl;
  lua_gettable: procedure(L: lua_State; idx: Integer); cdecl;
  lua_getfield: procedure(L: lua_State; idx: Integer; k: PAnsiChar); cdecl;
  lua_rawget: procedure(L: lua_State; idx: Integer); cdecl;
  lua_rawgeti: procedure(L: lua_State; idx, n: Integer); cdecl;
  lua_rawgetp: procedure(L: lua_State; idx: Integer; p: Pointer); cdecl;
  lua_createtable: procedure(L: lua_State; narr: Integer; nrec: Integer); cdecl;
  lua_newuserdata: procedure(L: lua_State; sz: size_t); cdecl;
  lua_getmetatable: function(L: lua_State; objindex: Integer): Integer; cdecl;
  lua_getuservalue: procedure(L: lua_State; idx: Integer); cdecl;

  { set functions (stack -> Lua) }
  lua_setglobal: procedure(L: lua_State; value: PAnsiChar); cdecl;
  lua_settable: procedure(L: lua_State; idx: Integer); cdecl;
  lua_setfield: procedure(L: lua_State; idx: Integer; k: PAnsiChar); cdecl;
  lua_rawset: procedure(L: lua_State; idx: Integer); cdecl;
  lua_rawseti: procedure(L: lua_State; idx, n: Integer); cdecl;
  lua_rawsetp: procedure(L: lua_State; idx: Integer; p: Pointer); cdecl;
  lua_setmetatable: function(L: lua_State; objindex: Integer): Integer; cdecl;
  lua_setuservalue: procedure(L: lua_State; idx: Integer); cdecl;


  { 'load' and 'call' functions (load and run Lua code) }
  lua_callk: procedure(L: lua_State; nargs, nresults, ctx: Integer; k: lua_CFunction); cdecl;
  lua_getctx: function(L: lua_State; var ctx: Integer): Integer; cdecl;
  lua_pcallk: function(L: lua_State; nargs, nresults, errfunc, ctx: Integer; k: lua_CFunction): Integer; cdecl;

  lua_load: function(L: lua_State; reader: lua_Reader; dt: Pointer; chunkname, mode: PAnsiChar): Integer; cdecl;
  lua_dump: function(L: lua_State; writer: lua_Writer; data: Pointer): Integer; cdecl;


  procedure lua_call(L: lua_State; nargs, nresults: Integer); inline;
  function lua_pcall(L: lua_State; nargs, nresults, errfunc: Integer): Integer; inline;


var
  { coroutine functions }
  lua_yieldk: function(L: lua_State; nresults, ctx: Integer; k: lua_CFunction): Integer; cdecl;
  lua_resume: function(L, from: lua_State; nargs: Integer): Integer; cdecl;
  lua_status: function(L: lua_State): Integer; cdecl;

  function lua_yield(L: lua_State; nresults: Integer): Integer; inline;


const
  { garbage-collection function and options }
  LUA_GCSTOP = 0;
  LUA_GCRESTART = 1;
  LUA_GCCOLLECT = 2;
  LUA_GCCOUNT = 3;
  LUA_GCCOUNTB = 4;
  LUA_GCSTEP = 5;
  LUA_GCSETPAUSE = 6;
  LUA_GCSETSTEPMU = 7;
  LUA_GCSETMAJORIN = 8;
  LUA_GCISRUNNING = 9;
  LUA_GCGEN = 0;
  LUA_GCINC = 1;

var
  lua_gc: function(L: lua_State; what, data: Integer): Integer; cdecl;


var
  { miscellaneous functions }
  lua_error: function(L: lua_State): Integer; cdecl;
  lua_next: function(L: lua_State; idx: Integer): Integer; cdecl;

  lua_concat: procedure(L: lua_State; n: Integer); cdecl;
  lua_len: procedure(L: lua_State; idx: Integer); cdecl;

  lua_getallocf: function(L: lua_State; ud: Pointer): lua_Alloc; cdecl;
  lua_setallocf: procedure(L: lua_State; f: lua_Alloc; ud: Pointer); cdecl;


  { some useful macros }
  function lua_tonumber(L: lua_State; idx: Integer): lua_Number; inline;
  function lua_tointeger(L: lua_State; idx: Integer): lua_Integer; inline;
  function lua_tounsigned(L: lua_State; idx: Integer): lua_Unsigned; inline;

  procedure lua_pop(L: lua_State; n: Integer); inline;
  procedure lua_newtable(L: lua_State); inline;
  procedure lua_register(L: lua_State; name: PAnsiChar; f: lua_CFunction); inline;
  procedure lua_pushcfunction(L: lua_State; f: lua_CFunction); inline;

  function lua_isfunction(L: lua_State; n: Integer): Boolean; inline;
  function lua_istable(L: lua_State; n: Integer): Boolean; inline;
  function lua_islightuserdata(L: lua_State; n: Integer): Boolean; inline;
  function lua_isnil(L: lua_State; n: Integer): Boolean; inline;
  function lua_isboolean(L: lua_State; n: Integer): Boolean; inline;
  function lua_isthread(L: lua_State; n: Integer): Boolean; inline;
  function lua_isnone(L: lua_State; n: Integer): Boolean; inline;
  function lua_isnoneornil(L: lua_State; n: Integer): Boolean; inline;
  function lua_pushliteral(L: lua_State; const s: AnsiString): PAnsiChar; inline;

  procedure lua_pushglobaltable(L: lua_State); inline;
  function lua_tostring(L: lua_State; idx: Integer): PAnsiChar; inline;


const
  {======================================================================
   Debug API
  =======================================================================}

  { Event codes }
  LUA_HOOKCALL  = 0;
  LUA_HOOKRET = 1;
  LUA_HOOKLINE  = 2;
  LUA_HOOKCOUNT = 3;
  LUA_HOOKTAILCALL = 4;


  { Event masks }
  LUA_MASKCALL = (1 shl LUA_HOOKCALL);
  LUA_MASKRET = (1 shl LUA_HOOKRET);
  LUA_MASKLINE =  (1 shl LUA_HOOKLINE);
  LUA_MASKCOUNT = (1 shl LUA_HOOKCOUNT);


const
  LUA_IDSIZE = 60;


type
  lua_Debug = record
    event: Integer;
    name: PAnsiChar;
    namewhat: PAnsiChar; // 'global', 'local', 'field', 'method'
    what: PAnsiChar; // 'Lua', 'C', 'main', 'tail'
    source: PAnsiChar;
    currentline: Integer;
    linedefined: Integer;
    lastlinedefined: Integer;
    nups: Byte;
    nparams: Byte;
    isvararg: Byte;
    istailcall: Byte;
    short_src: array[0..LUA_IDSIZE - 1] of AnsiChar;
    //struct CallInfo *i_ci;  /* active function */
  end;

  { Functions to be called by the debugger in specific events }
  lua_Hook = procedure(L: lua_State; var ar: lua_Debug); cdecl;


var
  lua_getstack: function(L: lua_State; level: Integer; var ar: lua_Debug): Integer; cdecl;
  lua_getinfo: function(L: lua_State; what: PAnsiChar; var ar: lua_Debug): Integer; cdecl;

  lua_getlocal: function(L: lua_State; var ar: lua_Debug; n: Integer): PAnsiChar; cdecl;
  lua_setlocal: function(L: lua_State; var ar: lua_Debug; n: Integer): PAnsiChar; cdecl;
  lua_getupvalue: function(L: lua_State; funcindex, n: Integer): PAnsiChar; cdecl;
  lua_setupvalue: function(L: lua_State; funcindex, n: Integer): PAnsiChar; cdecl;

  lua_upvalueid: function(L: lua_State; fidx, n: Integer): Pointer; cdecl;
  lua_upvaluejoin: procedure(L: lua_State; fidx1, n1, fidx2, n2: Integer);

  lua_sethook: function(L: lua_State; func: lua_Hook; mask, count: Integer): Integer; cdecl;
  lua_gethook: function(L: lua_State): lua_Hook; cdecl;
  lua_gethookmask: function(L: lua_State): Integer; cdecl;
  lua_gethookcount: function(L: lua_State): Integer; cdecl;

  {====================================================================== }


const
  LUA_COLIBNAME = 'coroutine';
  LUA_TABLIBNAME = 'table';
  LUA_IOLIBNAME = 'io';
  LUA_OSLIBNAME = 'os';
  LUA_STRLIBNAME = 'string';
  LUA_BITLIBNAME = 'bit32';
  LUA_MATHLIBNAME = 'math';
  LUA_DBLIBNAME = 'debug';
  LUA_LOADLIBNAME = 'package';


var
  { lualib }
  luaopen_base: function(L: lua_State): Integer; cdecl;
  luaopen_coroutine: function(L: lua_State): Integer; cdecl;
  luaopen_table: function(L: lua_State): Integer; cdecl;
  luaopen_io: function(L: lua_State): Integer; cdecl;
  luaopen_os: function(L: lua_State): Integer; cdecl;
  luaopen_string: function(L: lua_State): Integer; cdecl;
  luaopen_bit32: function(L: lua_State): Integer; cdecl;
  luaopen_math: function(L: lua_State): Integer; cdecl;
  luaopen_debug: function(L: lua_State): Integer; cdecl;
  luaopen_package: function(L: lua_State): Integer; cdecl;

  { open all previous libraries }
  luaL_openlibs: procedure(L: lua_State); cdecl;
  luaL_requiref: procedure(L: lua_State; modname: PAnsiChar; openf: lua_CFunction; glb: Integer); cdecl;



type
  luaL_Reg = record
    name: PAnsiChar;
    func: lua_CFunction;
  end;
  PluaL_Reg = ^luaL_Reg;

var
  luaL_setfuncs: procedure(L: lua_State; luaL_Reg: PluaL_Reg; nup: Integer); cdecl;


const
  DefaultLuaLibName = 'lua' + LUA_VERSION_MAJOR + LUA_VERSION_MINOR + '.dll';

  procedure LoadLuaLib(const AFileName: string = DefaultLuaLibName);
  procedure UnloadLuaLib;

  function LuaLibLoaded: Boolean;

  function DefaultLuaAlloc(ud, ptr: Pointer; osize, nsize: size_t): Pointer; cdecl;


implementation
uses
  System.Generics.Collections,
  Winapi.Windows;

var
  LuaLibHandle: THandle;
  LuaFunctions: TList<PPointer>;


function DefaultLuaAlloc(ud, ptr: Pointer; osize, nsize: size_t): Pointer;
begin
  if (nsize = 0) then
  begin
    FreeMemory(ptr);
    Result := nil;
  end else
    Result := ReallocMemory(ptr, nsize);
end;


procedure LoadLuaLib(const AFileName: string = DefaultLuaLibName);

  procedure Load(var AVariable: Pointer; const AName: string);
  begin
    AVariable := GetProcAddress(LuaLibHandle, PChar(AName));
    LuaFunctions.Add(@AVariable);
  end;


begin
  UnloadLuaLib;

  LuaLibHandle := SafeLoadLibrary(AFileName);
  if LuaLibHandle = 0 then
    RaiseLastOSError;

  if not Assigned(LuaFunctions) then
    LuaFunctions := TList<PPointer>.Create();

  Load(@lua_newstate, 'lua_newstate');
  Load(@lua_close, 'lua_close');
  Load(@lua_newthread, 'lua_newthread');

  Load(@lua_atpanic, 'lua_atpanic');
  Load(@lua_version, 'lua_version');

  Load(@lua_absindex, 'lua_absindex');
  Load(@lua_gettop, 'lua_gettop');
  Load(@lua_settop, 'lua_settop');
  Load(@lua_pushvalue, 'lua_pushvalue');
  Load(@lua_remove, 'lua_remove');
  Load(@lua_insert, 'lua_insert');
  Load(@lua_replace, 'lua_replace');
  Load(@lua_copy, 'lua_copy');
  Load(@lua_checkstack, 'lua_checkstack');
  Load(@lua_xmove, 'lua_xmove');

  Load(@lua_isnumber, 'lua_isnumber');
  Load(@lua_isstring, 'lua_isstring');
  Load(@lua_iscfunction, 'lua_iscfunction');
  Load(@lua_isuserdata, 'lua_isuserdata');
  Load(@lua_type, 'lua_type');
  Load(@lua_typename, 'lua_typename');
  Load(@lua_tonumberx, 'lua_tonumberx');
  Load(@lua_tointegerx, 'lua_tointegerx');
  Load(@lua_tounsignedx, 'lua_tounsignedx');
  Load(@lua_toboolean, 'lua_toboolean');
  Load(@lua_tolstring, 'lua_tolstring');
  Load(@lua_rawlen, 'lua_rawlen');
  Load(@lua_tocfunction, 'lua_tocfunction');
  Load(@lua_touserdata, 'lua_touserdata');
  Load(@lua_tothread, 'lua_tothread');
  Load(@lua_topointer, 'lua_topointer');

  Load(@lua_arith, 'lua_arith');
  Load(@lua_rawequal, 'lua_rawequal');
  Load(@lua_compare, 'lua_compare');

  Load(@lua_pushnil, 'lua_pushnil');
  Load(@lua_pushnumber, 'lua_pushnumber');
  Load(@lua_pushinteger, 'lua_pushinteger');
  Load(@lua_pushunsigned, 'lua_pushunsigned');
  Load(@lua_pushlstring, 'lua_pushlstring');
  Load(@lua_pushstring, 'lua_pushstring');
  Load(@lua_pushvfstring, 'lua_pushvfstring');
  Load(@lua_pushfstring, 'lua_pushfstring');
  Load(@lua_pushcclosure, 'lua_pushcclosure');
  Load(@lua_pushboolean, 'lua_pushboolean');
  Load(@lua_pushlightuserdata, 'lua_pushlightuserdata');
  Load(@lua_pushthread, 'lua_pushthread');

  Load(@lua_getglobal, 'lua_getglobal');
  Load(@lua_gettable, 'lua_gettable');
  Load(@lua_getfield, 'lua_getfield');
  Load(@lua_rawget, 'lua_rawget');
  Load(@lua_rawgeti, 'lua_rawgeti');
  Load(@lua_rawgetp, 'lua_rawgetp');
  Load(@lua_newuserdata, 'lua_newuserdata');
  Load(@lua_getmetatable, 'lua_getmetatable');
  Load(@lua_getuservalue, 'lua_getuservalue');

  Load(@lua_createtable, 'lua_createtable');
  Load(@lua_setglobal, 'lua_setglobal');
  Load(@lua_settable, 'lua_settable');
  Load(@lua_setfield, 'lua_setfield');

  Load(@lua_rawset, 'lua_rawset');
  Load(@lua_rawseti, 'lua_rawseti');
  Load(@lua_rawsetp, 'lua_rawsetp');
  Load(@lua_setmetatable, 'lua_setmetatable');
  Load(@lua_setuservalue, 'lua_setuservalue');

  Load(@lua_callk, 'lua_callk');
  Load(@lua_getctx, 'lua_getctx');
  Load(@lua_pcallk, 'lua_pcallk');

  Load(@lua_yieldk, 'lua_yieldk');
  Load(@lua_resume, 'lua_resume');
  Load(@lua_status, 'lua_status');

  Load(@lua_gc, 'lua_gc');

  Load(@lua_load, 'lua_load');
  Load(@lua_dump, 'lua_dump');

  Load(@lua_error, 'lua_error');
  Load(@lua_next, 'lua_next');

  Load(@lua_concat, 'lua_concat');
  Load(@lua_len, 'lua_len');

  Load(@lua_getallocf, 'lua_getallocf');
  Load(@lua_setallocf, 'lua_setallocf');


  Load(@lua_getstack, 'lua_getstack');
  Load(@lua_getinfo, 'lua_getinfo');

  Load(@lua_getlocal, 'lua_getlocal');
  Load(@lua_setlocal, 'lua_setlocal');
  Load(@lua_getupvalue, 'lua_getupvalue');
  Load(@lua_setupvalue, 'lua_setupvalue');

  Load(@lua_upvalueid, 'lua_upvalueid');
  Load(@lua_upvaluejoin, 'lua_upvaluejoin');

  Load(@lua_sethook, 'lua_sethook');
  Load(@lua_gethook, 'lua_gethook');
  Load(@lua_gethookmask, 'lua_gethookmask');
  Load(@lua_gethookcount, 'lua_gethookcount');

  Load(@luaopen_base, 'luaopen_base');
  Load(@luaopen_coroutine, 'luaopen_coroutine');
  Load(@luaopen_table, 'luaopen_table');
  Load(@luaopen_io, 'luaopen_io');
  Load(@luaopen_os, 'luaopen_os');
  Load(@luaopen_string, 'luaopen_string');
  Load(@luaopen_bit32, 'luaopen_bit32');
  Load(@luaopen_math, 'luaopen_math');
  Load(@luaopen_debug, 'luaopen_debug');
  Load(@luaopen_package, 'luaopen_package');

  Load(@luaL_openlibs, 'luaL_openlibs');
  Load(@luaL_requiref, 'luaL_requiref');

  Load(@luaL_setfuncs, 'luaL_setfuncs');
end;


procedure UnloadLuaLib;
var
  variable: PPointer;

begin
  if Assigned(LuaFunctions) then
  begin
    for variable in LuaFunctions do
      variable^ := nil;
  end;

  if LuaLibLoaded then
  begin
    FreeLibrary(LuaLibHandle);
    LuaLibHandle := 0;
  end;
end;


function LuaLibLoaded: Boolean;
begin
  Result := (LuaLibHandle <> 0);
end;


{ Macros }
function lua_upvalueindex(idx: Integer): Integer;
begin
  Result := (LUA_REGISTRYINDEX - idx);
end;

procedure lua_call(L: lua_State; nargs, nresults: Integer);
begin
  lua_callk(L, nargs, nresults, 0, nil);
end;

function lua_pcall(L: lua_State; nargs, nresults, errfunc: Integer): Integer;
begin
  Result := lua_pcallk(L, nargs, nresults, errfunc, 0, nil);
end;

function lua_yield(L: lua_State; nresults: Integer): Integer;
begin
  Result := lua_yieldk(L, nresults, 0, nil);
end;

function lua_tonumber(L: lua_State; idx: Integer): lua_Number;
begin
  Result := lua_tonumberx(L, idx, nil);
end;

function lua_tointeger(L: lua_State; idx: Integer): lua_Integer;
begin
  Result := lua_tointegerx(L, idx, nil);
end;

function lua_tounsigned(L: lua_State; idx: Integer): lua_Unsigned;
begin
  Result := lua_tounsignedx(L, idx, nil);
end;

procedure lua_pop(L: lua_State; n: Integer);
begin
  lua_settop(L, -(n) - 1);
end;

procedure lua_newtable(L: lua_State); inline;
begin
  lua_createtable(L, 0, 0);
end;

procedure lua_register(L: lua_State; name: PAnsiChar; f: lua_CFunction); inline;
begin
  lua_pushcfunction(L, f);
  lua_setglobal(L, name);
end;

procedure lua_pushcfunction(L: lua_State; f: lua_CFunction);
begin
  lua_pushcclosure(L, f, 0);
end;

function lua_isfunction(L: lua_State; n: Integer): Boolean;
begin
  Result := lua_type(L, n) = LUA_TFUNCTION;
end;

function lua_istable(L: lua_State; n: Integer): Boolean;
begin
  Result := lua_type(L, n) = LUA_TTABLE;
end;

function lua_islightuserdata(L: lua_State; n: Integer): Boolean;
begin
  Result := lua_type(L, n) = LUA_TLIGHTUSERDATA;
end;

function lua_isnil(L: lua_State; n: Integer): Boolean;
begin
  Result := lua_type(L, n) = LUA_TNIL;
end;

function lua_isboolean(L: lua_State; n: Integer): Boolean;
begin
  Result := lua_type(L, n) = LUA_TBOOLEAN;
end;

function lua_isthread(L: lua_State; n: Integer): Boolean;
begin
  Result := lua_type(L, n) = LUA_TTHREAD;
end;

function lua_isnone(L: lua_State; n: Integer): Boolean;
begin
  Result := lua_type(L, n) = LUA_TNONE;
end;

function lua_isnoneornil(L: lua_State; n: Integer): Boolean;
begin
  Result := lua_type(L, n) <= 0;
end;

function lua_pushliteral(L: lua_State; const s: AnsiString): PAnsiChar;
begin
  Result := lua_pushlstring(L, PAnsiChar(s), Length(s));
end;

procedure lua_pushglobaltable(L: lua_State);
begin
  lua_rawgeti(L, LUA_REGISTRYINDEX, LUA_RIDX_GLOBALS);
end;

function lua_tostring(L: lua_State; idx: Integer): PAnsiChar;
begin
  Result := lua_tolstring(L, idx, nil);
end;


initialization
finalization
  UnloadLuaLib;
  FreeAndNil(LuaFunctions);

end.
