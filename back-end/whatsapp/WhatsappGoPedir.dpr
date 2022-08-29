program WhatsappGoPedir;

uses
  Vcl.Forms,
  uTInject.ConfigCEF,
  uPrincipal in 'Uses\uPrincipal.pas' {dmPrincipal},
  uBotConversa in 'Uses\uBotConversa.pas',
  uBotGestor in 'Uses\uBotGestor.pas',
  uConversa in 'Uses\uConversa.pas',
  uClassPedido in 'Uses\uClassPedido.pas',
  uClassProduto in 'Uses\uClassProduto.pas',
  uClassEndereco in 'Uses\uClassEndereco.pas',
  uClassEnderecoUtil in 'Uses\uClassEnderecoUtil.pas',
  uDM in '..\papaleguas-frontend-whatsapp\Uses\uDM.pas' {dm: TDataModule},
  uClassFinalizarPedido in 'Uses\uClassFinalizarPedido.pas',
  uAlteracaoCancelamento in 'Uses\uAlteracaoCancelamento.pas',
  uClassPedidoRecente in 'Uses\uClassPedidoRecente.pas',
  Vcl.Themes,
  Vcl.Styles,
  uClassFuncoes in 'Uses\uClassFuncoes.pas',
  uClassAPIGooleLocalizacao in 'Uses\uClassAPIGooleLocalizacao.pas',
  uClassPizza in 'Uses\uClassPizza.pas',
  uFuncoes in '..\papaleguas-frontend-whatsapp\Uses\uFuncoes.pas',
  uClassEnviaMensagem in 'Uses\uClassEnviaMensagem.pas',
  uClassCronometro in 'Uses\uClassCronometro.pas',
  uClassThreeConversa in 'Uses\uClassThreeConversa.pas',
  uClassAdicionais in 'Uses\uClassAdicionais.pas',
  udmProdutos in 'Uses\udmProdutos.pas' {dmProdutos: TDataModule},
  uBackup in 'Uses\uBackup.pas',
  Dialogs,
  uGravaConversaMemoria in 'Uses\uGravaConversaMemoria.pas';

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
