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
#Write-Information "will invoke gettenantinfo"
$WorkBatch = Invoke-DurableActivity -FunctionName 'gettenantinfo'
#Write-Information "Received $($WorkBatch.Count) work items to process."

$ParallelTasks =
    foreach ($WorkItem in $WorkBatch) {
 #       write-information "Invoking invokedefenderscore for Tenant: '$($WorkItem.TenantID)'."
        Invoke-DurableActivity -FunctionName 'invokedefenderscore' -Input $WorkItem -NoWait
    }

$Outputs = Wait-ActivityFunction -Task $ParallelTasks
#Write-Information "Received $($Outputs.Count) outputs from parallel tasks."
# Aggregate all outputs and send the result to F3.
Invoke-DurableActivity -FunctionName 'processresults' -Input $Outputs
```

The issues I want to ask your support / advise

I start the function by doing `func start`. then I trigger the orchesttor function browing "http://localhost:7071/api/orchestrators/myorchestrator" in edge.

several things I want to clarify.
1. my acitivity functions returns pscustomobject but when I debug I notieced them they are returned as hashtables. This was weird...
1. Is there a way to see the queue behind the scenes for troublehsooting purposes because it looks like from the write-informations it run multiple times. For instance check the "INFORMATION: Received 10 work items to process." its been printed 3-4 times. Actually it should be printed per 1 orchestrator run.
1. Even though the output at line 17 is not empty (an array of hashtables) I got the null exception which can be found in the below text which is a full output.  

# Issue to discuss with the TA ( he and us knows him very well :) )
The processresults activity writes the information 10 time as expected but then we have an exception like below that the input parameter is null. 

```
[2024-03-20T11:58:38.651Z] ERROR: Value cannot be null. (Parameter 'input')
.
.
.
.
[2024-03-20T11:58:38.671Z] InvocationInfo        :
[2024-03-20T11:58:38.672Z]     MyCommand        : Invoke-DurableActivity
[2024-03-20T11:58:38.672Z]     ScriptLineNumber : 17
[2024-03-20T11:58:38.673Z]     OffsetInLine     : 1
[2024-03-20T11:58:38.674Z]     HistoryId        : 1
[2024-03-20T11:58:38.674Z]     ScriptName       : C:\Temp\durable_function\MyOrchestrator\run.ps1
[2024-03-20T11:58:38.675Z]     Line             : Invoke-DurableActivity -FunctionName 'processresults' -Input $Outputs
[2024-03-20T11:58:38.676Z]     PositionMessage  : At C:\Temp\durable_function\MyOrchestrator\run.ps1:17 char:1
[2024-03-20T11:58:38.676Z]                        + Invoke-DurableActivity -FunctionName 'processresults' -Input $Outputs

```
Result: ERROR: Value cannot be null. (Parameter 'input')
```


Below is a full text of the output:

