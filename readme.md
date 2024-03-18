# durable function test

I am trying to mimic a durable function with a [fan out/in](https://learn.microsoft.com/en-us/azure/azure-functions/durable/durable-functions-overview?tabs=in-process%2Cnodejs-v3%2Cv1-model&pivots=powershell#fan-in-out) pattern. 

My setup is currently local 

Core Tools Version:       4.0.5571
Function Runtime Version: 4.30.0.22097

I have 4 functions. 

1. myorchestreator: This is the orchestreator function
1. gettenantinfo: this is the activity that gathers information to be passed to invokedefenderscore.
1. invokedefenderscore: This is the activity that the orchestrator calls for parelel processing. 
1. process results: this is the activity that runs when all the invokedefenderscore acitivites finish.

You can find the functions in their respective folders but for the sake of readability I added the my orchesatrator function below.

```powershell
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
```

The issues I want to ask your support / advise

I start the function by doing `func start`. then I trigger the orchesttor function browing "http://localhost:7071/api/orchestrators/myorchestrator" in edge.

several things I want to clarify.
1. my acitivity functions returns pscustomobject but when I debug I notieced them they are returned as hashtables. This was weird...
1. Is there a way to see the queue behind the scenes for troublehsooting purposes because it looks like from the write-informations it run multiple times. For instance check the "INFORMATION: Received 10 work items to process." its been printed 3-4 times. Actually it should be printed per 1 orchestrator run.
1. Even though the output at line 20 is not empty (an array of hashtables) I got the null exception which can be found in the below text which is a full output.  

Below is a full text of the output:

```
024-03-18T12:00:13.657Z] INFORMATION: Invoking invokedefenderscore for Tenant: '926b14dc-33ef-4624-90c3-4bb6f5241522'.
[2024-03-18T12:00:13.989Z] ERROR: Value cannot be null. (Parameter 'input')
[2024-03-18T12:00:13.990Z]
[2024-03-18T12:00:13.990Z] Exception             :
[2024-03-18T12:00:13.990Z] Executed 'Functions.MyOrchestrator' (Succeeded, Id=f5522a1b-45ad-4e23-ac43-59bb8c2a8cc1, Duration=337ms)
[2024-03-18T12:00:13.990Z]     Type       : System.ArgumentNullException
[2024-03-18T12:00:13.992Z]     Message    : Value cannot be null. (Parameter 'input')
[2024-03-18T12:00:13.992Z]     ParamName  : input
[2024-03-18T12:00:13.993Z]     TargetSite :
[2024-03-18T12:00:13.993Z]         Name          : ConvertFromJson
[2024-03-18T12:00:13.994Z]         DeclaringType : Microsoft.PowerShell.Commands.JsonObject
[2024-03-18T12:00:13.994Z]         MemberType    : Method
[2024-03-18T12:00:13.995Z]         Module        : Microsoft.PowerShell.Commands.Utility.dll
[2024-03-18T12:00:13.995Z]     Source     : Microsoft.PowerShell.Commands.Utility
[2024-03-18T12:00:13.996Z]     HResult    : -2147467261
[2024-03-18T12:00:13.996Z]     StackTrace :
[2024-03-18T12:00:13.997Z]    at Microsoft.PowerShell.Commands.JsonObject.ConvertFromJson(String input, Boolean returnHashtable, Nullable`1 maxDepth, ErrorRecord& error)
[2024-03-18T12:00:13.998Z]    at Microsoft.PowerShell.Commands.JsonObject.ConvertFromJson(String input, Boolean returnHashtable, ErrorRecord& error)
[2024-03-18T12:00:13.998Z]    at Microsoft.Azure.Functions.PowerShellWorker.Utility.TypeExtensions.ConvertFromJson(String json) in /mnt/vss/_work/1/s/src/Utility/TypeExtensions.cs:line 118
[2024-03-18T12:00:13.999Z]    at Microsoft.Azure.Functions.PowerShellWorker.Durable.DurableTaskHandler.GetEventResult(HistoryEvent historyEvent) in /mnt/vss/_work/1/s/src/DurableSDK/DurableTaskHandler.cs:line 235
[2024-03-18T12:00:13.999Z]    at Microsoft.Azure.Functions.PowerShellWorker.Durable.DurableTaskHandler.StopAndInitiateDurableTaskOrReplay(DurableTask task, OrchestrationContext context, Boolean noWait, Action`1 output, Action`1 onFailure, RetryOptions retryOptions) in /mnt/vss/_work/1/s/src/DurableSDK/DurableTaskHandler.cs:line 55
[2024-03-18T12:00:14.000Z]    at Microsoft.Azure.Functions.PowerShellWorker.Durable.Commands.InvokeDurableActivityCommand.EndProcessing() in /mnt/vss/_work/1/s/src/DurableSDK/Commands/InvokeDurableActivityCommand.cs:line 51
[2024-03-18T12:00:14.001Z]    at System.Management.Automation.Cmdlet.DoEndProcessing()
[2024-03-18T12:00:14.001Z]    at System.Management.Automation.CommandProcessorBase.Complete()
[2024-03-18T12:00:14.002Z] CategoryInfo          : NotSpecified: (:) [Invoke-DurableActivity], ArgumentNullException
[2024-03-18T12:00:14.002Z] FullyQualifiedErrorId : System.ArgumentNullException,Microsoft.Azure.Functions.PowerShellWorker.Durable.Commands.InvokeDurableActivityCommand
[2024-03-18T12:00:14.003Z] InvocationInfo        :
[2024-03-18T12:00:14.003Z]     MyCommand        : Invoke-DurableActivity
[2024-03-18T12:00:14.004Z]     ScriptLineNumber : 20
[2024-03-18T12:00:14.005Z]     OffsetInLine     : 1
[2024-03-18T12:00:14.005Z]     HistoryId        : 1
[2024-03-18T12:00:14.006Z]     ScriptName       : C:\Temp\durable_function\MyOrchestrator\run.ps1
[2024-03-18T12:00:14.006Z]     Line             : Invoke-DurableActivity -FunctionName 'processresults' -Input $Outputs
[2024-03-18T12:00:14.007Z]     PositionMessage  : At C:\Temp\durable_function\MyOrchestrator\run.ps1:20 char:1
[2024-03-18T12:00:14.007Z]                        + Invoke-DurableActivity -FunctionName 'processresults' -Input $Outputs
[2024-03-18T12:00:14.008Z]                        + ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
[2024-03-18T12:00:14.008Z]     PSScriptRoot     : C:\Temp\durable_function\MyOrchestrator
[2024-03-18T12:00:14.009Z]     PSCommandPath    : C:\Temp\durable_function\MyOrchestrator\run.ps1
[2024-03-18T12:00:14.009Z]     InvocationName   : Invoke-DurableActivity
[2024-03-18T12:00:14.010Z]     CommandOrigin    : Internal
[2024-03-18T12:00:14.011Z] ScriptStackTrace      : at <ScriptBlock>, C:\Temp\durable_function\MyOrchestrator\run.ps1: line 20
[2024-03-18T12:00:14.011Z]
[2024-03-18T12:00:14.012Z]
[2024-03-18T12:00:14.012Z] Result: ERROR: Value cannot be null. (Parameter 'input')
[2024-03-18T12:00:14.013Z]
[2024-03-18T12:00:14.013Z] Exception             :
[2024-03-18T12:00:14.014Z]     Type       : System.ArgumentNullException
[2024-03-18T12:00:14.014Z]     Message    : Value cannot be null. (Parameter 'input')
[2024-03-18T12:00:14.015Z]     ParamName  : input
[2024-03-18T12:00:14.015Z]     TargetSite : 
[2024-03-18T12:00:14.016Z]         Name          : ConvertFromJson
[2024-03-18T12:00:14.017Z]         DeclaringType : Microsoft.PowerShell.Commands.JsonObject
[2024-03-18T12:00:14.018Z]         MemberType    : Method
[2024-03-18T12:00:14.018Z]         Module        : Microsoft.PowerShell.Commands.Utility.dll
[2024-03-18T12:00:14.019Z]     Source     : Microsoft.PowerShell.Commands.Utility
[2024-03-18T12:00:14.020Z]     HResult    : -2147467261
[2024-03-18T12:00:14.020Z]     StackTrace :
[2024-03-18T12:00:14.021Z]    at Microsoft.PowerShell.Commands.JsonObject.ConvertFromJson(String input, Boolean returnHashtable, Nullable`1 maxDepth, ErrorRecord& error)
[2024-03-18T12:00:14.022Z]    at Microsoft.PowerShell.Commands.JsonObject.ConvertFromJson(String input, Boolean returnHashtable, ErrorRecord& error)
[2024-03-18T12:00:14.023Z]    at Microsoft.Azure.Functions.PowerShellWorker.Utility.TypeExtensions.ConvertFromJson(String json) in /mnt/vss/_work/1/s/src/Utility/TypeExtensions.cs:line 118
[2024-03-18T12:00:14.024Z]    at Microsoft.Azure.Functions.PowerShellWorker.Durable.DurableTaskHandler.GetEventResult(HistoryEvent historyEvent) in /mnt/vss/_work/1/s/src/DurableSDK/DurableTaskHandler.cs:line 235
[2024-03-18T12:00:14.025Z]    at Microsoft.Azure.Functions.PowerShellWorker.Durable.DurableTaskHandler.StopAndInitiateDurableTaskOrReplay(DurableTask task, OrchestrationContext context, Boolean noWait, Action`1 output, Action`1 onFailure, RetryOptions retryOptions) in /mnt/vss/_work/1/s/src/DurableSDK/DurableTaskHandler.cs:line 55
[2024-03-18T12:00:14.026Z]    at Microsoft.Azure.Functions.PowerShellWorker.Durable.Commands.InvokeDurableActivityCommand.EndProcessing() in /mnt/vss/_work/1/s/src/DurableSDK/Commands/InvokeDurableActivityCommand.cs:line 51
[2024-03-18T12:00:14.026Z]    at System.Management.Automation.Cmdlet.DoEndProcessing()
[2024-03-18T12:00:14.027Z]    at System.Management.Automation.CommandProcessorBase.Complete()
[2024-03-18T12:00:14.028Z] CategoryInfo          : NotSpecified: (:) [Invoke-DurableActivity], ArgumentNullException
[2024-03-18T12:00:14.028Z] FullyQualifiedErrorId : System.ArgumentNullException,Microsoft.Azure.Functions.PowerShellWorker.Durable.Commands.InvokeDurableActivityCommand
[2024-03-18T12:00:14.029Z] InvocationInfo        :
[2024-03-18T12:00:14.030Z]     MyCommand        : Invoke-DurableActivity
[2024-03-18T12:00:14.031Z]     ScriptLineNumber : 20
[2024-03-18T12:00:14.031Z]     OffsetInLine     : 1
[2024-03-18T12:00:14.032Z]     HistoryId        : 1
[2024-03-18T12:00:14.033Z]     ScriptName       : C:\Temp\durable_function\MyOrchestrator\run.ps1
[2024-03-18T12:00:14.033Z]     Line             : Invoke-DurableActivity -FunctionName 'processresults' -Input $Outputs
[2024-03-18T12:00:14.034Z]     PositionMessage  : At C:\Temp\durable_function\MyOrchestrator\run.ps1:20 char:1
[2024-03-18T12:00:14.035Z]                        + Invoke-DurableActivity -FunctionName 'processresults' -Input $Outputs
[2024-03-18T12:00:14.035Z]                        + ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
[2024-03-18T12:00:14.036Z]     PSScriptRoot     : C:\Temp\durable_function\MyOrchestrator
[2024-03-18T12:00:14.036Z]     PSCommandPath    : C:\Temp\durable_function\MyOrchestrator\run.ps1
[2024-03-18T12:00:14.037Z]     InvocationName   : Invoke-DurableActivity
[2024-03-18T12:00:14.038Z]     CommandOrigin    : Internal
[2024-03-18T12:00:14.039Z] ScriptStackTrace      : at <ScriptBlock>, C:\Temp\durable_function\MyOrchestrator\run.ps1: line 20
[2024-03-18T12:00:14.039Z]
[2024-03-18T12:00:14.040Z]
Exception: Value cannot be null. (Parameter 'input')
Stack:    at Microsoft.PowerShell.Commands.JsonObject.ConvertFromJson(String input, Boolean returnHashtable, Nullable`1 maxDepth, ErrorRecord& error)
[2024-03-18T12:00:14.040Z]    at Microsoft.PowerShell.Commands.JsonObject.ConvertFromJson(String input, Boolean returnHashtable, ErrorRecord& error)
[2024-03-18T12:00:14.041Z]    at Microsoft.Azure.Functions.PowerShellWorker.Utility.TypeExtensions.ConvertFromJson(String json) in /mnt/vss/_work/1/s/src/Utility/TypeExtensions.cs:line 118
[2024-03-18T12:00:14.042Z]    at Microsoft.Azure.Functions.PowerShellWorker.Durable.DurableTaskHandler.GetEventResult(HistoryEvent historyEvent) in /mnt/vss/_work/1/s/src/DurableSDK/DurableTaskHandler.cs:line 235
[2024-03-18T12:00:14.042Z]    at Microsoft.Azure.Functions.PowerShellWorker.Durable.DurableTaskHandler.StopAndInitiateDurableTaskOrReplay(DurableTask task, OrchestrationContext context, Boolean noWait, Action`1 output, Action`1 onFailure, RetryOptions retryOptions) in /mnt/vss/_work/1/s/src/DurableSDK/DurableTaskHandler.cs:line 55
[2024-03-18T12:00:14.043Z]    at Microsoft.Azure.Functions.PowerShellWorker.Durable.Commands.InvokeDurableActivityCommand.EndProcessing() in /mnt/vss/_work/1/s/src/DurableSDK/Commands/InvokeDurableActivityCommand.cs:line 51
[2024-03-18T12:00:14.044Z]    at System.Management.Automation.Cmdlet.DoEndProcessing()
[2024-03-18T12:00:14.044Z]    at System.Management.Automation.CommandProcessorBase.Complete().
```