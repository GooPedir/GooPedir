param(
    [Parameter(Mandatory = $true)]
    [string]$SourceDirectory,

    [Parameter(Mandatory = $true)]
    [string]$OutputZip,

    [string]$Product = "servidor",

    [string]$Channel = "production",

    [string]$Version = ""
)

$ErrorActionPreference = 'Stop'

# ============================================================
# CONFIGURACAO
# ============================================================

$IgnoredExtensions = @(
    ".map",
    ".drc"
)

# Arquivos que nunca devem ser copiados da origem.
# O manifest sera gerado novamente pelo proprio script.
$IgnoredFileNames = @(
    "manifest.json"
)

# ============================================================
# FUNCOES
# ============================================================

function Get-RelativePath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$BasePath,

        [Parameter(Mandatory = $true)]
        [string]$FullPath
    )

    $BasePath = [IO.Path]::GetFullPath($BasePath)
    $FullPath = [IO.Path]::GetFullPath($FullPath)

    if (-not $BasePath.EndsWith([IO.Path]::DirectorySeparatorChar)) {
        $BasePath += [IO.Path]::DirectorySeparatorChar
    }

    $BaseUri = New-Object System.Uri($BasePath)
    $FileUri = New-Object System.Uri($FullPath)

    $RelativeUri = $BaseUri.MakeRelativeUri($FileUri)

    return [Uri]::UnescapeDataString(
        $RelativeUri.ToString()
    ).Replace('/', '\')
}

function Convert-ToManifestPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    return $Path.Replace('\', '/')
}

function Should-IgnoreFile {
    param(
        [Parameter(Mandatory = $true)]
        [System.IO.FileInfo]$File
    )

    $Extension = $File.Extension.ToLowerInvariant()

    if ($IgnoredExtensions -contains $Extension) {
        return $true
    }

    if ($IgnoredFileNames -contains $File.Name.ToLowerInvariant()) {
        return $true
    }

    return $false
}

# ============================================================
# NORMALIZA CAMINHOS
# ============================================================

if (-not (Test-Path -LiteralPath $SourceDirectory)) {
    throw "Pasta de origem nao encontrada: $SourceDirectory"
}

$SourceDirectory = (
    Resolve-Path -LiteralPath $SourceDirectory
).Path

$OutputZip = [IO.Path]::GetFullPath($OutputZip)

$OutputDirectory = Split-Path -Parent $OutputZip

if ([string]::IsNullOrWhiteSpace($OutputDirectory)) {
    throw "Diretorio de saida invalido para o ZIP: $OutputZip"
}

