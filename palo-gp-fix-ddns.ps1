# Requires admin permissions for SetDynamicDNSRegistration and Register-DnsClient
# On-prem domains distributed via DHCP !!! Change me !!!
$OnPremDomains = @('example.com', 'example.org', 'example.local')
# Get all IP-enabled adapters
$ActiveAdapters = Get-WmiObject Win32_NetworkAdapterConfiguration -filter 'ipenabled = true'
# Disable DDNS for all the adapters
ForEach($Adapter in $ActiveAdapters) {$Adapter.SetDynamicDNSRegistration($False)}
# Find PAN GP adapter
$GPAdapter = $ActiveAdapters | Where-Object {$_.Description -eq 'PANGPVirtual Ethernet Adapter Secure'}
# Find adapters with the on-prem domain name
$NICsOnPrem = $ActiveAdapters | Where-Object {$_.DNSDomain -in $OnPremDomains} | Where-Object {$_.Description -ne 'PANGPVirtual Ethernet Adapter Secure'}
# Enable DDNS on physical adapters or the PAN GP depending on if pc is on-prem or not
If ($NICsOnPrem) {ForEach($Adapter in $NICsOnPrem) {$Adapter.SetDynamicDNSRegistration($True)}} ElseIf ($GPAdapter) {$GPAdapter.SetDynamicDNSRegistration($True)}
# Run ipconfig /registerdns
Register-DnsClient
