program DelphiLuaInteractiveTests;

uses
  Vcl.Forms,
  MainFrm in 'MainFrm.pas' {MainForm},
  Lua.API in '..\Lua.API.pas',
  Lua in '..\Lua.pas';

{$R *.res}

var
  MainForm: TMainForm;

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
