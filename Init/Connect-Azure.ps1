<#
.PARAMETER Alias
    azl
.PARAMETER Description
    Authenticates to Azure for the Planet Pearce tenant and sets the active subscription using Connect-AzAccount.
#>
function Connect-Azure {
    [CmdletBinding()]
    param()
    Connect-AzAccount -TenantId 19269dc1-8b0e-4c8c-9647-1aebbab40de3 -Subscription 955b0d26-ef56-491a-9672-80eeb763d932
}
