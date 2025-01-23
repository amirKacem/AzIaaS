# Three Tier Applicaiton Infrastructure deployment in Azure

This is deploying a [three-tier application architecture][1] on virtual machines in Azure. 

<details>
<summary><u>Naming Standard</u></summary>
<div style="display:flex;gap:3rem">
[Naming Convention] (% include https://raw.githubusercontent.com/Ayanmullick/AzIaaS/refs/heads/main/3TierApp/NamingConvention.md %)
[Abbreviatons] (% include https://raw.githubusercontent.com/Ayanmullick/AzIaaS/refs/heads/main/3TierApp/Abbreviations.md %) 
</div>
</details>



[Virtual Machines] (% include https://raw.githubusercontent.com/Ayanmullick/AzIaaS/refs/heads/main/3TierApp/VMs.md %) 


[Network Security Group Rules] (% include https://raw.githubusercontent.com/Ayanmullick/AzIaaS/refs/heads/main/3TierApp/NsgRules.md %) 



<script>
  var allowedVariables = ["GovernanceResources", "NetworkResources", "OutputForNextJob"];
  var fetchRes = fetch("https://raw.githubusercontent.com/Ayanmullick/AzIaaS/refs/heads/main/3TierApp/GovResource.ps1")
  fetchRes.then(response => response.clone().text()).then(data => {
    showBlocks(data,allowedVariables);
  })
</script>


This prestages the governance resources in Azure for the VMs' Deployment job.


<details open>
<summary><u id="GovernanceResources"></u></summary> <pre class="powershell" id="code0"></pre>
</details>

This prestages the Network resources in Azure for the VMs' Deployment job.


<details open>
<summary><u id="NetworkResources"></u></summary> <pre class="powershell" id="code1"></pre>
</details>


This passes the resources' details between the Governance resources and the VM deployment jobs in the GitHub Actions workflow.

<details open>
<summary><u id="OutputForNextJob"></u></summary> <pre class="powershell" id="code2"></pre>
</details>


Here is a link to the [Governance resources deployment execution](https://ayanmullick.github.io/AzIaaS/Render/LogRender.html?path=https://raw.githubusercontent.com/Ayanmullick/AzIaaS/refs/heads/main/3TierApp/AzPSImageInfraDeploymentWithApproval%20GovernanceResourcesJob.log)


<script>
  var allowedVariables = ["VirtualMachineCreation"];
  var fetchRes = fetch("https://raw.githubusercontent.com/Ayanmullick/AzIaaS/refs/heads/main/3TierApp/VMs.ps1")
  fetchRes.then(response => response.clone().text()).then(data => {
    showBlocks(data,allowedVariables);
  })
</script>

This deploys the required virtual machines in the same resource group using the previously prestaged governance resources.

<details open>
<summary><u id="VirtualMachineCreation"></u></summary> <pre class="powershell" id="code3"></pre>
</details>


[VM deployment execution](https://ayanmullick.github.io/AzIaaS/Render/LogRender.html?path=https://raw.githubusercontent.com/Ayanmullick/AzIaaS/refs/heads/main/3TierApp/AzPSImageInfraDeploymentWithApproval%20DeployVirtualMachines.log)



Sparse checkout is currently blocked by bug.
https://github.com/actions/checkout/issues/1602#issuecomment-2048656906
Resume once the 'Deploy Virtual machines' step in the 'AzPSImageInfraDeploymentWithApproval' workflow populates the resource group name in the end correctly.

 
Potential Tables: vNet details, NSG rules, VM details, storage account restrictions

RG name, KV, Sa, secret, admin name, 

Put your tabularizable configuration in a markdown table. And the other configurations in a hash table.
You get a single source of truth for configuration and documentation.
And adding to configuration doesn't require you to add to the code

= Correct, Deterministic, Efficient, Robust, Maintainable, Testable, Reliable, Reusable, Flexible, Scalable, Secure, BAU\BC lang parity
https://www.geeksforgeeks.org/software-engineering-characteristics-of-good-software
https://biosistemika.com/blog/dont-save-on-quality-key-attributes-of-software

≠ Idempotent\Incremental,Stateless  #How many orders of magnitude more lines of code just for this


[1]: <https://learn.microsoft.com/en-us/azure/architecture/guide/architecture-styles/#n-tier>