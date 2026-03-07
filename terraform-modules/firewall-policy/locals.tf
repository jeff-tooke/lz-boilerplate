locals {
  # ---------------------------------------------------------------
  # HOME_NET — sources permitted to egress internet via this firewall.
  # Azure is deliberately excluded: Azure traffic never egresses via AWS.
  # On-prem is only included when Pattern B egress is explicitly enabled.
  # ---------------------------------------------------------------
  home_net_cidrs    = [var.internal_cidr]
  dr_home_net_cidrs = [var.dr_internal_cidr]

  # ---------------------------------------------------------------
  # Validation guards — surface misconfiguration at plan time rather
  # than producing silently incomplete rule groups at apply time.
  # ---------------------------------------------------------------
  validate_onprem_cidr = (
    var.enable_onprem_inspection && var.onprem_cidr == null
    ? tobool("onprem_cidr must be set when enable_onprem_inspection = true")
    : true
  )

  validate_onprem_ad = (
    var.enable_onprem_ad_rules && !var.enable_onprem_inspection
    ? tobool("enable_onprem_inspection must be true when enable_onprem_ad_rules = true")
    : true
  )

  validate_azure_cidr = (
    var.enable_azure_inspection && var.azure_cidr == null
    ? tobool("azure_cidr must be set when enable_azure_inspection = true")
    : true
  )

  validate_azure_ad = (
    var.enable_azure_ad_rules && !var.enable_azure_inspection
    ? tobool("enable_azure_inspection must be true when enable_azure_ad_rules = true")
    : true
  )

  # ---------------------------------------------------------------
  # AD rule definitions — shared across east-west, on-prem and Azure
  # rule groups. CIDRs and Suricata direction operators are injected
  # at each call site. SID ranges are namespaced per rule group:
  #
  #   East-west TCP  AD : 10010xx
  #   East-west UDP  AD : 10020xx
  #   On-prem   TCP  AD : 10030xx
  #   On-prem   UDP  AD : 10040xx
  #   Azure     TCP  AD : 10050xx
  #   Azure     UDP  AD : 10060xx
  # ---------------------------------------------------------------
  ad_rules_tcp = [
    { port = "88", msg = "Kerberos TCP", sid = "01" },
    { port = "135", msg = "RPC Endpoint Mapper", sid = "02" },
    { port = "139", msg = "NetBIOS Session", sid = "03" },
    { port = "389", msg = "LDAP TCP", sid = "04" },
    { port = "445", msg = "SMB", sid = "05" },
    { port = "464", msg = "Kerberos pw change TCP", sid = "06" },
    { port = "636", msg = "LDAPS", sid = "07" },
    { port = "3268", msg = "Global Catalog LDAP", sid = "08" },
    { port = "3269", msg = "Global Catalog LDAPS", sid = "09" },
    { port = "5722", msg = "DFS Replication", sid = "10" },
    { port = "9389", msg = "AD Web Services", sid = "11" },
    { port = "49152:65535", msg = "RPC dynamic ports", sid = "12" },
    { port = "3389", msg = "RDP", sid = "13" },
    { port = "5985:5986", msg = "WinRM", sid = "14" },
    { port = "1433", msg = "MSSQL", sid = "15" },
  ]

  ad_rules_udp = [
    { port = "88", msg = "Kerberos UDP", sid = "16" },
    { port = "123", msg = "NTP", sid = "17" },
    { port = "137", msg = "NetBIOS Name", sid = "18" },
    { port = "138", msg = "NetBIOS Datagram", sid = "19" },
    { port = "389", msg = "LDAP UDP", sid = "20" },
    { port = "464", msg = "Kerberos pw change UDP", sid = "21" },
    { port = "1434", msg = "MSSQL Browser", sid = "22" },
  ]
}
