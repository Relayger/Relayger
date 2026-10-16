#!/bin/sh
# Relayger CLI installer for Linux and macOS.
#
#   curl -fsSL https://raw.githubusercontent.com/Relayger/Relayger/main/install.sh | sh
#
# Installs the `relayger` command, which includes the local MCP server (`relayger mcp`).
# Needs Node.js 22.23.2+, 24.18.1+ or 26.5.1+ with npm. The package comes from this
# repository's GitHub release and is checked against a SHA-256 checksum before npm sees it;
# nothing is fetched from the npm registry. No sudo: when npm's global prefix is not
# writable, the CLI goes to ~/.local.
#
# Environment:
#   RELAYGER_VERSION  release to install (default: the version below)
#   RELAYGER_PREFIX   install prefix for npm (default: npm's global prefix, else ~/.local)

set -eu

DEFAULT_VERSION="0.10.0"
DEFAULT_SHA256="dda9ee6b4e19d3bd602b7ee007f6d0b6eb695989ad6672cff493f4b3465ddf27"
REPOSITORY="https://github.com/Relayger/Relayger"

fail() {
  printf 'relayger install: %s\n' "$1" >&2
  exit 1
}

download() {
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL --proto '=https' --tlsv1.2 --retry 3 -o "$2" "$1" || fail "could not download $1"
  elif command -v wget >/dev/null 2>&1; then
    wget -q -O "$2" "$1" || fail "could not download $1"
  else
    fail "curl or wget is required"
  fi
}

sha256() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | cut -d ' ' -f 1
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | cut -d ' ' -f 1
  elif command -v openssl >/dev/null 2>&1; then
    openssl dgst -sha256 -r "$1" | cut -d ' ' -f 1
  else
    fail "sha256sum, shasum or openssl is required to verify the download"
  fi
}

writable_prefix() {
  [ -d "$1" ] && [ -w "$1" ] || return 1
  for dir in "$1/lib" "$1/lib/node_modules" "$1/bin"; do
    if [ -e "$dir" ] && [ ! -w "$dir" ]; then
      return 1
    fi
  done
  return 0
}

main() {
  supported="Node.js 22.23.2+, 24.18.1+ or 26.5.1+"
  command -v node >/dev/null 2>&1 || fail "$supported is required: https://nodejs.org"
  command -v npm >/dev/null 2>&1 || fail "npm is required (it ships with Node.js)"
  node_version=$(node -p 'process.versions.node')
  # The July 2026 security releases or later; the odd lines 23 and 25 are end-of-life.
  node -e '
    const [a, b, c] = process.versions.node.split(".").map(Number);
    const from = (minor, patch) => b > minor || (b === minor && c >= patch);
    process.exit((a === 22 && from(23, 2)) || (a === 24 && from(18, 1)) || (a === 26 && from(5, 1)) || a > 26 ? 0 : 1);
  ' || fail "$supported is required (found $node_version)"
  case "$node_version" in
    22.* | 24.* | 26.*) ;;
    *) printf 'relayger install: note: tested with Node.js 22, 24 and 26 (found %s)\n' "$node_version" >&2 ;;
  esac

  version="${RELAYGER_VERSION:-$DEFAULT_VERSION}"
  version="${version#v}"
  case "$version" in
    *[!0-9.]* | '' | .* | *. | *..*) fail "invalid release version" ;;
  esac
  [ "$(printf '%s' "$version" | awk -F. '{print NF}')" = 3 ] || fail "invalid release version"
  file="relayger-cli-$version.tgz"
  base="$REPOSITORY/releases/download/v$version"

  work=$(mktemp -d 2>/dev/null || mktemp -d -t relayger)
  trap 'rm -rf "$work"' EXIT
  trap 'exit 130' INT TERM

  printf 'Downloading %s\n' "$base/$file"
  download "$base/$file" "$work/$file"
  if [ "$version" = "$DEFAULT_VERSION" ]; then
    expected="$DEFAULT_SHA256"
  else
    download "$base/SHA256SUMS" "$work/SHA256SUMS"
    expected=$(awk -v f="$file" '$2 == f { print $1 }' "$work/SHA256SUMS")
  fi
  actual=$(sha256 "$work/$file")
  [ -n "$expected" ] && [ "$expected" = "$actual" ] || fail "checksum mismatch for $file; nothing was installed"

  # `npm config get prefix` refuses values that look like secrets; `npm prefix -g` does not.
  global=$(npm prefix -g 2>/dev/null || true)
  prefix="${RELAYGER_PREFIX:-}"
  if [ -z "$prefix" ]; then
    if [ -n "$global" ] && writable_prefix "$global"; then
      prefix="$global"
    else
      prefix="$HOME/.local"
    fi
  fi
  mkdir -p "$prefix"
  npm install --global --prefix "$prefix" --no-audit --no-fund --loglevel=error "$work/$file"

  bin="$prefix/bin"
  installed=$("$bin/relayger" --version) || fail "the installed command could not run"
  [ "$installed" = "$version" ] || fail "the installed command reports an unexpected version"
  printf '\nInstalled Relayger %s: %s/relayger\n' "$installed" "$bin"
  case ":$PATH:" in
    *":$bin:"*) ;;
    *) printf 'Add it to your PATH, for example:  export PATH="%s:$PATH"\n' "$bin" ;;
  esac
  printf '%s\n' \
    '' \
    'Next:' \
    '  relayger register https://relayger.com      # an agent number, password and recovery key' \
    '  relayger --help' \
    '  relayger --server https://relayger.com mcp --print-config   # for MCP host configuration' \
    'Guide: https://relayger.com/agents.md'
}

main "$@"
