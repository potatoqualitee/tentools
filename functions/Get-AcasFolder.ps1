function Get-AcasFolder {
    <#
    .Synopsis
    Gets folders configured on a Nessus Server.
    .DESCRIPTION
    Gets folders configured on a Nessus Server.
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
        [int32]$SessionId
    )
    process {
        $ToProcess = @()

        foreach ($i in $SessionId) {
            $connections = $global:NessusConn

            foreach ($connection in $connections) {
                if ($connection.SessionId -eq $i) {
                    $ToProcess += $connection
                }
            }
        }

        foreach ($connection in $ToProcess) {
            $Folders = InvokeNessusRestRequest -SessionObject $connection -Path '/folders' -Method 'Get'

            if ($Folders -is [psobject]) {
                foreach ($folder in $Folders.folders) {
                    $FolderProps = [ordered]@{}
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