function Import-ModulesIfNotExists {
    param (
        [Parameter(Mandatory=$true)]
        [string[]]$ModuleNames
    )
    foreach ($ModuleName in $ModuleNames) {
        if (-not (Get-Module -Name $ModuleName)) {
            if (Get-Module -ListAvailable -Name $ModuleName) {
                Import-Module $ModuleName
                Write-Host -ForegroundColor Yellow "`tModule '$ModuleName' is not imported. Importing now..."
                # Progress bar importing modules
                for ($i = 0; $i -le 100; $i+=10) {
                    Write-Progress -Activity "`tImporting module '$ModuleName'" -Status "Please wait..." -PercentComplete $i
                    Start-Sleep -Milliseconds 100
                }
                break # Exit the loop after importing the module
            } else {
                Write-Host -ForegroundColor Red  "`tModule '$ModuleName' does not exist."
            }
        } else {
            Write-Host -ForegroundColor Magenta "`tModule '$ModuleName' is already imported."
        }
    }
}
# Import the required modules
Import-ModulesIfNotExists -ModuleNames 'HPEOneView.850', 'Microsoft.PowerShell.Security'
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