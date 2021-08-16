[CmdletBinding()]
param(
    [string] $PackagePath,
    [string] $AnalysisInstance,
    [string] $ModelName,
    [string] $ServicePrincipal
)

Write-Host "Hello from my action"

Import-Module (Join-Path $PSScriptRoot "SQLServer")
Import-Module (Join-Path $PSScriptRoot "AzureRM.Profile")
Import-Module (Join-Path $PSScriptRoot "AzureRM.AnalysisServices")
Import-Module (Join-Path $PSScriptRoot "Azure.AnalysisServices")

Write-Host "Will import $PackagePath to $AnalysisInstance / $ModelName"

$sp = $ServicePrincipal | ConvertFrom-Json

$sp.clientId
$sp.clientSecret
$sp.tenantId

$secureSecret = ConvertTo-SecureString -String $sp.clientSecret -AsPlainText -Force
$creds = New-Object PSCredential @($sp.clientId, $secureSecret)

$model = Get-Content $PackagePath -Encoding UTF8 | ConvertFrom-Json

$tmsl = '{"createOrReplace":{"object":{"database":"existingModel"},"database":{"name":"emptyModel"}}}' | ConvertFrom-Json
$tmsl.createOrReplace.object.database = $ModelName
$tmsl.createOrReplace.database = $Model
$tmsl = ConvertTo-Json $tmsl -Depth 100 -Compress


$environment = $AnalysisInstance.Split('/')[2];
$result = Add-AzureAnalysisServicesAccount -Credential $creds -ServicePrincipal -TenantId $sp.tenantId -RolloutEnvironment $environment

Invoke-ASCmd -Server $Server -Query $tmsl
# Invoke-ASCmd -Server $AnalysisInstance -Database $ModelName -ApplicationId $sp.clientId -ServicePrincipal -TenantID $sp.tenantId -Credential $creds