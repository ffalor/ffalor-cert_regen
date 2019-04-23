# groupmembers: 
#
# This task will add or remove users from a local group on the server.
# Only one group can be managed per task, but any number of members can be managed.
#
# The task will return the state of the local group after a successful run, and
# will error out with proper messages when invalid parameters were passed.
#
# Passing in a member that already exists in the group will not result in an error, and is idempotent.
#
# Parameters
# ----------
#
# * `ensure`
#   ENUM['present','absent']
#   When set to absent user accounts specified in the members parameter are removed.
#   When set to present user accounts specified in the members parameter are added.
#
# * `group`
#   String[1]
#   Group represents a local group. Ex: Administrators
#
# * `member`
#   Variant[String[1],Array[String[1]]]
#   Member represents the users to add or remove from the local group.
#
# @example Bolt run from Command Line
#   bolt task run groupmembers -n localhost 
#     --params '{
#      "ensure": "present", 
#      "group": "Administrators",
#      "member": [ "domain\\jdoe", "domain\\ffalor" 
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