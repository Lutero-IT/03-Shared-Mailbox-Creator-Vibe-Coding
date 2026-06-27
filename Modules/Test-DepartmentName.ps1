function Test-DepartmentName {
    [CmdletBinding()]
    param()

    # Enterprise naming convention regex pattern
    # Validates alphanumeric strings, allowing internal hyphens and underscores.
    # Prevents special characters at the start or end.
    $RegexPattern = '^[a-zA-Z0-9]([a-zA-Z0-9-_]*[a-zA-Z0-9])?$'
    $MinLength = 2
    $MaxLength = 17

    while ($true) {
        Write-Host ""
        Write-Host "==================================================" -ForegroundColor Cyan
        Write-Host "ENTERPRISE NAMING CONVENTIONS FOR SHARED MAILBOX" -ForegroundColor Cyan
        Write-Host "- Allowed characters: Letters (a-z, A-Z), Digits (0-9)" -ForegroundColor White
        Write-Host "- Allowed internal separators: Hyphens (-), Underscores (_)" -ForegroundColor White
        Write-Host "- Constraint: Cannot start or end with a hyphen or underscore" -ForegroundColor Yellow
        Write-Host "- Department Name Length: Between $MinLength and $MaxLength characters" -ForegroundColor White
        Write-Host "To abort the entire operation, type 'c' or 'cancel'." -ForegroundColor DarkYellow
        Write-Host "==================================================" -ForegroundColor Cyan

        $RawInput = Read-Host "Enter Department Name"
        Write-Host ""

        # Jeden warunek, który załatwia absolutnie wszystko: null, puste znaki i same spacje
        if ([string]::IsNullOrWhiteSpace($RawInput)) {
            Write-Warning "Input cannot be empty. Please try again."
            continue
        }

        # Skoro przeszliśmy warunek, możemy bezpiecznie trimować i procesować dalej
        $CleanInput = $RawInput.Trim()

        # Check for user cancellation token
        if ($CleanInput -ieq 'c' -or $CleanInput -ieq 'cancel') {
            Write-Host "Operation canceled by the user." -ForegroundColor Yellow
            return $null
        }

        # Validate length requirements
        if ($CleanInput.Length -lt $MinLength -or $CleanInput.Length -gt $MaxLength) {
            Write-Warning "Invalid length. The department name must be between $MinLength and $MaxLength characters."
            continue
        }

        # Validate structural and character restrictions via Regex
        if ($CleanInput -notmatch $RegexPattern) {
            Write-Warning "Invalid format. Name contains illegal characters or starts/ends with a special character."
            continue
        }

        # Formulate the final compliant shared mailbox string
        $FormattedName = "sm_" + $CleanInput.ToLower()
        # FOR TEST PURPOSES: Write-Host "The SM Name is: $FormattedName"
        return $FormattedName
    }
}
