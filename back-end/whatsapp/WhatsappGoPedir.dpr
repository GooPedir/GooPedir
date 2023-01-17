program WhatsappGoPedir;

uses
  Vcl.Forms,
  Vcl.Themes,
  Vcl.Styles,
  Dialogs,
  uTInject.ConfigCEF,
  uPrincipal in 'Uses\uPrincipal.pas' {dmPrincipal},
  uBotConversa in 'Uses\uBotConversa.pas',
  uBotGestor in 'Uses\uBotGestor.pas',
  uConversa in 'Uses\uConversa.pas',
  uClassPedido in 'Uses\uClassPedido.pas',
  uClassProduto in 'Uses\uClassProduto.pas',
  uClassEndereco in 'Uses\uClassEndereco.pas',
  uClassEnderecoUtil in 'Uses\uClassEnderecoUtil.pas',
  uDM in 'Uses\uDM.pas' {dm: TDataModule},
  uClassFinalizarPedido in 'Uses\uClassFinalizarPedido.pas',
  uAlteracaoCancelamento in 'Uses\uAlteracaoCancelamento.pas',
  uClassPedidoRecente in 'Uses\uClassPedidoRecente.pas',
  uClassFuncoes in 'Uses\uClassFuncoes.pas',
  uClassAPIGooleLocalizacao in 'Uses\uClassAPIGooleLocalizacao.pas',
  uClassPizza in 'Uses\uClassPizza.pas',
  uClassEnviaMensagem in 'Uses\uClassEnviaMensagem.pas',
  uClassCronometro in 'Uses\uClassCronometro.pas',
  uClassThreeConversa in 'Uses\uClassThreeConversa.pas',
  uClassAdicionais in 'Uses\uClassAdicionais.pas',
  udmProdutos in 'Uses\udmProdutos.pas' {dmProdutos: TDataModule},
  uBackup in 'Uses\uBackup.pas' {,
  uFuncoes in 'Uses\uFuncoes.pas',
  uGravaConversaMemoria in 'Uses\uGravaConversaMemoria.pas'},
  uGravaConversaMemoria in 'Uses\uGravaConversaMemoria.pas',
  XSuperJSON in 'Uses\Superobject\XSuperJSON.pas',
  XSuperObject in 'Uses\Superobject\XSuperObject.pas';

{$R *.res}

begin

  If not GlobalCEFApp.StartMainProcess then
    exit;

  Application.Initialize;
  Application.MainFormOnTaskbar := True;

   TStyleManager.TrySetStyle('Windows10 Dark');
  Application.CreateForm(Tdm, dm);
  //  Application.CreateForm(TdmProdutos, dmProdutos);
  Application.CreateForm(TdmPrincipal, dmPrincipal);


  Application.Title := 'PapaLéguas Food';
  Application.Run;

end.
