program DelphiLuaUnitTests;

uses
  DUnitTestRunner,
  TestAPI in 'source\TestAPI.pas',
  Lua in '..\Lua.pas',
  Lua.Wrapper in '..\Lua.Wrapper.pas',
  TestWrapper in 'source\TestWrapper.pas';

{$R *.RES}

begin
  DUnitTestRunner.RunRegisteredTests;
end.

