function Create-SharedMailbox {
    <#
    .SYNOPSIS
        Creates an AD User Account for a Shared Mailbox and its associated Access Group.
    .DESCRIPTION
        Validates uniqueness against both SamAccountName and UserPrincipalName.
        If unique, provisions the account and security group into a specified OU.
        Includes an automatic rollback mechanism to clean up AD upon failures.
    .PARAMETER FormattedName
        The validated, lowercase department name string returned by Test-DepartmentName.
    .EXAMPLE
        Create-SharedMailbox -FormattedName "finances"
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FormattedName
    )

    # --- Step 1: Pre-requisites & Local Variables ---
    $name = $FormattedName
    $titleName = (Get-Culture).TextInfo.ToTitleCase($name)
    $samAccountName = "sm_$name"
    $groupName = "sg_sm_${name}_access"
    
    # Dynamically determine domain info
    try {
        $domainRoot = (Get-ADDomain -Current LoggedOnUser).DNSRoot
    }
    catch {
        Write-Host "Failed to connect to Active Directory. Ensure you have the ActiveDirectory module and a valid session." -BackgroundColor Red -ForegroundColor White
        return $false
    }
    
    $userPrincipalName = "$samAccountName@$domainRoot"
    $OUPath = "OU=Shared Mailboxes,OU=Resources,OU=Camp,DC=oldcamp,DC=gothic,DC=inc"

    # Tracking creation state for the rollback mechanism
    $accountCreatedStatus = $false
    $groupCreatedStatus = $false

    # --- Step 2: Extended Pre-existence Validation (SamAccountName OR UPN) ---
    Write-Host "Checking AD for existing SamAccountName or UserPrincipalName..." -ForegroundColor Cyan
    
    # Querying both parameters to ensure 100% uniqueness
    $existingAccount = Get-ADUser -Filter "SamAccountName -eq '$samAccountName' -or UserPrincipalName -eq '$userPrincipalName'" -ErrorAction SilentlyContinue

    if ($existingAccount) {
        Write-Warning "Conflict detected: An Active Directory account with SamAccountName '$samAccountName' or UPN '$userPrincipalName' already exists."
        return $false  # Signal Main Loop to 'continue' back to Test-DepartmentName
    }

    # Generate a test password for the disabled account (AD Requirement)
    $PasswordString = "Test1234!"
    $SecurePassword = ConvertTo-SecureString $PasswordString -AsPlainText -Force

    # --- Step 3: Splatting Configurations ---
    $AccountParams = @{
        Name                  = "$titleName Shared Mailbox"
        SamAccountName        = $samAccountName
        UserPrincipalName     = $userPrincipalName
        DisplayName           = "Shared Mailbox - $titleName"
        AccountPassword       = $SecurePassword
        Enabled               = $false
        ChangePasswordAtLogon = $false
        Path                  = $OUPath
        Description           = "Shared Mailbox for '$titleName' department, created by Shared Mailbox Creator."
    }

    $GroupParams = @{
        Name          = $groupName
        DisplayName   = "Security Group - SM - $titleName - Access"
        GroupScope    = "Global"
        GroupCategory = "Security"
        Path          = $OUPath
        Description   = "Access group for the $titleName Shared Mailbox. Created via automation script."
    }

    # --- Step 4: Infrastructure Creation with Rollback (Try/Catch) ---
    try {
        # Create User Account
        Write-Host "Creating AD User Account: $samAccountName..." -ForegroundColor Gray
        New-ADUser @AccountParams
        $accountCreatedStatus = $true
        Write-Host "AD User Account created successfully." -ForegroundColor Green

        # Create Security Group
        Write-Host "Creating Access Security Group: $groupName..." -ForegroundColor Gray
        New-ADGroup @GroupParams
        $groupCreatedStatus = $true
        Write-Host "Access Security Group created successfully." -ForegroundColor Green
    }
    catch {
        Write-Warning "[CRITICAL] An error occurred during the provisioning sequence: $_"
        Write-Host "Initiating automatic rollback mechanism to maintain Active Directory integrity..." -ForegroundColor Yellow
        
        # Rollback Execution
        if ($accountCreatedStatus -eq $true) {
            Write-Host "Rollback: Removing partially created AD User Account ($samAccountName)..." -ForegroundColor DarkYellow
            Remove-ADUser -Identity $samAccountName -Confirm:$false -ErrorAction SilentlyContinue
        }
        if ($groupCreatedStatus -eq $true) {
            Write-Host "Rollback: Removing partially created AD Security Group ($groupName)..." -ForegroundColor DarkYellow
            Remove-ADGroup -Identity $groupName -Confirm:$false -ErrorAction SilentlyContinue
        }
        
        Write-Host "Rollback complete. Active Directory environment remains clean." -ForegroundColor Green
        return $false
    }

    # --- Step 5: Post-Creation Base Department Group Search & Nesting ---
    Write-Host "Searching for matching base department group '$titleName'..." -ForegroundColor Cyan
    $departmentGroup = Get-ADGroup -Filter "Name -eq '$titleName'" -ErrorAction SilentlyContinue

    if ($departmentGroup) {
        Write-Host "Found an existing base department group matching: $titleName" -ForegroundColor Green
        
        # Interactive CLI Prompt
        $Confirmation = Read-Host "Do you want to add this group to the newly created access group ($groupName)? [Y/N]"
        
        if ($Confirmation -eq "Y") {
            try {
                Write-Host "Nesting group '$titleName' inside '$groupName'..." -ForegroundColor Gray
                Add-ADGroupMember -Identity $groupName -Members $departmentGroup
                Write-Host "Group nesting successful." -ForegroundColor Green
            }
            catch {
                Write-Warning "Failed to nest group: $_"
            }
        }
        else {
            Write-Host "User declined group nesting. Skipping phase." -ForegroundColor Yellow
        }
    }
    else {
        Write-Host "No matching base department group found for '$titleName'. Skipping phase." -ForegroundColor Yellow
    }

    Write-Host "Create-SharedMailbox process finalized successfully." -ForegroundColor Green
    return $true
}