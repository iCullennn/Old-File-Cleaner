param (
    [Parameter(Mandatory = $true)]
    [string]$Path,
    [switch]$Backup
)

# Set age threshold
$limit = (Get-Date).AddDays(-30)
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$backupPath = Join-Path -Path $root -ChildPath "backup"

if (-not (Test-Path -Path $Path)) {
    Write-Error "Path does not exist: $Path"
    exit
}

# Get list of old files
$oldFiles = Get-ChildItem -Path $Path -Recurse -Force |
    Where-Object { !$_.PSIsContainer -and $_.CreationTime -lt $limit }

if ($oldFiles.Count -eq 0) {
    Write-Output "No files older than 30 days found."
    exit
}

if ($Backup) {
    if (-not (Test-Path -Path $backupPath)) {
        Write-Output "Creating backup directory: $backupPath"
        New-Item -Path $backupPath -ItemType Directory | Out-Null
    }

    Write-Output "Backing up $($oldFiles.Count) old files to: $backupPath"
    $oldFiles | Copy-Item -Destination $backupPath -Force
}

# Remove old files
Write-Output "Deleting old files..."
$oldFiles | Remove-Item -Force

# Remove empty folders
$emptyFolders = Get-ChildItem -Path $Path -Recurse -Directory -Force |
    Where-Object { (Get-ChildItem -Path $_.FullName -Force) -eq $null }

if ($emptyFolders.Count -gt 0) {
    Write-Output "Removing $($emptyFolders.Count) empty folders..."
    $emptyFolders | Remove-Item -Force -Recurse
}

Write-Output "Cleanup complete."
