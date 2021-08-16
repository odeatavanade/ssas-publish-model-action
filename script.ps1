[CmdletBinding()]
param(
    [string] $PackagePath,
    [string] $AnalysisInstance
)

Write-Host "Hello from my action"

Import-Module (Join-Path $PSScriptRoot "SQLServer")

Write-Host "Will import $PackagePath to $AnalysisInstance"
