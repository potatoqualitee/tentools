
function Invoke-SecureShellCommand ($Stream, $Message, $Command, $StepCounter) {
    Write-ProgressHelper -StepNumber $StepCounter -Message $message
    if ($Stream) {
        Write-PSFMessage -Level Verbose -Message "SUDO MODE: $message : $command"
        Invoke-SSHStreamShellCommand -ShellStream $Stream -Command $Command
        if ($Stream.DataAvailable) {
            $null = $stream.Read()
        }
    } else {
        Write-PSFMessage -Level Verbose -Message "REGULAR MODE: $message : $command"
        $results = Invoke-SSHCommand -Command $command
        if ($results.ExitStatus -notin 0,1) {
            Write-PSFMessage -Level Warning -Message "Command '$command' failed with exit status $($results.ExitStatus)"
        }
        $results
    }
}