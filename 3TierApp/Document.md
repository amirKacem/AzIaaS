[Virtual Machines](% include VMs.md %)


* [Section 2](NSGRules.md)


[NSGRules.md]

#include "NSGRules.md"



Currently blocked by bug.
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