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
unit Lua;

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
  LUA_YIELD	    = 1;
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


  (*
  /*
  ** Comparison and arithmetic functions
  */

  #define LUA_OPADD	0	/* ORDER TM */
  #define LUA_OPSUB	1
  #define LUA_OPMUL	2
  #define LUA_OPDIV	3
  #define LUA_OPMOD	4
  #define LUA_OPPOW	5
  #define LUA_OPUNM	6

  LUA_API void  (lua_arith) (lua_State *L, int op);

  #define LUA_OPEQ	0
  #define LUA_OPLT	1
  #define LUA_OPLE	2

  LUA_API int   (lua_rawequal) (lua_State *L, int idx1, int idx2);
  LUA_API int   (lua_compare) (lua_State *L, int idx1, int idx2, int op);
  *)

  { push functions (C -> stack) }
  lua_pushnil: procedure(L: lua_State); cdecl;
  lua_pushnumber: procedure(L: lua_State; n: lua_Number); cdecl;
  lua_pushinteger: procedure(L: lua_State; n: lua_Integer); cdecl;
  lua_pushunsigned: procedure(L: lua_State; n: lua_Unsigned); cdecl;
  lua_pushlstring: function (L: lua_State; s: PAnsiChar; l_: size_t): PAnsiChar; cdecl;
  lua_pushstring: function (L: lua_State; s: PAnsiChar): PAnsiChar; cdecl;
  lua_pushvfstring: function (L: lua_State; fmt: PAnsiChar; argp: array of const): PAnsiChar; cdecl;
  lua_pushfstring: function (L: lua_State; fmt: PAnsiChar): PAnsiChar; cdecl; {$IFDEF FPC}varargs;{$ENDIF}
  lua_pushcclosure: procedure(L: lua_State; fn: lua_CFunction; n: Integer); cdecl;
  lua_pushboolean: procedure(L: lua_State; b: Integer); cdecl;
  lua_pushlightuserdata: procedure(L: lua_State; p: Pointer); cdecl;
  lua_pushthread: function (L: lua_State): Integer; cdecl;

  { get functions (Lua -> stack) }
  lua_getglobal: procedure(L: lua_State; value: PAnsiChar); cdecl;
  (*
  LUA_API void  (lua_gettable) (lua_State *L, int idx);
  LUA_API void  (lua_getfield) (lua_State *L, int idx, const char *k);
  LUA_API void  (lua_rawget) (lua_State *L, int idx);
  *)
  lua_rawgeti: procedure(L: lua_State; idx, n: integer); cdecl;
  (*
  LUA_API void  (lua_rawgetp) (lua_State *L, int idx, const void *p);
  LUA_API void  (lua_createtable) (lua_State *L, int narr, int nrec);
  LUA_API void *(lua_newuserdata) (lua_State *L, size_t sz);
  LUA_API int   (lua_getmetatable) (lua_State *L, int objindex);
  LUA_API void  (lua_getuservalue) (lua_State *L, int idx);
  *)

  { set functions (stack -> Lua) }
  lua_setglobal: procedure(L: lua_State; value: PAnsiChar); cdecl;
  (*
  LUA_API void  (lua_settable) (lua_State *L, int idx);
  LUA_API void  (lua_setfield) (lua_State *L, int idx, const char *k);
  LUA_API void  (lua_rawset) (lua_State *L, int idx);
  LUA_API void  (lua_rawseti) (lua_State *L, int idx, int n);
  LUA_API void  (lua_rawsetp) (lua_State *L, int idx, const void *p);
  LUA_API int   (lua_setmetatable) (lua_State *L, int objindex);
  LUA_API void  (lua_setuservalue) (lua_State *L, int idx);
  *)


  { 'load' and 'call' functions (load and run Lua code) }
  lua_callk: procedure(L: lua_State; nargs, nresults, ctx: Integer; k: lua_CFunction); cdecl;
  lua_getctx: function(L: lua_State; var ctx: Integer): Integer; cdecl;
  lua_pcallk: function(L: lua_State; nargs, nresults, errfunc, ctx: Integer; k: lua_CFunction): Integer; cdecl;

  lua_load: function(L: lua_State; reader: lua_Reader; dt: Pointer; chunkname, mode: PAnsiChar): Integer; cdecl;
  lua_dump: function(L: lua_State; writer: lua_Writer; data: Pointer): Integer; cdecl;


  procedure lua_call(L: lua_State; nargs, nresults: Integer); inline;
  function lua_pcall(L: lua_State; nargs, nresults, errfunc: Integer): Integer; inline;


