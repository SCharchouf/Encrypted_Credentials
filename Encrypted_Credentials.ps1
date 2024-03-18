function ImportModules {
    param (
        [Parameter(Mandatory=$true)]
        [string[]]$ModuleNames
    )

    $totalModules = $ModuleNames.Count
    $currentModule = 0

    foreach ($ModuleName in $ModuleNames) {
        $currentModule++

        # Update progress bar
        $percentComplete = ($currentModule / $totalModules) * 100
        $progressBar = ('#' * $percentComplete) + (' ' * (100 - $percentComplete))
        Write-Host -NoNewline "`rProgress: [$progressBar] $percentComplete%"

        # Check if module is already imported
        $module = Get-Module -Name $ModuleName
        if ($module) {
            Write-Host "`n$ModuleName is already imported" -ForegroundColor Green
        } else {
            Write-Host "`n$ModuleName is not imported. Trying to import..." -ForegroundColor Yellow
            # Try to import the module
            Import-Module -Name $ModuleName -ErrorAction SilentlyContinue -ErrorVariable importError
            if ($importError) {
                Write-Host "Failed to import $ModuleName. It may not be installed." -ForegroundColor Red
            } else {
                Write-Host "Successfully imported $ModuleName" -ForegroundColor Green
            }
        }
    }

    # Clear progress bar
    Write-Host "`nDone checking and importing modules."
}
# Import the required modules
ImportModules -ModuleNames 'HPEOneView.850', 'Microsoft.PowerShell.Security', 'Microsoft.PowerShell.Utility'
# Specify the directory where the encrypted credentials will be stored
$directoryPath = .\Encrypted_Credentials
# Check if the directory exists, if not, create it
if (!(Test-Path -Path $directoryPath)) {
    New-Item -ItemType Directory -Path $directoryPath
    Write-Host "Directory $directoryPath created." -ForegroundColor Green
}
# Specify the path to the CSV file containing the list of OneView Global Dashboards
$GlobalDashboards = Import-Csv -Path .\GlobalDashboards_List.csv
# Read the CSV file
$OGDList = Import-Csv -Path $GlobalDashboards
# Loop through each OneView in the list
foreach ($oneView in $OGDList) {
    # Ask for the OneView login credentials
    $credentials = Get-Credential -Message "Please enter your login credentials for $oneView"
    # Encrypt the credentials and store them in a secure file
    $encryptedCredentials = $credentials | ConvertFrom-SecureString
    Set-Content -Path "$directoryPath\$oneView-credentials.txt" -Value $encryptedCredentials
}