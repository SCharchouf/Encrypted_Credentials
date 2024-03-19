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
# Define the function to connect to all OneView Global Dashboards stored in the CSV file using Connect-OVGD
function ConnectToGlobalDashboard {
    # Get the current script's full path
    $scriptPath = $PSScriptRoot
    # Define the CSV file name
    $csvFileName = "GlobalDashboards_List.csv"
    # Combine script path and filename to get the full CSV path
    $GlobalDashboardsCSV = Join-Path $scriptPath $csvFileName
    # Import the CSV file that contains the Global Dashboards information
    $GlobalDashboards = Import-Csv -Path $GlobalDashboardsCSV
    # Connect to each OneView Global Dashboard
    foreach ($GlobalDashboard in $GlobalDashboards) {
        $GlobalDashboardName = $GlobalDashboard.GlobalDashboardName
        # Prompt the user for the username and password
        $GlobalDashboardUsername = Read-Host -Prompt "Enter username for $GlobalDashboardName"
        $GlobalDashboardPassword = Read-Host -Prompt "Enter password for $GlobalDashboardName" -AsSecureString
        # Convert the secure string password to an encrypted standard string
        $encryptedPassword = ConvertFrom-SecureString -SecureString $GlobalDashboardPassword
        # Define the directory where the password files will be stored
        $passwordDirectory = Join-Path $scriptPath "EncryptedPasswords"
        # Check if the directory exists, if not, create it
            if (!(Test-Path -Path $passwordDirectory)) {
                New-Item -ItemType Directory -Path $passwordDirectory | Out-Null
            }
        # Define the path to the password file
        $passwordFilePath = Join-Path $passwordDirectory "$GlobalDashboardName.txt"
        # Save the encrypted password to a file
        Set-Content -Path $passwordFilePath -Value $encryptedPassword
        # Create a PSCredential object to use with the New-GlobalDashboardSession function
        $GlobalDashboardCredential = New-Object System.Management.Automation.PSCredential($GlobalDashboardUsername, $GlobalDashboardPassword)
        # Connect to the OneView Global Dashboard
        $GlobalDashboardSession = New-GlobalDashboardSession -GlobalDashboardIP $GlobalDashboardName -Credential $GlobalDashboardCredential
            if ($GlobalDashboardSession) {
                Write-Host "`tSuccessfully connected to the OneView Global Dashboard: $GlobalDashboardName" -ForegroundColor Green
            } else {
                Write-Host "`tFailed to connect to the OneView Global Dashboard: $GlobalDashboardName" -ForegroundColor Red
            }
    }
}
# Connect to all OneView Global Dashboards
ConnectToGlobalDashboard