(*
  /*
  ** coroutine functions
  */
  LUA_API int  (lua_yieldk) (lua_State *L, int nresults, int ctx,
                             lua_CFunction k);
  #define lua_yield(L,n)		lua_yieldk(L, (n), 0, NULL)
  LUA_API int  (lua_resume) (lua_State *L, lua_State *from, int narg);
  LUA_API int  (lua_status) (lua_State *L);

  /*
  ** garbage-collection function and options
  */

  #define LUA_GCSTOP		0
  #define LUA_GCRESTART		1
  #define LUA_GCCOLLECT		2
  #define LUA_GCCOUNT		3
  #define LUA_GCCOUNTB		4
  #define LUA_GCSTEP		5
  #define LUA_GCSETPAUSE		6
  #define LUA_GCSETSTEPMUL	7
  #define LUA_GCSETMAJORINC	8
  #define LUA_GCISRUNNING		9
  #define LUA_GCGEN		10
  #define LUA_GCINC		11

  LUA_API int (lua_gc) (lua_State *L, int what, int data);


  /*
  ** miscellaneous functions
  */

  LUA_API int   (lua_error) (lua_State *L);

  LUA_API int   (lua_next) (lua_State *L, int idx);

  LUA_API void  (lua_concat) (lua_State *L, int n);
  LUA_API void  (lua_len)    (lua_State *L, int idx);

  LUA_API lua_Alloc (lua_getallocf) (lua_State *L, void **ud);
  LUA_API void      (lua_setallocf) (lua_State *L, lua_Alloc f, void *ud);
  *)


  { some useful macros }
  function lua_tonumber(L: lua_State; idx: Integer): lua_Number; inline;
  function lua_tointeger(L: lua_State; idx: Integer): lua_Integer; inline;
  function lua_tounsigned(L: lua_State; idx: Integer): lua_Unsigned; inline;

  (*
  #define lua_pop(L,n)		lua_settop(L, -(n)-1)

  #define lua_newtable(L)		lua_createtable(L, 0, 0)

  #define lua_register(L,n,f) (lua_pushcfunction(L, (f)), lua_setglobal(L, (n)))
  *)

  procedure lua_pushcfunction(L: lua_State; f: lua_CFunction); inline;

  (*
  #define lua_isfunction(L,n)	(lua_type(L, (n)) == LUA_TFUNCTION)
  #define lua_istable(L,n)	(lua_type(L, (n)) == LUA_TTABLE)
  #define lua_islightuserdata(L,n)	(lua_type(L, (n)) == LUA_TLIGHTUSERDATA)
  #define lua_isnil(L,n)		(lua_type(L, (n)) == LUA_TNIL)
  #define lua_isboolean(L,n)	(lua_type(L, (n)) == LUA_TBOOLEAN)
  #define lua_isthread(L,n)	(lua_type(L, (n)) == LUA_TTHREAD)
  #define lua_isnone(L,n)		(lua_type(L, (n)) == LUA_TNONE)
  #define lua_isnoneornil(L, n)	(lua_type(L, (n)) <= 0)

  #define lua_pushliteral(L, s)	\
    lua_pushlstring(L, "" s, (sizeof(s)/sizeof(char))-1)
    *)

  procedure lua_pushglobaltable(L: lua_State); inline;
  function lua_tostring(L: lua_State; idx: Integer): PAnsiChar; inline;

  (*



  /*
  ** {======================================================================
  ** Debug API
  ** =======================================================================
  */


  /*
  ** Event codes
  */
  #define LUA_HOOKCALL	0
  #define LUA_HOOKRET	1
  #define LUA_HOOKLINE	2
  #define LUA_HOOKCOUNT	3
  #define LUA_HOOKTAILCALL 4


  /*
  ** Event masks
  */
  #define LUA_MASKCALL	(1 << LUA_HOOKCALL)
  #define LUA_MASKRET	(1 << LUA_HOOKRET)
  #define LUA_MASKLINE	(1 << LUA_HOOKLINE)
  #define LUA_MASKCOUNT	(1 << LUA_HOOKCOUNT)


  /* Functions to be called by the debugger in specific events */
  typedef void (*lua_Hook) (lua_State *L, lua_Debug *ar);
  *)

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


var
  lua_getstack: function(L: lua_State; level: Integer; var ar: lua_Debug): Integer; cdecl;
  lua_getinfo: function(L: lua_State; what: PAnsiChar; var ar: lua_Debug): Integer; cdecl;

  (*
  LUA_API const char *(lua_getlocal) (lua_State *L, const lua_Debug *ar, int n);
  LUA_API const char *(lua_setlocal) (lua_State *L, const lua_Debug *ar, int n);
  LUA_API const char *(lua_getupvalue) (lua_State *L, int funcindex, int n);
  LUA_API const char *(lua_setupvalue) (lua_State *L, int funcindex, int n);

  LUA_API void *(lua_upvalueid) (lua_State *L, int fidx, int n);
  LUA_API void  (lua_upvaluejoin) (lua_State *L, int fidx1, int n1,
                                                 int fidx2, int n2);

  LUA_API int (lua_sethook) (lua_State *L, lua_Hook func, int mask, int count);
  LUA_API lua_Hook (lua_gethook) (lua_State *L);
  LUA_API int (lua_gethookmask) (lua_State *L);
  LUA_API int (lua_gethookcount) (lua_State *L);
  /* }====================================================================== */

  #endif
*)


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

  Load(@lua_rawgeti, 'lua_rawgeti');
  Load(@lua_setglobal, 'lua_setglobal');

  Load(@lua_callk, 'lua_callk');
  Load(@lua_getctx, 'lua_getctx');
  Load(@lua_pcallk, 'lua_pcallk');

  Load(@lua_load, 'lua_load');
  Load(@lua_dump, 'lua_dump');

  Load(@lua_getstack, 'lua_getstack');
  Load(@lua_getinfo, 'lua_getinfo');


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

procedure lua_pushcfunction(L: lua_State; f: lua_CFunction);
begin
  lua_pushcclosure(L, f, 0);
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
