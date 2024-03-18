param($results)

foreach ($result in $results) {
   $result = [pscustomobject]$result
   write-information "result: $result"
}