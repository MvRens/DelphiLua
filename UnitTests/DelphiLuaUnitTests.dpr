program DelphiLuaUnitTests;

uses
  Forms,
  DUnitTestRunner,
  TestAPI in 'source\TestAPI.pas',
  Lua.API in '..\Lua.API.pas',
  Lua in '..\Lua.pas',
  TestWrapper in 'source\TestWrapper.pas';

{$R *.RES}

begin
  ReportMemoryLeaksOnShutdown := True;

  Application.Title := 'DelphiLua Unit Tests';
  DUnitTestRunner.RunRegisteredTests;
end.

