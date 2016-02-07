# DelphiLua
*definitely not the most creative project name*

This project consists of two parts: a straight-up conversion of the [LuaBinaries](http://luabinaries.sourceforge.net/) 5.2 C headers to Delphi, and the TLua class to make integrating Lua with Delphi projects easier.

##### A note on compatibility
It's been tested and developed on Delphi XE2 32-bits. Minimum version for the wrapper is probably 2010, due to anonymous functions and TRttiContext being used. I also know for sure that the code isn't 64-bits compatible yet.


### Getting started
If you're just interested in the API, the [Lua manual](http://www.lua.org/manual/5.2/manual.html#4) is the best place to start.

For the wrapper, take a look at the unit tests in TestWrapper.pas. Be sure to copy Lua52.dll into the output path if you're gonna run the unit tests or your own project.


##### A very, very simple example
Load a script from a string, passing two variables A and B and having the script sum them up into variable C.

```delphi
var
  lua: TLua;
  returnValue: Integer;

begin
  lua := TLua.Create;
  try
    lua.SetGlobalVariable('A', 5);
    lua.SetGlobalVariable('B', 10);

    lua.LoadFromString('C = A + B');

    returnValue := lua.GetGlobalVariable('C').AsInteger;
  finally
    FreeAndNil(lua);
  end;
end;
```

...of course, you can do much more exciting things like calling Delphi functions from Lua or vice versa. Check out the Call and RegisterFunction(s) methods. Have fun!