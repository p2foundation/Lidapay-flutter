# PowerShell script to fix generated api_client.g.dart file
# This removes the errorLogger calls and fixes country list response handling
# Run this after: flutter pub run build_runner build

$filePath = "lib/data/datasources/api_client.g.dart"

if (Test-Path $filePath) {
    $content = Get-Content $filePath -Raw
    
    # Fix 1: Remove errorLogger calls - they cause arg mismatch and errors are already logged via Dio interceptors
    $content = $content -replace 'errorLogger\?\s*\.logError\(\s*e\s*,\s*s\s*,\s*_options\s*\)\s*;', '// errorLogger removed to fix arg mismatch'
    
    # Fix 2: Change getCountries to fetch<dynamic> because API returns List directly
    $content = $content -replace '(Future<CountriesResponse> getCountries\(\) async \{[\s\S]*?)_dio\.fetch<Map<String, dynamic>>', '$1_dio.fetch<dynamic>'
    
    # Fix 3: Change CountriesResponse.fromJson(_result.data!) to CountriesResponse.fromJson(_result.data)
    $content = $content -replace 'CountriesResponse\.fromJson\(_result\.data!\)', 'CountriesResponse.fromJson(_result.data)'
    
    Set-Content $filePath -Value $content -NoNewline
    Write-Host "Fixed api_client.g.dart:" -ForegroundColor Green
    Write-Host "  - Removed errorLogger calls" -ForegroundColor Yellow
    Write-Host "  - Fixed getCountries to handle List response" -ForegroundColor Yellow
} else {
    Write-Host "File not found: $filePath" -ForegroundColor Red
}
