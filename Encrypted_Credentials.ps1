function Import-ModulesIfNotExists {
    param (
        [Parameter(Mandatory=$true)]
        [string[]]$ModuleNames
    )
    # Check for missing modules
    Write-Host "`tChecking for missing modules..." -ForegroundColor Cyan
    # Check if the required modules are already imported
    $missingModules = $ModuleNames | Where-Object { -not (Get-Module -Name $_ -ListAvailable) }
    # If there are missing modules, display a message and exit the script
    if ($missingModules) {
        Write-Host "`tCritical modules missing: " -NoNewline -ForegroundColor Red
        Write-Host "$($missingModules -join ', ')" -ForegroundColor Yellow
        Write-Host "`tThe script cannot continue without these missing module(s). Please ensure they are installed locally and try again." -ForegroundColor Red
        Exit 1  # Exit with error code 1
    }
    # Import remaining modules
    $totalModules = $ModuleNames.Count
    $currentModuleNumber = 0
    foreach ($ModuleName in $ModuleNames) {
        $currentModuleNumber++
        if (Get-Module -Name $ModuleName -ListAvailable) {
            Write-Host "`tThe module " -NoNewline -foregroundColor Yellow
            Write-Host "[$ModuleName] " -NoNewline -foregroundColor Cyan
            Write-Host "is already imported." -ForegroundColor Yellow
        } else {
            $progress = ($currentModuleNumber / $totalModules) * 100
            Write-Progress -Activity "Importing $ModuleName" -Status "Please wait..." -PercentComplete $progress
            Import-Module -Name $ModuleName -ErrorAction SilentlyContinue -ErrorVariable importError
            if ($importError) {
                Write-Host "`tFailed to import The module " -NoNewline -ForegroundColor Red
                Write-Host "$ModuleName $($importError.Exception.Message)" -ForegroundColor Red
            } else {
                Write-Host "`tSuccessfully imported The module" -NoNewline -ForegroundColor Green
                Write-Host "[$ModuleName]" -ForegroundColor Green
            }
        }
    }
    # Clear progress bar (optional)
    Write-Progress -Activity "Importing modules" -Completed
    Write-Host "`n`tDone checking and importing modules." -ForegroundColor Green
}
# Import the required modules
$RequiredModules = @('HPEOneView.850', 'GlobalDashboardPS', 'Microsoft.PowerShell.Security', 'Microsoft.PowerShell.Utility')
Import-ModulesIfNotExists -ModuleNames $RequiredModules
# Get the script's folder path
$ScriptPath = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
# Import OneView Global Dashboard FQDNs from the CSV file placed outside the script's folder from where the script is executed
$CsvFilePath = Join-Path -Path (Get-Item -Path $ScriptPath).Parent.FullName -ChildPath "GlobalDashboards_List.csv"
$GlobalDashboards = Import-Csv -Path $CsvFilePath
# Connect to the OneView Global Dashboard
foreach ($GlobalDashboard in $GlobalDashboards) {
    $GlobalDashboardFQDN = $GlobalDashboard.FQDN
    $GlobalDashboardCredential = Get-Credential -Message "Enter the credentials for the OneView Global Dashboard $GlobalDashboardFQDN"
    $GlobalDashboardSession = Connect-HPOVGlobalDashboard -FQDN $GlobalDashboardFQDN -Credential $GlobalDashboardCredential
    if ($GlobalDashboardSession) {
        Write-Host "Connected to the OneView Global Dashboard $GlobalDashboardFQDN" -ForegroundColor Green
    } else {
        Write-Host "Failed to connect to the OneView Global Dashboard $GlobalDashboardFQDN" -ForegroundColor Red
    }
}
