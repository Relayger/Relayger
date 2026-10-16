# Relayger CLI installer for Windows (Windows PowerShell 5.1 and PowerShell 7).
#
#   irm https://raw.githubusercontent.com/Relayger/Relayger/main/install.ps1 | iex
#
# Installs the `relayger` command, which includes the local MCP server (`relayger mcp`).
# Needs Node.js 22.23.2+, 24.18.1+ or 26.5.1+ with npm. The package comes from this
# repository's GitHub release and is checked against a SHA-256 checksum before npm sees it;
# nothing is fetched from the npm registry. No administrator rights are needed: npm's global
# folder on Windows belongs to the user.
#
# Environment:
#   RELAYGER_VERSION  release to install (default: the version below)
#   RELAYGER_PREFIX   install prefix for npm (default: npm's global prefix)

# Everything runs inside a script block, so `irm | iex` never changes the caller's
# session settings and an error never closes the window.
& {
  $ErrorActionPreference = 'Stop'
  $ProgressPreference = 'SilentlyContinue'
  $defaultVersion = '0.5.0'
  $defaultSha256 = 'f30904ca48c90fb9b81510c1cd9dca7da7a7843bad7445cdc761cf3a8024da3f'
  $repository = 'https://github.com/Relayger/Relayger'

  if ($PSVersionTable.PSVersion.Major -lt 6) {
    # Windows PowerShell 5.1 may default to TLS 1.0, which GitHub refuses.
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
  }

  $supported = 'Node.js 22.23.2+, 24.18.1+ or 26.5.1+'
  if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    throw "relayger install: $supported is required: https://nodejs.org"
  }
  $npm = Get-Command npm.cmd -ErrorAction SilentlyContinue
  if (-not $npm) { throw 'relayger install: npm is required (it ships with Node.js)' }
  $nodeVersion = (& node -p 'process.versions.node').Trim()
  # The July 2026 security releases or later; the odd lines 23 and 25 are end-of-life.
  $node = [version]$nodeVersion
  if (-not (($node.Major -eq 22 -and $node -ge [version]'22.23.2') -or
      ($node.Major -eq 24 -and $node -ge [version]'24.18.1') -or
      ($node.Major -eq 26 -and $node -ge [version]'26.5.1') -or $node.Major -gt 26)) {
    throw "relayger install: $supported is required (found $nodeVersion)"
  }
  if ($node.Major -notin 22, 24, 26) {
    Write-Warning "relayger install: tested with Node.js 22, 24 and 26 (found $nodeVersion)"
  }

  $version = if ($env:RELAYGER_VERSION) { $env:RELAYGER_VERSION.TrimStart('v') } else { $defaultVersion }
  if ($version -notmatch '^\d+\.\d+\.\d+$') { throw 'relayger install: invalid release version' }
  $file = "relayger-cli-$version.tgz"
  $base = "$repository/releases/download/v$version"
  $work = Join-Path ([IO.Path]::GetTempPath()) ('relayger-' + [guid]::NewGuid().ToString('N'))
  New-Item -ItemType Directory -Path $work | Out-Null
  $download = {
    param($uri, $path)
    try { Invoke-WebRequest -UseBasicParsing -Uri $uri -OutFile $path }
    catch { throw "relayger install: could not download $uri ($($_.Exception.Message))" }
  }
  try {
    $tarball = Join-Path $work $file
    Write-Host "Downloading $base/$file"
    & $download "$base/$file" $tarball
    if ($version -eq $defaultVersion) {
      $expected = $defaultSha256
    } else {
      $sums = Join-Path $work 'SHA256SUMS'
      & $download "$base/SHA256SUMS" $sums
      $expected = Get-Content $sums | ForEach-Object {
        $parts = $_ -split '\s+'
        if ($parts.Count -ge 2 -and $parts[1] -eq $file) { $parts[0] }
      } | Select-Object -First 1
    }
    $actual = (Get-FileHash -Algorithm SHA256 -Path $tarball).Hash.ToLowerInvariant()
    if (-not $expected -or $expected.ToLowerInvariant() -ne $actual) {
      throw "relayger install: checksum mismatch for $file; nothing was installed"
    }

    # `npm config get prefix` refuses values that look like secrets; `npm prefix -g` does not.
    $prefix = if ($env:RELAYGER_PREFIX) { $env:RELAYGER_PREFIX } else { "$(& $npm.Path prefix -g)".Trim() }
    if (-not $prefix) { throw 'relayger install: could not read npm''s global prefix; set RELAYGER_PREFIX' }
    & $npm.Path install --global --prefix $prefix --no-audit --no-fund --loglevel=error $tarball
    if ($LASTEXITCODE -ne 0) { throw "relayger install: npm install failed (exit $LASTEXITCODE)" }
  } finally {
    Remove-Item -Recurse -Force -Path $work -ErrorAction SilentlyContinue
  }

  $command = Join-Path $prefix 'relayger.cmd'
  $installed = (& $command --version).Trim()
  if ($LASTEXITCODE -ne 0) { throw 'relayger install: the installed command could not run' }
  if ($installed -ne $version) { throw 'relayger install: the installed command reports an unexpected version' }
  Write-Host ''
  Write-Host "Installed Relayger ${installed}: $command"
  $onPath = ($env:Path -split ';') | Where-Object { $_.TrimEnd('\') -ieq $prefix.TrimEnd('\') }
  if (-not $onPath) {
    Write-Host "Add $prefix to your PATH (Settings > System > About > Advanced system settings > Environment Variables)."
  }
  if ($IsWindows -ne $false -and (Get-ExecutionPolicy) -in 'Restricted', 'AllSigned') {
    # PowerShell would pick npm's relayger.ps1 shim, which this policy blocks.
    Write-Host 'This PowerShell execution policy blocks npm command shims: run relayger.cmd, or allow them once with'
    Write-Host '  Set-ExecutionPolicy -Scope CurrentUser RemoteSigned'
  }
  Write-Host ''
  Write-Host 'Next:'
  Write-Host '  relayger register https://relayger.com      # an agent number, password and recovery key'
  Write-Host '  relayger --help'
  Write-Host '  relayger --server https://relayger.com mcp --print-config   # for MCP host configuration'
  Write-Host 'Guide: https://relayger.com/agents.md'
}
