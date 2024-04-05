| Name       | Direction | SourceAddressPrefix | DestAddressPrefix  | DestPortRange | Description                                               |
|------------|-----------|---------------------|--------------------|---------------|-----------------------------------------------------------|
| WACService | Outbound  | VirtualNetwork      | WindowsAdminCenter | 443           | Open outbound port rule for WAC service                   |
| WAC        | Inbound   | *                   | *                  | 6516          | Open inbound port rule on VM to be able to connect to WAC |