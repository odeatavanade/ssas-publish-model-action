function Invoke-AsCmdInternal{
[CmdletBinding()]
    param(
        [string] $Server,
        [string] $Query
    )

    Write-Host $Query

    Invoke-ASCmd -Server $Server -Query $Query -Verbose
}
[CmdletBinding()]
param(
    [string] $PackagePath,
    [string] $AnalysisInstance,
    [string] $ModelName,
    [string] $ServicePrincipal,
    [string] $PostDeploymentScripts
)

Write-Host "Hello from my action"

Import-Module (Join-Path $PSScriptRoot "SQLServer")
Import-Module (Join-Path $PSScriptRoot "AzureRM.Profile")
Import-Module (Join-Path $PSScriptRoot "AzureRM.AnalysisServices")
Import-Module (Join-Path $PSScriptRoot "Azure.AnalysisServices")

Write-Host "Will import $PackagePath to $AnalysisInstance / $ModelName"

$sp = $ServicePrincipal | ConvertFrom-Json

Write-Host "Will deploy as $($sp.clientId) on $($sp.tenantId)"

$secureSecret = ConvertTo-SecureString -String $sp.clientSecret -AsPlainText -Force
$creds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList @($sp.clientId, $secureSecret)

$asInstanceName = $AnalysisInstance.Split('/')[2];
Add-AzureAnalysisServicesAccount -Credential $creds -ServicePrincipal -TenantId $sp.tenantId -RolloutEnvironment $asInstanceName

$model = Get-Content $PackagePath -Encoding UTF8 | ConvertFrom-Json
$tmsl = '{"createOrReplace":{"object":{"database":"existingModel"},"database":{"name":"emptyModel"}}}' | ConvertFrom-Json
$tmsl.createOrReplace.object.database = $ModelName
$tmsl.createOrReplace.database = $Model
$tmsl = ConvertTo-Json $tmsl -Depth 100 -Compress

Invoke-AsCmdInternal -Server $AnalysisInstance -Query $tmsl
# Invoke-ASCmd -Server $AnalysisInstance -Database $ModelName -ApplicationId $sp.clientId -ServicePrincipal -TenantID $sp.tenantId -Credential $creds

if($PostDeploymentScripts -and (![string]::IsNullOrEmpty($PostDeploymentScripts))){
    $PostDeploymentScripts.Split(",") | ForEach-Object {
        Write-Host "Running post deployment script $_"
        $tmsl = Get-Content $_ -Encoding UTF8 | Out-String
        Invoke-AsCmdInternal -Server $AnalysisInstance -Query $tmsl
    }
}