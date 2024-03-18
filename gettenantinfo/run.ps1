param($name)
Function new-tenantInfo{
    [CmdletBinding(
    )]
    Param(
        $TenantID,
        $ClientID,
        $Aztoken
    )
    [PSCustomObject]@{
        TenantID = $TenantID
        ClientID = $ClientID
        Aztoken = $Aztoken
    }
}

$results = @()
# run the function 3 times in a for loop
for ($i=0; $i -lt 10; $i++) {
    $results += new-tenantInfo -TenantID (New-Guid).Guid -ClientID (New-Guid).Guid -Aztoken (New-Guid).Guid
}

$results
