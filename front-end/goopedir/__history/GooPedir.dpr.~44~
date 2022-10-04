program GooPedir;

uses
  System.StartUpCopy,
  FMX.Forms,
  uProduto in 'uProduto.pas' {frmProduto},
  uDM in 'uDM.pas' {DM: TDataModule},
  uExtra in 'uExtra.pas' {frmExtra},
  util in 'util.pas',
  FMX.Toast.Frame in 'outros\toast\FMX.Toast.Frame.pas' {FrameToast: TFrame},
  FMX.Toast in 'outros\toast\FMX.Toast.pas',
  FMX.Toast.Types in 'outros\toast\FMX.Toast.Types.pas',
  uSimNao in 'outros\simnao\uSimNao.pas' {frmSimNao},
  util.funcoes in 'util.funcoes.pas',
  uFrmClonePadrao in 'outros\uFrmClonePadrao.pas' {frmPadrao},
  uPedido in 'outros\uPedido.pas' {frmPedido},
  uFiltroPadrao in 'outros\uFiltroPadrao.pas' {frmFiltroPadrao},
  uComboboxLocal in 'outros\uComboboxLocal.pas',
  uMain in 'uMain.pas' {frmMain},
  uCadastroPadrao in 'outros\uCadastroPadrao.pas' {frmCadastroBase},
  uCategoria in 'cadastro\uCategoria.pas' {frmCategoria},
  uTaxaEntrega in 'cadastro\uTaxaEntrega.pas' {frmTaxaEntrega},
  uFuncoes in 'util\uFuncoes.pas',
  uMotoboy in 'cadastro\uMotoboy.pas' {frmMotoboy},
  uFazPedido in 'uFazPedido.pas' {frmFazPedido},
  uDashBoard in 'outros\uDashBoard.pas' {frmDashBoard},
  uMesas in 'uMesas.pas' {frmMesas},
  Funcoes in 'comanda\Funcoes.pas',
  uFechamentoPedido in 'comanda\uFechamentoPedido.pas' {frmFechamentoPedido},
  UnitAddItem in 'comanda\UnitAddItem.pas' {FrmAddItem},
  UnitLogin in 'comanda\UnitLogin.pas' {FrmLogin},
  UnitPrincipal in 'comanda\UnitPrincipal.pas' {FrmPrincipal},
  UnitResumo in 'comanda\UnitResumo.pas' {FrmResumo},
  uTransferencia in 'comanda\uTransferencia.pas' {frmTransferenciaItem},
  Loading in 'comanda\Loading.pas',
  uLoginWindows in 'uLoginWindows.pas',
  uRequisicao {frmLoginWindows},
  uCadastroMesas in 'cadastro\uCadastroMesas.pas' {frmCadastroMesas},
  uSenha in 'outros\uSenha.pas' {frmSenha},
  uPedidoAdicionaAlterar in 'uPedidoAdicionaAlterar.pas' {frmCadastroBase1},
  uCaixa in 'uCaixa.pas' {frmCaixa},
  uPrincipalMotoboy in 'uPrincipalMotoboy.pas' {frmPrincipalMotoboy},
