#!/usr/local/bin/pwsh
param(
  [switch]$offline,
  [switch]$SkipPester,
  [switch]$ServerOnly,
  [switch]$TentacleOnly,
  [string]$OctopusVersion,
  [switch]$retainondestroy,
  [switch]$debug
)

. Tests/powershell-helpers.ps1

Start-Transcript .\vagrant-virtualbox.log

Set-OctopusDscEnvVars @PSBoundParameters

. Tests/powershell-helpers.ps1

if (-not (Test-AppExists "vagrant")) {
  Write-Output "Please install vagrant from vagrantup.com."
  exit 1
}
Write-Output "Vagrant installed - good."

if (-not (Test-AppExists "VBoxManage")) {
  Write-Output "Please install VirtualBox from virtualbox.org and ensure the installation path is added to the system environment path."
  exit 1
}
Write-Output "VirtualBox installed - good."

Test-CustomVersionOfVagrantDscPluginIsInstalled
Test-PluginInstalled "vagrant-winrm-syncedfolders"

# Check to see if Chocolatey is installed
if (!(Get-Command choco.exe -ErrorAction SilentlyContinue))
{
  # Display message to user
  Write-Output 'Please install Chocolatey.'
  exit 1
}
else
{
  Write-Output "Chocolatey installed - good."
}


if(-not $SkipPester)
{
  Write-Output "Importing Pester module"
  Test-PowershellModuleInstalled "Pester"
  Test-PowershellModuleInstalled "PSScriptAnalyzer"
  Import-Module Pester -verbose -force
  Write-Output "Running Pester Tests"
  $result = Invoke-Pester -OutputFile PesterTestResults.xml -OutputFormat NUnitXml -PassThru
  if ($result.FailedCount -gt 0) {
    exit 1
  }
}
else
{
  Write-Output "-SkipPester was specified, skipping pester tests"
}

$splat = @{
  provider = 'virtualbox';
  retainondestroy = $retainondestroy.IsPresent;
  debug = $debug.IsPresent;
}

Invoke-VagrantWithRetries @splat

Write-Output "Don't forget to run 'vagrant destroy -f' when you have finished"

stop-transcript
