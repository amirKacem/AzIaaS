| Resource Type               | ResourceType | Domain | Type | Roles | Location               | Environment | Organisation | Role | Seq#                   | Example           |
| --------------------------- | ------------ | ------ | ---- | ----- | ---------------------- | ----------- | ------------ | ---- | ---------------------- | ----------------- |
| Subscription                |              |        |      |       |                        |             |              |      |                        |                   |
| Resource group              | 2-4          |        |      |       | 3-4                    | 2           | 2-6          | 0    | 0                      | EusPdEnTCWRG      |
| Virtual Machine             | 2            | 2      | 2    | 2-4   | 3-4                    | 2           | 2-6          | 2    | 1-2                    | az-pc-dc          |
| Network Interface           | 2-4          |        |      |       | Virtual Machine        |             | 0            | 0    | EusPdEnTCWDbVm1Nic     |
| Network Security Group      | 2-4          |        |      |       | Virtual Machine        |             | 0            | 0    | EusPdEnTCWDbVm1Nsg     |
| Network Security Group Rule | 2-4          |        |      |       | Network Security Group |             | 0            | 1-2  | EusPdEnTCWDbVm1NsgR1   |
| Public IP Address           | 2-4          |        |      |       | Virtual Machine        |             | 0            | 1-2  | EusPdEnTCWDbVm1Pip     |
| Storage account name        | 2-4          |        |      |       | 3-4                    | 2           | 2-6          | 0    | 1-2                    | eus_pd_entcw_sa_1 |
| Storage Container name      | 2-4          |        |      |       | Storage account name   |             | 0            | 1-2  | eus_pd_entcw_sa_1_sc_1 |
| Blob name                   | 2-4          |        |      |       | Storage Container name |             | 0            | 1-2  |                        |
| Virtual Network             | 2-4          |        |      |       | 3-4                    | 2           | 2-6          | 0    | 1-2                    |                   |
| Load Balancer               |              |        |      |       |                        |             |              | 0    |                        |                   |