<#
    .Synopsis
    Installs Azure powershell modules outside the auto-loading directory for import only when needed

    .Description
    For performance, it's an advantage to have the Azure modules outside your normal module path. This script does the following:
     - installs AzureRM modules to a separate location in the current user's WindowsPowerShell folder
     - installs the PoshSecret module to save your Azure credentials securely
     - adds a funciton to your powershell profile that imports the modules and authenticates to Azure

    This assumes that you only want to administer a single Azure subscription

    .Link
    https://docs.microsoft.com/en-us/powershell/azure/overview?view=azurermps-4.0.0
#>
#requires -Version 4.0
#requires -Modules PowerShellGet, PoshSecret

function Install-AzureModules {
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [switch]$IncludeLegacy
    )
    $ModuleRoot = Get-Item ~\Documents\WindowsPowerShell
    $NoAutoLoad = New-Item $ModuleRoot\NoAutoLoad -ItemType Directory -Force
    $null = New-Item $NoAutoLoad\Modules -ItemType Directory -Force


    $Before = Get-ChildItem $ModuleRoot\Modules
    if ($IncludeLegacy) {
        Write-Host -ForegroundColor DarkYellow "Installing Azure (legacy) modules for current user"
        Install-Module Azure -AllowClobber -Scope CurrentUser -Force     #Legacy: Service Manager
    }
    Write-Host -ForegroundColor DarkYellow "Installing AzureRM modules for current user"
    Install-Module AzureRM -AllowClobber -Scope CurrentUser -Force
    $After = Get-ChildItem $ModuleRoot\Modules

    #Move out of PSModulePath
    $ItemsToMove = Compare-Object $Before $After | where {$_.SideIndicator -eq '=>'} | select -ExpandProperty InputObject
    $ItemsToMove | Move-Item -Destination $NoAutoLoad\Modules -Force
}


function Load-AzureModules {
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [switch]$IncludeLegacy
    )
    $env:PSModulePath = "{0}\Modules;{1}" -f $NoAutoLoad, $env:PSModulePath
    if ($IncludeLegacy) {
        Write-Host -ForegroundColor DarkYellow "Importing Azure (legacy) modules"
        Import-Module AzureRM
    }
    Write-Host -ForegroundColor DarkYellow "Importing AzureRM modules"
    Import-Module AzureRM
    $env:PSModulePath = $env:PSModulePath -replace [regex]::Escape(("{0}\Modules;" -f $NoAutoLoad))
}


function Get-AzureCredential {
    [CmdletBinding(DefaultParameterSetName='SubscriptionAdmin')]
    [OutputType([pscredential])]
    param(
        [Parameter(ParameterSetName='SubscriptionAdmin', Position=0)]
        [switch]$SubscriptionAdmin
    )
    
    switch ($PSCmdlet.ParameterSetName) {
        'SubscriptionAdmin'
            {
                Get-PoshSecret
            }


    }
}

function Save-AzureCredential {
    [CmdletBinding(DefaultParameterSetName='SubscriptionAdmin')]
    [OutputType([void])]
    param(
        [Parameter(ParameterSetName='SubscriptionAdmin', Position=0)]
        [switch]$SubscriptionAdmin,

        [Parameter(Position=1)]
        [pscredential]$Credential = (Get-Credential)
    )


}