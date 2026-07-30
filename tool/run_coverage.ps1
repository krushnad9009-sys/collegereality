# Generate lcov coverage for unit + widget + flow tests.
$ErrorActionPreference = "Stop"
flutter test --coverage
Write-Host "Coverage written to coverage/lcov.info"
if (Get-Command genhtml -ErrorAction SilentlyContinue) {
  genhtml coverage/lcov.info -o coverage/html
  Write-Host "HTML report: coverage/html/index.html"
}
