function Get-AcasFolder {
    <#
    .Synopsis
        Gets folders configured on a Nessus Server.

    .DESCRIPTION
        Gets folders configured on a Nessus Server.

    .PARAMETER SessionId
        ID of a valid Nessus session. This is auto-populated after a connection is made using Connect-AcasService.

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        Get-AcasFolder 0

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
        $collection = @()

        foreach ($id in $SessionId) {
            $connections = $global:NessusConn

            foreach ($connection in $connections) {
                if ($connection.SessionId -eq $id) {
                    $collection += $connection
                }
            }
        }

        foreach ($connection in $collection) {
            $Folders = Invoke-AcasRequest -SessionObject $connection -Path '/folders' -Method 'Get'

            if ($Folders -is [psobject]) {
                foreach ($folder in $Folders.folders) {
                    $FolderProps = [ordered]@{ }
                    $FolderProps.Add('Name', $folder.name)
                    $FolderProps.Add('FolderId', $folder.id)
                    $FolderProps.Add('Type', $folder.type)
                    $FolderProps.Add('Default', $folder.default_tag)
                    $FolderProps.Add('Unread', $folder.unread_count)
                    $FolderProps.Add('SessionId', $connection.SessionId)
                    $FolderObj = New-Object -TypeName psobject -Property $FolderProps
                    $FolderObj.pstypenames[0] = 'Nessus.Folder'
                    $FolderObj
                }
            }
        }
    }
}