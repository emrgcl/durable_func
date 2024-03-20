param($results)

Write-Information "Received $($results.Count) outputs from parallel tasks."

foreach ($result in $results) {
   $result = [pscustomobject]$result
   write-information "result: $result"
}