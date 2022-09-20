#Requires -RunAsAdministrator

param (
    [Parameter(Mandatory=$false, Position=0, HelpMessage="The user to copy group membership FROM. If left blank, will assume it's the template user.")]
    [string] $SourceUser,
    [Parameter(Mandatory=$true, Position=1, HelpMessage="The user samaccountname, CN, DN, or SID to copy group membership TO.")]
    [string] $TargetUser,
	[Parameter(Mandatory=$false, HelpMessage="Obly add the following groups to the target user")]
    [string] $Filter
)

# START: Logging
$current_dir = Split-Path "$($MyInvocation.MyCommand.Path)" -Parent
Start-Transcript -OutputDirectory (Join-Path "$current_dir" "transcripts") | Out-Null

# get user object for target user, exit if invalid
$target_user = Get-ADUser -Identity $TargetUser -Properties MemberOf
    if ($null -eq $target_user) {throw "Target user Invalid"; exit}

# if source user is not specified, assume we're using the template user
if ( [string]::IsNullOrEmpty($SourceUser) ) {

    # get parent ou of target user
    $target_user_ou = (($target_user.DistinguishedName -split ',') | Select-Object -Skip 1) -join ','

    # fetch template user
    $template_user = Get-ADUser -SearchBase $target_user_ou -Filter {name -like "template*"} -Properties MemberOf

    # check if only 1 result
    $template_user_count = ($template_user | Measure-Object).Count
    if ($template_user_count -eq 1) {
        $source_user = $template_user
    }
    elseif ($template_user_count -gt 1) {
        throw "multiple template users found, please specify source user explicietly instead"; exit
    }
    else {
        throw "error retreiving templater user"; exit
    }

}

# otherwise, use the parameter
else {

    # get source user object for target user, exit if invalid
    $source_user = Get-ADUser -Identity $SourceUser -Properties MemberOf
    if ($null -eq $source_user) {throw "Source user Invalid"; exit}

}

Write-Host ""
Write-Host "Source User: $($source_user.distinguishedName)"
Write-Host "Target User: $($target_user.distinguishedName)"
Write-Host ""

# get source user groups
$source_users_groups = if ($Filter -ne $null) {
	# because .memberOf is a DN (and i'd rather keep the filter syntax simple) we'll (probably) need to append some values to the filter string
    if ( (-not $Filter.StartsWith("CN=")) ) {
		$Filter = "CN=$($Filter)"
	}
	if ( (-not $Filter.EndsWith("*")) ) {
		$Filter = "$($Filter)*"
	}
	
	Write-Host "Filter: $Filter"
	Write-Host ""
	
	$source_user.MemberOf | Where-Object {$_ -like $Filter}
} 
else {
	$source_user.MemberOf
}


# get target user groups
$target_users_groups = $target_user.MemberOf

# itterate groups the source user is a member of
foreach ( $source_group in $source_users_groups )
{
	$source_group_name = (Get-ADGroup $source_group).Name
	
	# compare each source users group against target users groups
    if ($target_users_groups -notcontains "$source_group") 
    {
        # if not there, do the thing.
        Write-Host "    Adding to group: $source_group_name" -ForegroundColor Yellow
        Add-ADGroupMember -Identity "$source_group" -Members $target_user
    }
    else 
    {
        # little courtesey message, not really necessary but nice.. I guess.
        Write-Host "    Already a member of: $source_group_name" -ForegroundColor DarkGray
    }
}

# STOP: Logging
Write-Host ""
Stop-Transcript | Out-Null