```
Azure Functions Core Tools
Core Tools Version:       4.0.5571 Commit hash: N/A +9a5b604f0b846df7de3eb37b423a9eba8baa1152 (64-bit)
Function Runtime Version: 4.30.0.22097


Functions:

        HttpStart: [POST,GET] http://localhost:7071/api/orchestrators/{FunctionName}

        gettenantinfo: activityTrigger

        hello: activityTrigger

        invokedefenderscore: activityTrigger

        MyOrchestrator: orchestrationTrigger

        processresults: activityTrigger

For detailed output, run func with --verbose flag.
[2024-03-20T11:58:36.481Z] Worker process started and initialized.
[2024-03-20T11:58:37.232Z] Executing 'Functions.HttpStart' (Reason='This function was programmatically called via the host APIs.', Id=41007fe9-898e-4fe4-9b45-a7b9cde8e16b)
[2024-03-20T11:58:37.792Z] INFORMATION: Started orchestration with ID = 'dfe2fd4f-1d60-4a33-acf7-0a537686a724'
[2024-03-20T11:58:37.832Z] Executing 'Functions.MyOrchestrator' (Reason='(null)', Id=5277b659-7c62-4964-a6dd-16b3aae8cd88)
[2024-03-20T11:58:37.930Z] Executed 'Functions.HttpStart' (Succeeded, Id=41007fe9-898e-4fe4-9b45-a7b9cde8e16b, Duration=712ms)
[2024-03-20T11:58:37.932Z] Executed 'Functions.MyOrchestrator' (Succeeded, Id=5277b659-7c62-4964-a6dd-16b3aae8cd88, Duration=103ms)
[2024-03-20T11:58:37.977Z] Executing 'Functions.gettenantinfo' (Reason='(null)', Id=762b2b75-41d1-4c27-910f-548aedd618b7)
[2024-03-20T11:58:38.001Z] Executed 'Functions.gettenantinfo' (Succeeded, Id=762b2b75-41d1-4c27-910f-548aedd618b7, Duration=24ms)
[2024-03-20T11:58:38.074Z] Executing 'Functions.MyOrchestrator' (Reason='(null)', Id=6604d8bf-546d-488d-98e3-03895872a2df)
[2024-03-20T11:58:38.091Z] Executed 'Functions.MyOrchestrator' (Succeeded, Id=6604d8bf-546d-488d-98e3-03895872a2df, Duration=18ms)
[2024-03-20T11:58:38.121Z] Executing 'Functions.invokedefenderscore' (Reason='(null)', Id=f3f3f339-c32f-40ed-90b6-b151cee0a2c5)
[2024-03-20T11:58:38.128Z] INFORMATION: Inserting data for Tenant: 'b1c2d35c-a8bd-4789-8653-e51cd39c09ba' with ClientID: '431dc7ac-d97b-4727-83e7-98441755f984' and Aztoken: 'e3b09ffd-6d24-4a1c-8867-b98fe4dce779'.
[2024-03-20T11:58:38.129Z] Executed 'Functions.invokedefenderscore' (Succeeded, Id=f3f3f339-c32f-40ed-90b6-b151cee0a2c5, Duration=8ms)
[2024-03-20T11:58:38.142Z] Executing 'Functions.invokedefenderscore' (Reason='(null)', Id=92c9a9ae-206c-4613-bdd9-f63d94640413)
[2024-03-20T11:58:38.145Z] INFORMATION: Inserting data for Tenant: '9278fe5d-d7cf-42ca-a2f1-c4f1d1077165' with ClientID: 'ece35770-9e24-4c6e-9a9e-fb54a8f8c0d2' and Aztoken: '5ae80992-4ee0-4490-9bf6-3e21f76d0ac3'.
[2024-03-20T11:58:38.146Z] Executed 'Functions.invokedefenderscore' (Succeeded, Id=92c9a9ae-206c-4613-bdd9-f63d94640413, Duration=3ms)
[2024-03-20T11:58:38.150Z] Executing 'Functions.invokedefenderscore' (Reason='(null)', Id=b193d9a5-2e42-4f94-bf34-e82514b2569a)
[2024-03-20T11:58:38.153Z] INFORMATION: Inserting data for Tenant: '008bf624-a925-4825-8555-e14431c5a51b' with ClientID: 'b5c3ab2c-6612-4bc3-a57c-4bfd9847a828' and Aztoken: 'b1a26651-4791-452f-ae3a-4f9fe560bf39'.
[2024-03-20T11:58:38.153Z] Executed 'Functions.invokedefenderscore' (Succeeded, Id=b193d9a5-2e42-4f94-bf34-e82514b2569a, Duration=3ms)
[2024-03-20T11:58:38.159Z] Executing 'Functions.invokedefenderscore' (Reason='(null)', Id=f80ccd73-aabc-420e-a5cf-1e8189c408b0)
[2024-03-20T11:58:38.162Z] INFORMATION: Inserting data for Tenant: '434fd027-b316-4e15-9c25-dd62ce0974d4' with ClientID: '286a8222-3bf4-4e2d-9041-041b20e9fb42' and Aztoken: '12c907a9-5749-4f97-9914-e6658cb426f1'.
[2024-03-20T11:58:38.162Z] Executed 'Functions.invokedefenderscore' (Succeeded, Id=f80ccd73-aabc-420e-a5cf-1e8189c408b0, Duration=3ms)
[2024-03-20T11:58:38.170Z] Executing 'Functions.invokedefenderscore' (Reason='(null)', Id=856241c4-5ddf-45a5-aef2-c4bb43f42647)
[2024-03-20T11:58:38.172Z] INFORMATION: Inserting data for Tenant: 'dc2d3179-dd06-44bc-bc56-397f7f230585' with ClientID: 'd6b50cae-7ab1-4ed7-9fc3-4b8b3cc7ebe5' and Aztoken: 'c16af386-6c56-447d-8032-547b5f06ca1e'.
[2024-03-20T11:58:38.172Z] Executed 'Functions.invokedefenderscore' (Succeeded, Id=856241c4-5ddf-45a5-aef2-c4bb43f42647, Duration=2ms)
[2024-03-20T11:58:38.178Z] Executing 'Functions.invokedefenderscore' (Reason='(null)', Id=d55c6ab8-1fd6-41c5-9257-4a8d2042bc1a)
[2024-03-20T11:58:38.181Z] INFORMATION: Inserting data for Tenant: 'c98291e0-6f6b-4e6e-b635-f262d455f74b' with ClientID: '1e573ae8-4ee5-4187-a494-480a04537b6b' and Aztoken: '5ad6de4e-203f-4e1f-9886-41af3589150a'.
[2024-03-20T11:58:38.182Z] Executed 'Functions.invokedefenderscore' (Succeeded, Id=d55c6ab8-1fd6-41c5-9257-4a8d2042bc1a, Duration=3ms)
[2024-03-20T11:58:38.189Z] Executing 'Functions.invokedefenderscore' (Reason='(null)', Id=08f58ea2-440f-487e-bc8f-1384e68de81c)
[2024-03-20T11:58:38.191Z] INFORMATION: Inserting data for Tenant: '25e7ad04-550c-4ccd-b862-18b5ca2894c5' with ClientID: '46f7c955-697a-4608-8c84-f2606a5fcb73' and Aztoken: '6cdd5644-26f5-455e-bf41-11a395459cd7'.
[2024-03-20T11:58:38.192Z] Executed 'Functions.invokedefenderscore' (Succeeded, Id=08f58ea2-440f-487e-bc8f-1384e68de81c, Duration=3ms)
[2024-03-20T11:58:38.198Z] Executing 'Functions.invokedefenderscore' (Reason='(null)', Id=054eb6c6-59f7-46cc-b2bb-8e59803d0942)
[2024-03-20T11:58:38.200Z] INFORMATION: Inserting data for Tenant: '406f9f46-6f24-4b08-b5bb-6215c470fea0' with ClientID: '0eaf007b-6f1e-4b45-a105-e2608d4b1943' and Aztoken: '9a2fd010-cefd-499a-86e6-deeb6debfd72'.
[2024-03-20T11:58:38.201Z] Executed 'Functions.invokedefenderscore' (Succeeded, Id=054eb6c6-59f7-46cc-b2bb-8e59803d0942, Duration=3ms)
[2024-03-20T11:58:38.206Z] Executing 'Functions.invokedefenderscore' (Reason='(null)', Id=c9b3a49f-4d33-4588-b621-5d4d32908c63)
[2024-03-20T11:58:38.208Z] INFORMATION: Inserting data for Tenant: '4037f73a-d454-47f6-b0db-dc9d8525f604' with ClientID: '31a26042-3dc5-4571-b158-49396e69cbd8' and Aztoken: '6d556b53-cde4-478b-82d7-db8884bd0958'.
[2024-03-20T11:58:38.209Z] Executed 'Functions.invokedefenderscore' (Succeeded, Id=c9b3a49f-4d33-4588-b621-5d4d32908c63, Duration=3ms)
[2024-03-20T11:58:38.216Z] Executing 'Functions.invokedefenderscore' (Reason='(null)', Id=3cc71585-2230-4e06-8f2f-ea839df44fc7)
[2024-03-20T11:58:38.219Z] INFORMATION: Inserting data for Tenant: '88107eb8-d4c7-4259-ad52-e35e8dc20adb' with ClientID: '7aba7786-fbcb-4caf-8cd4-b5898d232216' and Aztoken: '0e1c173b-982f-457f-91a6-8a4e35d20929'.
[2024-03-20T11:58:38.219Z] Executed 'Functions.invokedefenderscore' (Succeeded, Id=3cc71585-2230-4e06-8f2f-ea839df44fc7, Duration=3ms)
[2024-03-20T11:58:38.270Z] Executing 'Functions.MyOrchestrator' (Reason='(null)', Id=5042261e-64f1-4348-bbac-16ee4cf62d44)
[2024-03-20T11:58:38.275Z] Executed 'Functions.MyOrchestrator' (Succeeded, Id=5042261e-64f1-4348-bbac-16ee4cf62d44, Duration=5ms)
[2024-03-20T11:58:38.293Z] Executing 'Functions.processresults' (Reason='(null)', Id=0e11ea05-5c2b-4de2-bfeb-c4e7effebc59)
[2024-03-20T11:58:38.308Z] INFORMATION: Received 10 outputs from parallel tasks.
[2024-03-20T11:58:38.310Z] INFORMATION: result: @{TenantID=dc2d3179-dd06-44bc-bc56-397f7f230585; status=success}
[2024-03-20T11:58:38.310Z] INFORMATION: result: @{TenantID=008bf624-a925-4825-8555-e14431c5a51b; status=success}
[2024-03-20T11:58:38.311Z] INFORMATION: result: @{TenantID=406f9f46-6f24-4b08-b5bb-6215c470fea0; status=success}
[2024-03-20T11:58:38.311Z] INFORMATION: result: @{TenantID=9278fe5d-d7cf-42ca-a2f1-c4f1d1077165; status=success}
[2024-03-20T11:58:38.310Z] INFORMATION: result: @{TenantID=b1c2d35c-a8bd-4789-8653-e51cd39c09ba; status=success}
[2024-03-20T11:58:38.312Z] Executed 'Functions.processresults' (Succeeded, Id=0e11ea05-5c2b-4de2-bfeb-c4e7effebc59, Duration=19ms)
[2024-03-20T11:58:38.311Z] INFORMATION: result: @{TenantID=25e7ad04-550c-4ccd-b862-18b5ca2894c5; status=success}
[2024-03-20T11:58:38.311Z] INFORMATION: result: @{TenantID=c98291e0-6f6b-4e6e-b635-f262d455f74b; status=success}
[2024-03-20T11:58:38.311Z] INFORMATION: result: @{TenantID=4037f73a-d454-47f6-b0db-dc9d8525f604; status=success}
[2024-03-20T11:58:38.311Z] INFORMATION: result: @{TenantID=434fd027-b316-4e15-9c25-dd62ce0974d4; status=success}
[2024-03-20T11:58:38.439Z] Executing 'Functions.MyOrchestrator' (Reason='(null)', Id=d1c91cab-6d44-415b-af3d-6077a995b9c3)
[2024-03-20T11:58:38.651Z] ERROR: Value cannot be null. (Parameter 'input')
[2024-03-20T11:58:38.652Z] Executed 'Functions.MyOrchestrator' (Succeeded, Id=d1c91cab-6d44-415b-af3d-6077a995b9c3, Duration=212ms)
[2024-03-20T11:58:38.652Z]
[2024-03-20T11:58:38.653Z] Exception             :
[2024-03-20T11:58:38.654Z]     Type       : System.ArgumentNullException
[2024-03-20T11:58:38.655Z]     Message    : Value cannot be null. (Parameter 'input')
[2024-03-20T11:58:38.656Z]     ParamName  : input
[2024-03-20T11:58:38.656Z]     TargetSite :
[2024-03-20T11:58:38.657Z]         Name          : ConvertFromJson
[2024-03-20T11:58:38.658Z]         DeclaringType : Microsoft.PowerShell.Commands.JsonObject
[2024-03-20T11:58:38.659Z]         MemberType    : Method
[2024-03-20T11:58:38.660Z]         Module        : Microsoft.PowerShell.Commands.Utility.dll
[2024-03-20T11:58:38.660Z]     Source     : Microsoft.PowerShell.Commands.Utility
[2024-03-20T11:58:38.661Z]     HResult    : -2147467261
[2024-03-20T11:58:38.662Z]     StackTrace :
[2024-03-20T11:58:38.662Z]    at Microsoft.PowerShell.Commands.JsonObject.ConvertFromJson(String input, Boolean returnHashtable, Nullable`1 maxDepth, ErrorRecord& error)
[2024-03-20T11:58:38.663Z]    at Microsoft.PowerShell.Commands.JsonObject.ConvertFromJson(String input, Boolean returnHashtable, ErrorRecord& error)
[2024-03-20T11:58:38.664Z]    at Microsoft.Azure.Functions.PowerShellWorker.Utility.TypeExtensions.ConvertFromJson(String json) in /mnt/vss/_work/1/s/src/Utility/TypeExtensions.cs:line 118
[2024-03-20T11:58:38.665Z]    at Microsoft.Azure.Functions.PowerShellWorker.Durable.DurableTaskHandler.GetEventResult(HistoryEvent historyEvent) in /mnt/vss/_work/1/s/src/DurableSDK/DurableTaskHandler.cs:line 235
[2024-03-20T11:58:38.666Z]    at Microsoft.Azure.Functions.PowerShellWorker.Durable.DurableTaskHandler.StopAndInitiateDurableTaskOrReplay(DurableTask task, OrchestrationContext context, Boolean noWait, Action`1 output, Action`1 onFailure, RetryOptions retryOptions) in /mnt/vss/_work/1/s/src/DurableSDK/DurableTaskHandler.cs:line 55
[2024-03-20T11:58:38.667Z]    at Microsoft.Azure.Functions.PowerShellWorker.Durable.Commands.InvokeDurableActivityCommand.EndProcessing() in /mnt/vss/_work/1/s/src/DurableSDK/Commands/InvokeDurableActivityCommand.cs:line 51
[2024-03-20T11:58:38.668Z]    at System.Management.Automation.Cmdlet.DoEndProcessing()
[2024-03-20T11:58:38.669Z]    at System.Management.Automation.CommandProcessorBase.Complete()
[2024-03-20T11:58:38.669Z] CategoryInfo          : NotSpecified: (:) [Invoke-DurableActivity], ArgumentNullException
[2024-03-20T11:58:38.670Z] FullyQualifiedErrorId : System.ArgumentNullException,Microsoft.Azure.Functions.PowerShellWorker.Durable.Commands.InvokeDurableActivityCommand
[2024-03-20T11:58:38.671Z] InvocationInfo        :
[2024-03-20T11:58:38.672Z]     MyCommand        : Invoke-DurableActivity
[2024-03-20T11:58:38.672Z]     ScriptLineNumber : 17
[2024-03-20T11:58:38.673Z]     OffsetInLine     : 1
[2024-03-20T11:58:38.674Z]     HistoryId        : 1
[2024-03-20T11:58:38.674Z]     ScriptName       : C:\Temp\durable_function\MyOrchestrator\run.ps1
[2024-03-20T11:58:38.675Z]     Line             : Invoke-DurableActivity -FunctionName 'processresults' -Input $Outputs
[2024-03-20T11:58:38.676Z]     PositionMessage  : At C:\Temp\durable_function\MyOrchestrator\run.ps1:17 char:1
[2024-03-20T11:58:38.676Z]                        + Invoke-DurableActivity -FunctionName 'processresults' -Input $Outputs
[2024-03-20T11:58:38.677Z]                        + ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
[2024-03-20T11:58:38.677Z]     PSScriptRoot     : C:\Temp\durable_function\MyOrchestrator
[2024-03-20T11:58:38.678Z]     PSCommandPath    : C:\Temp\durable_function\MyOrchestrator\run.ps1
[2024-03-20T11:58:38.679Z]     InvocationName   : Invoke-DurableActivity
[2024-03-20T11:58:38.680Z]     CommandOrigin    : Internal
[2024-03-20T11:58:38.680Z] ScriptStackTrace      : at <ScriptBlock>, C:\Temp\durable_function\MyOrchestrator\run.ps1: line 17
[2024-03-20T11:58:38.681Z]
[2024-03-20T11:58:38.681Z]
[2024-03-20T11:58:38.682Z] Result: ERROR: Value cannot be null. (Parameter 'input')
[2024-03-20T11:58:38.683Z]
[2024-03-20T11:58:38.683Z] Exception             :
[2024-03-20T11:58:38.684Z]     Type       : System.ArgumentNullException
[2024-03-20T11:58:38.684Z]     Message    : Value cannot be null. (Parameter 'input')
[2024-03-20T11:58:38.685Z]     ParamName  : input
[2024-03-20T11:58:38.686Z]     TargetSite :
[2024-03-20T11:58:38.686Z]         Name          : ConvertFromJson
[2024-03-20T11:58:38.687Z]         DeclaringType : Microsoft.PowerShell.Commands.JsonObject
[2024-03-20T11:58:38.688Z]         MemberType    : Method
[2024-03-20T11:58:38.689Z]         Module        : Microsoft.PowerShell.Commands.Utility.dll
[2024-03-20T11:58:38.689Z]     Source     : Microsoft.PowerShell.Commands.Utility
[2024-03-20T11:58:38.690Z]     HResult    : -2147467261
[2024-03-20T11:58:38.690Z]     StackTrace :
[2024-03-20T11:58:38.691Z]    at Microsoft.PowerShell.Commands.JsonObject.ConvertFromJson(String input, Boolean returnHashtable, Nullable`1 maxDepth, ErrorRecord& error)
[2024-03-20T11:58:38.692Z]    at Microsoft.PowerShell.Commands.JsonObject.ConvertFromJson(String input, Boolean returnHashtable, ErrorRecord& error)
[2024-03-20T11:58:38.693Z]    at Microsoft.Azure.Functions.PowerShellWorker.Utility.TypeExtensions.ConvertFromJson(String json) in /mnt/vss/_work/1/s/src/Utility/TypeExtensions.cs:line 118
[2024-03-20T11:58:38.693Z]    at Microsoft.Azure.Functions.PowerShellWorker.Durable.DurableTaskHandler.GetEventResult(HistoryEvent historyEvent) in /mnt/vss/_work/1/s/src/DurableSDK/DurableTaskHandler.cs:line 235
[2024-03-20T11:58:38.694Z]    at Microsoft.Azure.Functions.PowerShellWorker.Durable.DurableTaskHandler.StopAndInitiateDurableTaskOrReplay(DurableTask task, OrchestrationContext context, Boolean noWait, Action`1 output, Action`1 onFailure, RetryOptions retryOptions) in /mnt/vss/_work/1/s/src/DurableSDK/DurableTaskHandler.cs:line 55
[2024-03-20T11:58:38.695Z]    at Microsoft.Azure.Functions.PowerShellWorker.Durable.Commands.InvokeDurableActivityCommand.EndProcessing() in /mnt/vss/_work/1/s/src/DurableSDK/Commands/InvokeDurableActivityCommand.cs:line 51
[2024-03-20T11:58:38.695Z]    at System.Management.Automation.Cmdlet.DoEndProcessing()
[2024-03-20T11:58:38.696Z]    at System.Management.Automation.CommandProcessorBase.Complete()
[2024-03-20T11:58:38.697Z] CategoryInfo          : NotSpecified: (:) [Invoke-DurableActivity], ArgumentNullException
[2024-03-20T11:58:38.698Z] FullyQualifiedErrorId : System.ArgumentNullException,Microsoft.Azure.Functions.PowerShellWorker.Durable.Commands.InvokeDurableActivityCommand
[2024-03-20T11:58:38.699Z] InvocationInfo        :
[2024-03-20T11:58:38.699Z]     MyCommand        : Invoke-DurableActivity
[2024-03-20T11:58:38.700Z]     ScriptLineNumber : 17
[2024-03-20T11:58:38.701Z]     OffsetInLine     : 1
[2024-03-20T11:58:38.702Z]     HistoryId        : 1
[2024-03-20T11:58:38.702Z]     ScriptName       : C:\Temp\durable_function\MyOrchestrator\run.ps1
[2024-03-20T11:58:38.703Z]     Line             : Invoke-DurableActivity -FunctionName 'processresults' -Input $Outputs
[2024-03-20T11:58:38.704Z]     PositionMessage  : At C:\Temp\durable_function\MyOrchestrator\run.ps1:17 char:1
[2024-03-20T11:58:38.704Z]                        + Invoke-DurableActivity -FunctionName 'processresults' -Input $Outputs
[2024-03-20T11:58:38.705Z]                        + ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
[2024-03-20T11:58:38.706Z]     PSScriptRoot     : C:\Temp\durable_function\MyOrchestrator
[2024-03-20T11:58:38.706Z]     PSCommandPath    : C:\Temp\durable_function\MyOrchestrator\run.ps1
[2024-03-20T11:58:38.707Z]     InvocationName   : Invoke-DurableActivity
[2024-03-20T11:58:38.708Z]     CommandOrigin    : Internal
[2024-03-20T11:58:38.708Z] ScriptStackTrace      : at <ScriptBlock>, C:\Temp\durable_function\MyOrchestrator\run.ps1: line 17
[2024-03-20T11:58:38.709Z]
[2024-03-20T11:58:38.709Z]
Exception: Value cannot be null. (Parameter 'input')
Stack:    at Microsoft.PowerShell.Commands.JsonObject.ConvertFromJson(String input, Boolean returnHashtable, Nullable`1 maxDepth, ErrorRecord& error)
[2024-03-20T11:58:38.710Z]    at Microsoft.PowerShell.Commands.JsonObject.ConvertFromJson(String input, Boolean returnHashtable, ErrorRecord& error)
[2024-03-20T11:58:38.711Z]    at Microsoft.Azure.Functions.PowerShellWorker.Utility.TypeExtensions.ConvertFromJson(String json) in /mnt/vss/_work/1/s/src/Utility/TypeExtensions.cs:line 118
[2024-03-20T11:58:38.711Z]    at Microsoft.Azure.Functions.PowerShellWorker.Durable.DurableTaskHandler.GetEventResult(HistoryEvent historyEvent) in /mnt/vss/_work/1/s/src/DurableSDK/DurableTaskHandler.cs:line 235
[2024-03-20T11:58:38.712Z]    at Microsoft.Azure.Functions.PowerShellWorker.Durable.DurableTaskHandler.StopAndInitiateDurableTaskOrReplay(DurableTask task, OrchestrationContext context, Boolean noWait, Action`1 output, Action`1 onFailure, RetryOptions retryOptions) in /mnt/vss/_work/1/s/src/DurableSDK/DurableTaskHandler.cs:line 55
[2024-03-20T11:58:38.713Z]    at Microsoft.Azure.Functions.PowerShellWorker.Durable.Commands.InvokeDurableActivityCommand.EndProcessing() in /mnt/vss/_work/1/s/src/DurableSDK/Commands/InvokeDurableActivityCommand.cs:line 51
[2024-03-20T11:58:38.714Z]    at System.Management.Automation.Cmdlet.DoEndProcessing()
[2024-03-20T11:58:38.715Z]    at System.Management.Automation.CommandProcessorBase.Complete().
[2024-03-20T11:58:44.309Z] Host lock lease acquired by instance ID '00000000000000000000000056E42344'.
```

Meeting Notes
 - orchestartor goes back to line 1 after each activity invocation.
 - the history can be purged via the api purgeHistoryDeleteUri
 - you can also create a fresh history by renaming the durabletask/hubname in the host.json file