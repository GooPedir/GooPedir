unit uBackup;

interface

uses uBotConversa, SysUtils;

type

  TBackup = class
  public
    function Backup(Conversa: TBotConversa): boolean;
  end;

implementation

{ TBackup }

uses uPrincipal;

function TBackup.Backup(Conversa: TBotConversa): boolean;
var
  mensagem: String;
begin
  //Meu Pessoal
  if Conversa.Telefone <> '4898111156' then
  begin
  //Suporte
    if Conversa.Telefone <> '4898153342' then
    begin
    Result := false;
    exit;
    end;
  end;

  // !comandos
  if UpperCase(Conversa.Resposta) = '!COMANDOS' then
  begin
    mensagem := '*--- COMANDOS ---*' + MENSAGEM_QUEBRA_LINHA_DUPLA;
    mensagem := mensagem + '*!VersaoLocal* ' + MONO_ESPACADA +
      ' versão do sistema' + MONO_ESPACADA + MENSAGEM_QUEBRA_LINHA;
    mensagem := mensagem + '*!VersaoFTP* ' + MONO_ESPACADA +
      ' versão do servidor' + MONO_ESPACADA + MENSAGEM_QUEBRA_LINHA;
    mensagem := mensagem + '*!Atualizar* ' + MONO_ESPACADA +
      ' atualiza o sistema' + MONO_ESPACADA + MENSAGEM_QUEBRA_LINHA;
    mensagem := mensagem + '*!Reiniciar* ' + MONO_ESPACADA +
      ' reinicia o whatsapp' + MONO_ESPACADA + MENSAGEM_QUEBRA_LINHA;
    mensagem := mensagem + '*!Sair* ' + MONO_ESPACADA + ' sai dos comandos' +
      MONO_ESPACADA + MENSAGEM_QUEBRA_LINHA;

  end
  else if UpperCase(Conversa.Resposta) = '!VERSAOLOCAL' then
  begin
//    mensagem := '*--- COMANDOS ---*' + MENSAGEM_QUEBRA_LINHA_DUPLA;
//    mensagem := mensagem + '*' +
//      IntToStr(dmPrincipal.Atualizador.getLocalVersion) + '* ' + MONO_ESPACADA +
//      ' versão local' + MONO_ESPACADA;
  end
  else if UpperCase(Conversa.Resposta) = '!VERSAOFTP' then
  begin
//    mensagem := '*--- COMANDOS ---*' + MENSAGEM_QUEBRA_LINHA_DUPLA;
//    mensagem := mensagem + '*' +
//      IntToStr(dmPrincipal.Atualizador.getRemoteVersion) + '* ' + MONO_ESPACADA
//      + ' versão servidor' + MONO_ESPACADA;
  end
  else if UpperCase(Conversa.Resposta) = '!ATUALIZAR' then
  begin
//    mensagem := '*--- COMANDOS ---*' + MENSAGEM_QUEBRA_LINHA_DUPLA;
//    mensagem := mensagem + '*Inicio da atualização ' +
//      FormatDateTime('dd/mm hh:mm', now) + '*';
//    dmPrincipal.Atualizador.Upgrade;
  end
  else if UpperCase(Conversa.Resposta) = '!REINICIAR' then
  begin
    mensagem := '*--- COMANDOS ---*' + MENSAGEM_QUEBRA_LINHA_DUPLA;
    mensagem := mensagem + '*Sistema ira reiniciar em 5s*';
  end
  else if UpperCase(Conversa.Resposta) = '!SAIR' then
  begin
    Result := false;
    exit;
  end;
  if mensagem <> '' then
  begin
    dmPrincipal.Enviamensagem(Conversa, mensagem);
    Result := True;
    exit;
  end;
  Result := false;
end;

end.
