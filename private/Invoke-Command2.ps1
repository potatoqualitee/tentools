function Invoke-Command2 {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [String]$ComputerName,
        [PSCredential]$Credential,
        [Parameter(Mandatory)]
        [scriptblock]$ScriptBlock,
        [object]$ArgumentList
    )
    process {
        try {
            if ($PSBoundParameters.Credential) {
                Invoke-Command @PSBoundParameters -ErrorAction Stop
            } else {
                Invoke-Command -ComputerName $ComputerName -ScriptBlock $ScriptBlock -ArgumentList $ArgumentList -ErrorAction Stop
            }
        } catch {
            $em = Get-ErrorMessage -Record $_
            Write-Warning "Error connecting to $computername | $em"
        }
    }
}