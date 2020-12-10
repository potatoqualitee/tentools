function Get-TNAuditFile {
    <#
    .SYNOPSIS
        Gets a list of audit files

    .DESCRIPTION
        Gets a list of audit files

    .PARAMETER SessionObject
        Optional parameter to force using specific SessionObjects. By default, each command will connect to all connected servers that have been connected to using Connect-TNServer

    .PARAMETER Name
        The name of the target audit file

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with 'sea of red' exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this 'nice by default' feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        PS C:\> Get-TNAuditFile

        Gets a list of audit files

    .EXAMPLE
        PS C:\> Get-TNAuditFile -Name "SQL Server"

        Gets a list of audit files named SQL Server
#>
    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipelineByPropertyName)]
        [object[]]$SessionObject = (Get-TNSession),
        [Parameter(ValueFromPipelineByPropertyName)]
        [string[]]$Name,
        [switch]$EnableException
    )
    process {
        foreach ($session in $SessionObject) {
            if (-not $session.sc) {
                Stop-PSFFunction -EnableException:$EnableException -Message "Only tenable.sc supported" -Continue
            }

            $params = @{
                Path            = "/auditFile?fields=name,filename,originalFilename,dataStreamName,benchmarkName,profileName,tailoringOriginalFilename,typeFields,version,description,modifiedTime,createdTime,auditFileTemplate,type,editor,name,description,type,ownerGroup,groups,owner,version,canManage,canUse,originalFilename,modifiedTime,auditFileTemplate,typeFields,editor"
                Method          = "GET"
                EnableException = $EnableException
            }

            if ($PSBoundParameters.Name) {
                Invoke-TNRequest @params | ConvertFrom-TNRestResponse | Where-Object Name -in $Name
            } else {
                Invoke-TNRequest @params | ConvertFrom-TNRestResponse
            }
        }
    }
}