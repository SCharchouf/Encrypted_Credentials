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
$RequiredModules = @('HPEOneView.850', 'Microsoft.PowerShell.Security', 'Microsoft.PowerShell.Utility')
Import-ModulesIfNotExists -ModuleNames $RequiredModules
# Specify the directory where the encrypted credentials will be stored
$directoryPath = .\Encrypted_Credentials
# Check if the directory exists, if not, create it
if (!(Test-Path -Path $directoryPath)) {
    New-Item -ItemType Directory -Path $directoryPath
    Write-Host "Directory $directoryPath created." -ForegroundColor Green
}
# Specify the path to the CSV file containing the list of OneView Global Dashboards
$OGDList = Import-Csv -Path .\GlobalDashboards_List.csv
# Define the directory to save the reports
$UsersOGD = ".\Users_OneView_Global_Dashboard"
$AppliancesDirectory = ".\Appliances-Details"
# Define a function to create a directory if it doesn't exist
function New-Directory {
    param (
        [Parameter(Mandatory=$true)]
        [string]$DirectoryPath
    )

    if (-not (Test-Path -Path $DirectoryPath)) {
        New-Item -Path $DirectoryPath -ItemType Directory | Out-Null
        Write-Host "Directory $DirectoryPath created." -ForegroundColor Green
    } else {
        Write-Host "Directory $DirectoryPath already exists." -ForegroundColor Yellow
    }
}
# Use the function to create the directories
New-Directory -DirectoryPath $UsersOGD
New-Directory -DirectoryPath $AppliancesDirectory
# Connect to the OneView Global Dashboard imported from the CSV file
foreach ($Dashboard in $OGDList) {
    $DashboardName = $Dashboard.Name
    $DashboardIP = $Dashboard.IP
    $DashboardUsername = $Dashboard.Username
    $DashboardPassword = $Dashboard.Password
    $EncryptedPassword = ConvertTo-SecureString -String $DashboardPassword -AsPlainText -Force
    $Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $DashboardUsername, $EncryptedPassword
    # Save the encrypted credentials to a file
    $Credential | Export-Clixml -Path "$directoryPath\$DashboardName.xml"
    Write-Host "Encrypted credentials for $DashboardName saved to $directoryPath\$DashboardName.xml" -ForegroundColor Green
    # Connect to the OneView Global Dashboard
    Connect-HPOVGlobalDashboard -Hostname $DashboardIP -Credential $Credential
    # Get the list of users from the OneView Global Dashboard
    $Users = Get-HPOVGlobalDashboardUser
    # Save the list of users to a CSV file
    $Users | Export-Csv -Path "$UsersOGD\$DashboardName.csv" -NoTypeInformation
    Write-Host "List of users from $DashboardName saved to $UsersOGD\$DashboardName.csv" -ForegroundColor Green
    # Get the details of the appliances from the OneView Global Dashboard
    $Appliances = Get-HPOVGlobalDashboardAppliance
    # Save the details of the appliances to a CSV file
    $Appliances | Export-Csv -Path "$AppliancesDirectory\$DashboardName.csv" -NoTypeInformation
    Write-Host "Details of the appliances from $DashboardName saved to $AppliancesDirectory\$DashboardName.csv" -ForegroundColor Green
}
# Disconnect from the OneView Global Dashboard
