# PowerShell script to update author information in all SQL files
# Update SQL Analyst Pack - Set Author Information

param(
    [Parameter(Mandatory=$true)]
    [string]$AuthorName
)

Write-Host "🔧 Updating author information in SQL files..." -ForegroundColor Cyan
Write-Host "Author Name: $AuthorName" -ForegroundColor Green

# Get all SQL files recursively, excluding archived files
$sqlFiles = Get-ChildItem -Path "." -Filter "*.sql" -Recurse | Where-Object { 
    $_.FullName -notlike "*\_archive\*" 
}

$updatedCount = 0
$errorCount = 0

foreach ($file in $sqlFiles) {
    try {
        Write-Host "Processing: $($file.FullName)" -ForegroundColor Yellow
        
        # Read the file content
        $content = Get-Content -Path $file.FullName -Raw
        
        # Update various author patterns
        $originalContent = $content
        
        # Pattern 1: "Author      : SQL Analyst Pack Contributors"
        $content = $content -replace "(\s+Author\s+:\s+)SQL Analyst Pack Contributors", "`${1}$AuthorName"
        
        # Pattern 2: "Author      : GitHub Copilot"
        $content = $content -replace "(\s+Author\s+:\s+)GitHub Copilot", "`${1}$AuthorName"
        
        # Pattern 3: "Author      : {{Your Name}}"
        $content = $content -replace "(\s+Author\s+:\s+)\{\{Your Name\}\}", "`${1}$AuthorName"
        
        # Pattern 4: "Author      : [Your Name]"
        $content = $content -replace "(\s+Author\s+:\s+)\[Your Name\]", "`${1}$AuthorName"
        
        # Update the Updated date to today
        $today = Get-Date -Format "yyyy-MM-dd"
        $content = $content -replace "(\s+Updated\s+:\s+)\d{4}-\d{2}-\d{2}", "`${1}$today"
        
        # Only write if content changed
        if ($content -ne $originalContent) {
            Set-Content -Path $file.FullName -Value $content -NoNewline
            $updatedCount++
            Write-Host "  ✅ Updated" -ForegroundColor Green
        } else {
            Write-Host "  ⏭️ No changes needed" -ForegroundColor Gray
        }
        
    } catch {
        Write-Host "  ❌ Error: $($_.Exception.Message)" -ForegroundColor Red
        $errorCount++
    }
}

Write-Host "`n📊 Update Summary:" -ForegroundColor Cyan
Write-Host "  📁 Total SQL files processed: $($sqlFiles.Count)" -ForegroundColor White
Write-Host "  ✅ Files updated: $updatedCount" -ForegroundColor Green
Write-Host "  ❌ Errors: $errorCount" -ForegroundColor Red

if ($updatedCount -gt 0) {
    Write-Host "`n🎉 Author information successfully updated!" -ForegroundColor Green
    Write-Host "All SQL files now list '$AuthorName' as the author." -ForegroundColor White
} else {
    Write-Host "`n ℹ️ No files needed updating." -ForegroundColor Yellow
}

Write-Host "`n🚀 Author update process complete!" -ForegroundColor Cyan
