Set-PSDebug -Strict;

Set-Location -Path $PSScriptRoot;
<#
 # Python VirtualEnv
 #>
$_venv_dir = Join-Path -Path "." -ChildPath ".venv-w";
$_pip_list_cache = Join-Path -Path ${_venv_dir} -ChildPath "requirements.txt";
$_requirements = Join-Path -Path "." -ChildPath "requirements.txt";

$activator = @(${_venv_dir}, "Scripts", "activate") -join [IO.Path]::DirectorySeparatorChar;
$cmd = "`"" + ${activator} + "`"" +
    " && pip install -r `"" + ${_requirements} + "`"" +
    " && pip freeze > `" + ${_pip_list_cache} + `"";
if (!(Test-Path -Path ${_venv_dir})) {
    Invoke-Expression -Command ("python -m venv `"" + ${_venv_dir} + "`"");
    Start-Process -File "cmd.exe" -ArgumentList @("/c", $cmd) -Wait;
    Copy-Item -Path ${_pip_list_cache} -Destination ${_requirements} -Force;
} elseif (!(Test-Path -Path ${_pip_list_cache})) {
    Start-Process -File "cmd.exe" -ArgumentList @("/c", $cmd) -Wait;
    Copy-Item -Path ${_pip_list_cache} -Destination ${_requirements} -Force;
} else {
    $diff = Compare-Object -ReferenceObject (Get-Content -Path ${_requirements}) -DifferenceObject (Get-Content -Path ${_pip_list_cache});
    if ($diff -ne $Null) {
        Start-Process -File "cmd.exe" -ArgumentList @("/c", $cmd) -Wait;
        Copy-Item -Path ${_pip_list_cache} -Destination ${_requirements} -Force;
    }
}
