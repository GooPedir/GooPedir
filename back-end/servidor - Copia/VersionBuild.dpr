program VersionBuild;

{$APPTYPE CONSOLE}

uses
  SysUtils, Classes, XMLDoc, XMLIntf;

var
  FileName: string;
  XMLDoc: IXMLDocument;
  RootNode, VersionNode: IXMLNode;
  Major, Minor, Release, Build: Integer;
  VersionStr: string;
  Parts: TArray<string>;
  MajorStr, MinorStr, ReleaseStr, BuildStr: string;

begin
  FileName := 'C:\\Projetos\\GooPedir\\GooPedir\\back-end\\servidor\\ServidorGooPedir.dproj';  // Nome do seu arquivo de projeto

  XMLDoc := TXMLDocument.Create(nil);
  try
    // Verificar se o arquivo existe
    if not FileExists(FileName) then
    begin
      Writeln('Arquivo não encontrado: ', FileName);
      Exit;
    end;

    XMLDoc.LoadFromFile(FileName);
    XMLDoc.Active := True;

    // Acessar o nó raiz
    RootNode := XMLDoc.DocumentElement;

    // Encontrar o nó de versão
    VersionNode := RootNode.ChildNodes.FindNode('VersionInfo');
    if Assigned(VersionNode) then
    begin
      // Obter a versão atual
      VersionStr := VersionNode.Attributes['Version'];
      if VersionStr <> '' then
      begin
        // Dividir a versão em partes
        Parts := VersionStr.Split(['.']);
        if Length(Parts) = 4 then
        begin
          MajorStr := Parts[0];
          MinorStr := Parts[1];
          ReleaseStr := Parts[2];
          BuildStr := Parts[3];

          if TryStrToInt(MajorStr, Major) and TryStrToInt(MinorStr, Minor) and
             TryStrToInt(ReleaseStr, Release) and TryStrToInt(BuildStr, Build) then
          begin
            // Incrementar a versão
            Inc(Build);  // Incrementa o número da build
            if Build > 9999 then  // Limite máximo para o número da build
            begin
              Build := 0;
              Inc(Release);
              if Release > 9999 then
              begin
                Release := 0;
                Inc(Minor);
                if Minor > 9999 then
                begin
                  Minor := 0;
                  Inc(Major);
                end;
              end;
            end;

            // Atualizar a versão
            VersionStr := Format('%d.%d.%d.%d', [Major, Minor, Release, Build]);
            VersionNode.Attributes['Version'] := VersionStr;

            // Salvar as alterações
            XMLDoc.SaveToFile(FileName);
          end
          else
            Writeln('Erro ao converter versão para números.');
        end
        else
          Writeln('Formato da versão inesperado.');
      end
      else
        Writeln('Versão não encontrada no arquivo.');
    end
    else
      Writeln('No VersionInfo node found in the file.');
  except
    on E: Exception do
    begin
      Writeln('Erro: ' + E.Message);
    end;
  end;
  Readln;
end.

