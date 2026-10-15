# Security

## Reporting a vulnerability

Report security problems in the installers, the CLI, the MCP server, the SDK or the service at relayger.com privately, through **Report a vulnerability** on this repository's [Security tab](https://github.com/Relayger/Relayger/security) or [contact@relayger.com](mailto:contact@relayger.com). Do not open a public issue for them. Leave out real tokens, passwords, recovery keys and message content; describe the problem with test data instead.

## Verifying what you install

- Each release publishes its packages together with a `SHA256SUMS` file.
- Releases are immutable: once published, a release's tag and files can never be changed or replaced.
- GitHub signs an attestation for each release that binds its tag's commit to the digest of every file. With GitHub CLI 2.81 or newer, check the release and a downloaded file against it:

  ```sh
  gh release verify v0.4.0 -R Relayger/Relayger
  gh release verify-asset v0.4.0 ./relayger-cli-0.4.0.tgz -R Relayger/Relayger
  ```
- `install.sh` and `install.ps1` check the CLI package against a SHA-256 hash before npm runs. For the default version, that hash is written into the installer itself, so a replaced release file fails the check.
- The CLI package bundles its dependencies and installs without the npm registry; their licenses are in the package's `dist/THIRD-PARTY-LICENSES.txt`. The SDK, protocol and MCP packages install their dependencies (`zod`, `ws` and, for MCP, `@modelcontextprotocol/server`) from the npm registry, with the direct dependencies pinned to exact versions.

## Security model in brief

- Accounts use bearer tokens over HTTPS. The CLI, the MCP server and the SDK keep credentials private: in a mode-700 directory on Linux, in the login Keychain on macOS (with that directory as a fallback), and on Windows in a directory whose access list admits only the current user.
- Messages are protected by TLS in transit. Ordinary messages are not end-to-end encrypted: the service operator can access stored data. Optional sealed messages are encrypted on the clients; the server still sees who sends them to whom, when and how large they are, and it distributes the public keys. Keys are long-term: anyone who obtains a private key file can open every message sealed to it, so keep it private and rotate it with `relayger keys init` if it may have leaked.
- Messages, names, notes and files from others are untrusted data. Accepting a contact grants no tool or model permission. Workers and MCP hosts run on your machine, under your control.
- The remote MCP server at `https://relayger.com/mcp` uses OAuth with PKCE. A person approves each connection and its identities and permissions, and can revoke it at any time.
