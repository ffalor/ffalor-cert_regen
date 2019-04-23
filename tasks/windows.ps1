# cert_regen: 
#
# This task will recreate puppet certificates on windows machines.
# If no value is given for certname it will use the fqdn of the server.
#
# If the new certname is the same as the current certname nothing is done.
#
# Parameters
# ----------
#
# * `certname`
#   Optional[String[1]]
#   New certname to use. Defaults to the fqdn.
#
# * `section`
#   Optional[Enum[main,master,agent,user]]
#   Puppet.conf section to add the certname under. Defaults to main.
#
#
# @example Bolt run from Command Line
#   bolt task run cert_regen -n localhost 
#     --params '{
#      "certname": "present", 
#      "section": "main",
#      }'
#
# Authors
# -------
#
# * Falor, Frank    <ffalorjr@outlook.com>
[CmdletBinding()]
Param(
    $certname,
    $section = "main"
)
$redirect = "2>&1"

if ([String]::IsNullOrWhiteSpace($certname)) {
    $certname = ([System.Net.Dns]::GetHostEntry([string]$env:computername).HostName).ToLower()
}

function WriteError {
    param (
        [Parameter(Mandatory = $True)]
        $message,
        [Parameter(Mandatory = $True)]
        $currentCertname,
        [Parameter(Mandatory = $True)]
        $newCertname
    )
    if (!([String]::IsNullOrWhiteSpace($message))) {
        $message = $message | ConvertTo-Json
    }
    else {
        $message = '"No error message recieved."'
    }

    $error_payload = @"
{
    "_error": {
        "msg": $message,
        "kind": "puppetlabs.tasks/task-error",
        "details": {
            "section": "${section}",
            "old_certname": "${currentCertname}",
            "new_certname":"${newCertname}",
            "exitcode": 1
        }
    },
    "_output": "Something went wrong with task",
    "section": "${section}",
    "old_certname": "${currentCertname}",
    "new_certname":"${newCertname}"
}
"@

    Write-Output $error_payload
}

function WriteSuccess {
    param (
        [Parameter(Mandatory = $True)]
        $currentCertname,
        [Parameter(Mandatory = $True)]
        $newCertname
    )
    try {

        $success_payload = @"
{
        "section": "${section}",
        "old_certname": "${currentCertname}",
        "new_certname":"${newCertname}"
}
"@
        Write-Output $success_payload

    }
    catch {
        $error_message = $_.Exception.Message
        WriteError -message $error_message -currentCertname $currentCertname -newCertname $certname
        exit 1
    }
}


function GetInstallPath {
    $rootPath = 'HKLM:\SOFTWARE\Puppet Labs\Puppet'

    $reg = Get-ItemProperty -Path $rootPath -ErrorAction SilentlyContinue
    if ($null -ne $reg) {
        if ($null -ne $reg.RememberedInstallDir64) {
            $path = $reg.RememberedInstallDir64 + 'bin\puppet.bat'
        }
        elseif ($null -ne $reg.RememberedInstallDir) {
            $path = $reg.RememberedInstallDir + 'bin\puppet.bat'
        }
    }

    if ( !(($null -ne $path) -and (Test-Path -Path $path) )) {
        WriteError -message "Can't deterime puppet install Path" -currentCertname $currentCertname -newCertname $certname
    }

    return $path
}

function GetSSLDir {
    param (
        [Parameter(Mandatory = $True)]
        $path
    )
    $cmd = "`"${path}`" config print ssldir"
    $sslDir = cmd.exe /c $cmd $redirect
    if ($LASTEXITCODE -ne 0) {
        WriteError -message $sslDir -currentCertname $currentCertname -newCertname $certname
        exit 1
    }
    return $sslDir
    
}
function CurrentCertname {
    param (
        [Parameter(Mandatory = $True)]
        $path
    )
    $cmd = "`"${path}`" config print certname"
    $currentCertname = cmd.exe /c $cmd $redirect
    if ($LASTEXITCODE -ne 0) {
        WriteError -message $currentCertname -currentCertname $currentCertname -newCertname $certname
        exit 1
    }
    return $currentCertname
}

$path = GetInstallPath
$currentCertname = CurrentCertname -path $path
$sslDir = GetSSLDir -path $path

try {
    if ($currentCertname -ne $certname) {
        if (Test-Path -Path $sslDir) {
            Remove-Item -Path $sslDir -Recurse -Force
        }
        $cmd = "`"${path}`" config set certname `"${certname}`" --section ${section}"
        $cert_output = cmd.exe /c $cmd $redirect
        if ($LASTEXITCODE -ne 0) {
            WriteError -message $cert_output -currentCertname $currentCertname -newCertname $certname
            exit 1
        }
    }
    WriteSuccess -newCertname $certname -currentCertname $currentCertname

}
catch {
    $error_message = $_.Exception.Message
    WriteError -message $error_message -currentCertname $currentCertname -newCertname $certname
}