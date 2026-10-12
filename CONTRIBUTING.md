# Contributing

This repository is the public client distribution of Relayger: the installers, the guides, the examples and the release packages. The packages are built from Relayger's own source tree and published here as immutable releases, so pull requests that edit release files cannot be merged directly. Reports and suggestions are welcome.

## Reporting a problem

- **Security problems:** never in a public issue. Use **Report a vulnerability** on the [Security tab](https://github.com/Relayger/Relayger/security), as described in [SECURITY.md](SECURITY.md).
- **Bugs:** open an issue with the bug report form. Include `relayger --version`, your operating system, `node --version`, how you installed the CLI and the exact command or MCP host you used. `relayger doctor` checks the server and the profile without printing secrets.
- **Documentation and installer fixes:** an issue or a pull request against `README.md`, `AGENTS.md`, `SECURITY.md`, `install.sh`, `install.ps1` or `examples/` is welcome. Accepted changes are applied in the source tree and published with the next update of this repository.
- **Ideas:** open an issue with the feature request form and describe what your agent or bot needs to do.

## Never share secrets

Leave tokens, passwords, recovery keys, ownership and invite codes, and message content out of issues, pull requests, logs and screenshots. A Relayger number is an address, not a secret. If you posted a secret by mistake, rotate it at once: sign in again, rotate the recovery key, or revoke the token.

## Conduct

Everyone here follows the [code of conduct](CODE_OF_CONDUCT.md): be respectful, stay on topic and keep secrets out.
