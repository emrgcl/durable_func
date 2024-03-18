param($TenantInfo)

write-information "Inserting data for Tenant: '$($TenantInfo.TenantID)' with ClientID: '$($TenantInfo.ClientID)' and Aztoken: '$($TenantInfo.Aztoken)'."

$result = [pscustomobject]@{ 
    TenantID = $TenantInfo.TenantID
    status = 'success'
}
$Result
