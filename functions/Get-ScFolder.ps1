function Get-ScFolder {
    <#
    .Synopsis
        Gets folders configured on a Nessus Server.

    .DESCRIPTION
        Gets folders configured on a Nessus Server.

    .PARAMETER SessionId
        ID of a valid Nessus session. This is auto-populated after a connection is made using Connect-ScService.

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        Get-ScFolder 0

        Name    : My Scans
        Id      : 2
        Type    : main
        Default : 1
        Unread  : 5

        Name    : Trash
        Id      : 3
        Type    : trash
        Default : 0
        Unread  :

        Name    : Test Folder 2
        Id      : 10
        Type    : custom
        Default : 0
        Unread  : 0
    #>
    [CmdletBinding()]
    param
    (
        [Parameter(Position = 0, ValueFromPipelineByPropertyName)]
        [Alias('Index')]
        [int32[]]$SessionId = $global:NessusConn.SessionId,
        [switch]$EnableException
    )
    process {
        foreach ($session in (Get-ScSession -SessionId $SessionId)) {
            $folders = Invoke-ScRequest -SessionObject $session -Path '/folders' -Method 'Get'
            foreach ($folder in $folders.folders) {
                [pscustomobject]@{
                    Name      = $folder.name
                    FolderId  = $folder.id
                    Type      = $folder.type
                    Default   = $folder.default_tag
                    Unread    = $folder.unread_count
                    SessionId = $session.SessionId
                } | Select-DefaultView -ExcludeProperty SessionId
            }
        }
    }
}