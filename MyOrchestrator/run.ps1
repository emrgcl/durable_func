param($Context)

# Get a list of work items to process in parallel.
$WorkBatch = Invoke-DurableActivity -FunctionName 'gettenantinfo'
Write-Information "Received $($WorkBatch.Count) work items to process."

$ParallelTasks =
    foreach ($WorkItem in $WorkBatch) {
        write-information "Invoking invokedefenderscore for Tenant: '$($WorkItem.TenantID)'."
        Invoke-DurableActivity -FunctionName 'invokedefenderscore' -Input $WorkItem -NoWait
    }

$Outputs = Wait-ActivityFunction -Task $ParallelTasks
Write-Information "Received $($Outputs.Count) outputs from parallel tasks."
foreach ($Output in $Outputs) {
    Write-Information "Received output: $($Output.Keys -join ',')"
}

# Aggregate all outputs and send the result to F3.
Invoke-DurableActivity -FunctionName 'processresults' -Input $Outputs