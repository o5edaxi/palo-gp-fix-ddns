# Dynamic DNS Updates for GlobalProtect clients

**The registry settings that enable you to deploy scripts are supported on endpoints running GlobalProtect App 2.3 and later releases.**

A common issue when running any VPN Client is that Windows endpoints may update the company DNS with the wrong IP address. It is desirable to only register the physical adapter's address when on-premises, and only the GlobalProtect adapter's address when off-premises. This requires a script that enables and disables the "Register this connection's addresses in DNS" option in the adapters dynamically.

This Powershell script does the following:

- Identify all IP-enabled adapters
- Identify those that have a company DNS domain received via DHCP, to determine whether the endpoint is on-prem or off-prem
- If there are any, enable "Register this connection's addresses in DNS" only for them, and disable it for the PANGP adapter
- If there are none, enable it only for the PANGP adapter
- Force an ipconfig /registerdns

Thanks to [Deploy Scripts Using the Windows Registry](https://docs.paloaltonetworks.com/globalprotect/9-1/globalprotect-admin/globalprotect-apps/deploy-app-settings-transparently/deploy-app-settings-to-windows-endpoints/deploy-scripts-using-the-windows-registry) feature of Palo Alto GlobalProtect, the script can be run after each GlobalProtect login. Convert the script into a single-line batch like the following:

```powershell -Command "$OnPremDomains = @('example.com', 'example.org', 'example.local') ; $ActiveAdapters = Get-WmiObject Win32_NetworkAdapterConfiguration -filter 'ipenabled = true' ; ForEach($Adapter in $ActiveAdapters) {$Adapter.SetDynamicDNSRegistration($False)} ; $GPAdapter = $ActiveAdapters | Where-Object {$_.Description -eq 'PANGPVirtual Ethernet Adapter Secure'} ; $NICsOnPrem = $ActiveAdapters | Where-Object {$_.DNSDomain -in $OnPremDomains} | Where-Object {$_.Description -ne 'PANGPVirtual Ethernet Adapter Secure'} ; If ($NICsOnPrem) {ForEach($Adapter in $NICsOnPrem) {$Adapter.SetDynamicDNSRegistration($True)}} ElseIf ($GPAdapter) {$GPAdapter.SetDynamicDNSRegistration($True)} ; Register-DnsClient ;"```

**Remember to customize the domains in the script with your internal ones.** This string must be placed in every client's registry as string data in a value named **command** under the key **HKEY_LOCAL_MACHINE\SOFTWARE\Palo Alto Networks\GlobalProtect\Settings\post-vpn-connect**. Additionally, due to what it does, it must be run with administrator permissions thanks to the [Script Deployment Options](https://docs.paloaltonetworks.com/globalprotect/9-1/globalprotect-admin/globalprotect-apps/deploy-app-settings-transparently/customizable-app-settings/script-deployment-options): create a string value called **context** in the same registry key and enter **admin** as its data.

It is important that the "Register this connection's addresses in DNS" setting for the adapters is not overridden by any other script or GPO when using this script.

### License

This project is licensed under the [MIT License](https://github.com/o5edaxi/palo-gp-fix-ddns/blob/main/LICENSE).