if (-not (Test-Path -LiteralPath $OutputDirectory)) {
    New-Item `
        -ItemType Directory `
        -Force `
        -Path $OutputDirectory |
        Out-Null
}

# ============================================================
# STAGING
# ============================================================

$StageDirectory = Join-Path `
    ([IO.Path]::GetTempPath()) `
    ("goopedir-package-" + [Guid]::NewGuid().ToString("N"))

New-Item `
    -ItemType Directory `
    -Force `
    -Path $StageDirectory |
    Out-Null

try {

    Write-Host ""
    Write-Host "============================================================"
    Write-Host "  CRIANDO PACOTE"
    Write-Host "============================================================"
    Write-Host ""

    Write-Host "Origem:"
    Write-Host "  $SourceDirectory"
    Write-Host ""

    Write-Host "ZIP:"
    Write-Host "  $OutputZip"
    Write-Host ""

    # ========================================================
    # BUSCA ARQUIVOS
    # ========================================================

    $SourceFiles = @(
        Get-ChildItem `
            -LiteralPath $SourceDirectory `
            -File `
            -Recurse |
        Where-Object {
            -not (Should-IgnoreFile -File $_)
        }
    )

    if ($SourceFiles.Count -eq 0) {
        throw "Nenhum arquivo encontrado para gerar o pacote."
    }

    Write-Host "Arquivos encontrados: $($SourceFiles.Count)"
    Write-Host ""

    # ========================================================
    # COPIA PARA STAGING
    #
    # IMPORTANTE:
    #
    # A estrutura relativa a SourceDirectory e mantida.
    #
    # Exemplo:
    #
    # SourceDirectory
    # ├── ServidorGooPedir.exe
    # └── nginx
    #     └── html
    #         └── index.html
    #
    # vira:
    #
    # Stage
    # ├── ServidorGooPedir.exe
    # └── nginx
    #     └── html
    #         └── index.html
    #
    # ========================================================

    foreach ($SourceFile in $SourceFiles) {

        $RelativePath = Get-RelativePath `
            -BasePath $SourceDirectory `
            -FullPath $SourceFile.FullName

        $StageFile = Join-Path `
            $StageDirectory `
            $RelativePath

        $StageFileDirectory = Split-Path `
            -Parent `
            $StageFile

        if (-not (Test-Path -LiteralPath $StageFileDirectory)) {

            New-Item `
                -ItemType Directory `
                -Force `
                -Path $StageFileDirectory |
                Out-Null
        }

        Copy-Item `
            -LiteralPath $SourceFile.FullName `
            -Destination $StageFile `
            -Force

        Write-Host "  + $RelativePath"
    }

    # ========================================================
    # DESCOBRE VERSAO AUTOMATICAMENTE SE NAO FOI INFORMADA
    # ========================================================

    if ([string]::IsNullOrWhiteSpace($Version)) {

        $ServerExe = Join-Path `
            $StageDirectory `
            "ServidorGooPedir.exe"

        if (Test-Path -LiteralPath $ServerExe) {

            $DetectedVersion = (
                Get-Item -LiteralPath $ServerExe
            ).VersionInfo.FileVersion

            if (-not [string]::IsNullOrWhiteSpace($DetectedVersion)) {
                $Version = $DetectedVersion.Trim()
            }
        }
    }

    if ([string]::IsNullOrWhiteSpace($Version)) {
        $Version = "0.0.0.0"
    }

    Write-Host ""
    Write-Host "Produto:"
    Write-Host "  $Product"

    Write-Host ""
    Write-Host "Canal:"
    Write-Host "  $Channel"

    Write-Host ""
    Write-Host "Versao:"
    Write-Host "  $Version"
    Write-Host ""

    # ========================================================
    # GERA MANIFEST
    # ========================================================

    Write-Host "Gerando manifest.json..."
    Write-Host ""

    $ManifestFiles = @()

    $PackageFiles = @(
        Get-ChildItem `
            -LiteralPath $StageDirectory `
            -File `
            -Recurse
    )

    foreach ($PackageFile in $PackageFiles) {

        $RelativePath = Get-RelativePath `
            -BasePath $StageDirectory `
            -FullPath $PackageFile.FullName

        $ManifestPath = Convert-ToManifestPath `
            -Path $RelativePath

        $Hash = (
            Get-FileHash `
                -LiteralPath $PackageFile.FullName `
                -Algorithm SHA256
        ).Hash.ToLowerInvariant()

        $ManifestFiles += [ordered]@{
            source      = $ManifestPath
            destination = $ManifestPath
            sha256      = $Hash
            sizeBytes   = [Int64]$PackageFile.Length
        }
    }

    # Ordena por caminho para deixar o manifest previsivel
    $ManifestFiles = @(
        $ManifestFiles |
        Sort-Object source
    )

    $Manifest = [ordered]@{
        schemaVersion = 1
        product       = $Product
        channel       = $Channel
        version       = $Version
        generatedAt   = (Get-Date).ToUniversalTime().ToString("o")
        files         = $ManifestFiles
    }

    $ManifestPath = Join-Path `
        $StageDirectory `
        "manifest.json"

    $ManifestJson = $Manifest |
        ConvertTo-Json -Depth 10

    # UTF8 sem BOM para evitar problemas no parser
    $Utf8WithoutBom = New-Object System.Text.UTF8Encoding($false)

    [System.IO.File]::WriteAllText(
        $ManifestPath,
        $ManifestJson,
        $Utf8WithoutBom
    )

    Write-Host "Manifest criado:"
    Write-Host "  manifest.json"
    Write-Host ""

    Write-Host "Arquivos no manifest:"
    Write-Host "  $($ManifestFiles.Count)"
    Write-Host ""

    # ========================================================
    # REMOVE ZIP ANTIGO
    # ========================================================

    if (Test-Path -LiteralPath $OutputZip) {

        Write-Host "Removendo ZIP anterior..."
        Write-Host ""

        Remove-Item `
            -LiteralPath $OutputZip `
            -Force
    }

    # ========================================================
    # GERA ZIP
    #
    # Usar \* e importante para que o conteudo do Stage fique
    # diretamente na raiz do ZIP.
    #
    # NAO queremos:
    #
    # goopedir-package-xxxxx\
    #     ServidorGooPedir.exe
    #
    # Queremos:
    #
    # ServidorGooPedir.exe
    # manifest.json
    # nginx\
    #
    # ========================================================

    Write-Host "Compactando pacote..."
    Write-Host ""

    Compress-Archive `
        -Path (Join-Path $StageDirectory '*') `
        -DestinationPath $OutputZip `
        -CompressionLevel Optimal `
        -Force

    if (-not (Test-Path -LiteralPath $OutputZip)) {
        throw "O ZIP nao foi criado: $OutputZip"
    }

    # ========================================================
    # INFORMACOES DO ZIP
    # ========================================================

    $ZipFile = Get-Item `
        -LiteralPath $OutputZip

    $ZipHash = (
        Get-FileHash `
            -LiteralPath $OutputZip `
            -Algorithm SHA256
    ).Hash.ToLowerInvariant()

    Write-Host ""
    Write-Host "============================================================"
    Write-Host "  PACOTE GERADO COM SUCESSO"
    Write-Host "============================================================"
    Write-Host ""

    Write-Host "Arquivo:"
    Write-Host "  $($ZipFile.FullName)"
    Write-Host ""

    Write-Host "Tamanho:"
    Write-Host "  $($ZipFile.Length) bytes"
    Write-Host ""

    Write-Host "SHA256:"
    Write-Host "  $ZipHash"
    Write-Host ""

    # Mantem o mesmo retorno que teu script antigo ja fazia
    [PSCustomObject]@{
        file      = $ZipFile.FullName
        sizeBytes = [Int64]$ZipFile.Length
        sha256    = $ZipHash
    } |
        ConvertTo-Json
}
catch {

    Write-Host ""
    Write-Host "============================================================"
    Write-Host "  ERRO AO GERAR PACOTE"
    Write-Host "============================================================"
    Write-Host ""

    Write-Host $_.Exception.Message
    Write-Host ""

    throw
}
finally {

    # ========================================================
    # LIMPA SOMENTE O STAGING
    #
    # NAO LIMPA SourceDirectory.
    # A limpeza dos EXEs e nginx\html deve acontecer somente
    # no BAT, depois que o upload ao servidor for confirmado.
    # ========================================================

    if (Test-Path -LiteralPath $StageDirectory) {

        Remove-Item `
            -LiteralPath $StageDirectory `
            -Recurse `
            -Force `
            -ErrorAction SilentlyContinue
    }
}