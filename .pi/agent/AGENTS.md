# Global Agent Rules

## Command Execution: Context-Mode First

Default to context-mode `ctx_execute` / `ctx_execute_file` for ALL commands. Only use Bash for guaranteed-small-output operations.

Bash whitelist (safe to run directly):
- **File mutations**: `mkdir`, `mv`, `cp`, `rm`, `touch`, `chmod`, `ln`
- **Git writes**: `git add`, `git commit`, `git push`, `git checkout`, `git branch`, `git merge`
- **Navigation**: `cd`, `pwd`, `which`, `command -v`
- **Process control**: `kill`, `pkill`
- **Package management**: `npm install`, `pip install`, `uv tool install`, `pi install`
- **Simple output**: `echo`, `printf`

**Everything else → `ctx_execute` or `ctx_execute_file`.** This includes ALL queries (ls, find, grep, cat), all CLIs (gh, aws, docker, kubectl, terraform), all test runners, git log/diff, builds, and any command whose output size is uncertain. When in doubt, use context-mode.

## Sensitive File Reading

Before reading any of the following sensitive files, you MUST ask the user for explicit permission:

- `.env` files (environment variables)
- `.bashrc`, `.zshrc`, `.profile`, `.bash_profile` (shell configuration)
- `.git-credentials`, `.gitconfig` (git credentials/config)
- `*.pem`, `*.key`, `id_rsa*`, `id_ed25519*` (private keys)
- `credentials.*`, `secrets.*`, `tokens.*` (credential files)
- `config.json` or `.config` files that may contain API keys or tokens
- Any file containing `API_KEY`, `SECRET`, `TOKEN`, or `PASSWORD` in its name

When in doubt about whether a file might be sensitive, err on the side of caution and ask.
