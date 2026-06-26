<#
.PARAMETER Alias
    glt
.PARAMETER Description
    Outputs the last 20 git commits as a tab-aligned table showing hash, author, date, and commit subject.
#>
function Get-GitLogTable {
    git log --pretty=format:"%h%x09│ %an%x09│ %ad%x09│ %s" --date=short -n 20
}
Set-Alias glt Get-GitLogTable