//  uOpenViewUrl in '..\..\papaleguas-backend\src\util\uOpenViewUrl.pas',
  uFrameConfiguracaoEdit in 'frame\uFrameConfiguracaoEdit.pas' {FrameConfiguracaoEdit: TFrame},
  ufrmParametros in 'ufrmParametros.pas' {frmParametros},
  uFrameTitulo in 'frame\uFrameTitulo.pas' {FrameTitulo: TFrame},
  uframeSelecao in 'frame\uframeSelecao.pas' {frameSelecao: TFrame},
  cFrameCombo in 'cFrameCombo.pas' {FrameCombo: TFrame},
  uFrameBotao in 'frame\uFrameBotao.pas' {FrameBotao: TFrame},
  uframeMensagemWhatsapp in 'frame\uframeMensagemWhatsapp.pas' {frameMensagemWhatsapp: TFrame},
  uframeCategorias in 'frame\uframeCategorias.pas' {frameCategorias: TFrame},
  uFrameProdutos in 'frame\uFrameProdutos.pas' {FrameProdutos: TFrame},
  uImpressora in 'cadastro\uImpressora.pas' {frmImpressora},
  uFrameDescricaoAdicional in 'frame\uFrameDescricaoAdicional.pas' {FrameDescricaoAdicional: TFrame},
  uframeExtra in 'frame\uframeExtra.pas' {frameExtra: TFrame},
  uframeObservacaoPedido in 'frame\uframeObservacaoPedido.pas' {frameObservacaoPedido: TFrame},
  uframeExtraAdd in 'frame\uframeExtraAdd.pas' {frameExtraAdd: TFrame},
  uExtraItem in 'uExtraItem.pas' {frmExtraItem},
  uframeExtraItensAdd in 'frame\uframeExtraItensAdd.pas' {frameExtraItensAdd: TFrame},
  uframeSabores in 'frame\uframeSabores.pas' {frameSabores: TFrame},
  ufrmRelatorioVendas in 'ufrmRelatorioVendas.pas' {frmRelatorioVendas},
  uframeBalaoValores in 'frame\uframeBalaoValores.pas' {frameBalaoValores: TFrame},
  uSuperChartLight in 'util\uSuperChartLight.pas',
  uframeFaturas in 'frame\uframeFaturas.pas' {frameFaturas: TFrame},
  OpenViewUrl in 'OpenViewUrl.pas',
  uLoginNovo in 'uLoginNovo.pas' {FrmLoginNovo},
  uTipoPagamento in 'uTipoPagamento.pas' {frmTipoPagamento},
  uCliente in 'uCliente.pas' {frmCliente},
  uAReceber in 'uAReceber.pas' {frmAReceber},
  uFrameListaPedido in 'frame\uFrameListaPedido.pas' {frmListaPedido: TFrame},
  uCupom in 'uCupom.pas' {frmCupom},
  uframeDadosItens in 'uframeDadosItens.pas' {frameDadosItens: TFrame};

{$R *.res}

var
  TipoVersao: Integer;
  Login: Boolean;
  Usuario: String;
  Senha: String;
  URL: String;

begin
  Application.Initialize;
  Application.CreateForm(TDM, DM);
  TipoVersao :=1;
{$IFDEF Android}
  TipoVersao := 2;
{$ELSE}
{$ENDIF}
  case TipoVersao of
    1:
      begin
        // Windows
        FrmLoginNovo := TFrmLoginNovo.Create(Application);
        try
          FrmLoginNovo.ShowModal;
        finally
          Login := FrmLoginNovo.Logado;
          Usuario := FrmLoginNovo.edtUsuario.Text;
          Senha := FrmLoginNovo.edtSenha.Text;
          URL := DM.GetHost;

          FrmLoginNovo.Free;
        end;

        {
          frmLoginWindows := TfrmLoginWindows.Create(Application);

          try
          frmLoginWindows.ShowModal;
          finally
          Login := frmLoginWindows.Logado;
          Usuario := frmLoginWindows.edtUsuario.Text;
          Senha := frmLoginWindows.edtSenha.Text;
          URL := DM.GetHost;
          FrmLogin.Free;

          frmLoginWindows.Free;
          end; }

        Application.CreateForm(TfrmMain, frmMain);
      end;
    2:
      begin
        // Mobile

        Application.CreateForm(TFrmLogin, FrmLogin);
        Login := True;
      end
  else
    begin
      // Windows
      Application.CreateForm(TfrmMain, frmMain);
    end;
  end;

  Application.CreateForm(TfrmSimNao, frmSimNao);
  if Login then
  begin
    Application.Run;

  end
  else
  begin
    Application.Terminate;
  end;

end.
