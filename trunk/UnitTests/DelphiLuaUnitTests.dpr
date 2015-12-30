program DelphiLuaUnitTests;

uses
  Forms,
  DUnitTestRunner,
  TestAPI in 'source\TestAPI.pas',
  Lua in '..\Lua.pas',
  Lua.Wrapper in '..\Lua.Wrapper.pas',
  TestWrapper in 'source\TestWrapper.pas';

{$R *.RES}

begin
  ReportMemoryLeaksOnShutdown := True;

  Application.Title := 'DelphiLua Unit Tests';
  DUnitTestRunner.RunRegisteredTests;
end.

