function Publish-File {
    [CmdletBinding()]
    [OutputType('PSCustomObject')]
    param (
        [Parameter(ValueFromPipeline)]
        $InputObject,
        $Session,
        $EnableException
    )
    process {
        foreach ($file in $InputObject) {
            $fileinfo = Get-ItemProperty -Path $file
            $fullname = $fileinfo.FullName
            $restclient = New-Object RestSharp.RestClient
            $restrequest = New-Object RestSharp.RestRequest
            $restclient.UserAgent = 'tentools'
            $restclient.BaseUrl = $session.uri
            $restrequest.Method = [RestSharp.Method]::POST
            $restrequest.Resource = 'file/upload'
            $restclient.CookieContainer = $Session.WebSession.Cookies
            [void]$restrequest.AddFile('Filedata', $fullname, 'application/octet-stream')

            foreach ($header in $Session.Headers) {
                [void]$restrequest.AddHeader($header.Keys, $header.Values)
            }
            $result = $restclient.Execute($restrequest)

            if ($result.ErrorMessage) {
                Stop-PSFFunction -Message $result.ErrorMessage -Continue -EnableException:$EnableException
            }
            if ($session.sc) {
                $filename = ($result.Content | ConvertFrom-Json | Select-Object Response | ConvertFrom-TNRestResponse).Filename
                ConvertTo-Json @{'filename' = $filename } -Compress
            } else {
                $fileinfo = Get-ItemProperty -Path $file
                ConvertTo-Json @{'file' = $fileinfo.name } -Compress
            }
        }
    }
}