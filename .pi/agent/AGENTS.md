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

## Planning and To-Do

In each every project you are working always implement a plan and To-Do markdown files in order track project implementation phases.
### Plan.md

create a planning file called `Plan.md`
Here is an example of the file structure:

```markdown
    ## Goal
    Refactor authentication system to support OAuth

    ## Approach
    1. Research OAuth 2.0 flows
    2. Design token storage schema
    3. Implement authorization server endpoints
    4. Update client-side login flow
    5. Add tests

    ## Current Step
    Working on step 3 - authorization endpoints
```

Refer to this file to know what step we are currently on

### To-Do.md

create a file called `To-Do.md` descibing in
Example:

```markdown
## Phase 5: Secure Cookies 
### Why
- Currently: refresh token in JSON body → frontend JS can read it → XSS steals it → attacker gets new access tokens forever
- Fix: refresh token in HttpOnly cookie → JS can't read it → XSS can't steal it

### Plan
1. Create `CookieUtil` helper — builds HttpOnly/Secure/SameSite=Strict cookies
2. `LoginResponse` — remove `refreshToken` field (now in cookie)
3. `LoginRequest` / `LogoutRequest` / `RefreshTokenRequest` — remove refreshToken from body (read from cookie)
4. `AuthController.login()` — set refresh token cookie in response
5. `AuthController.refresh()` — read token from cookie, rotate cookie
6. `AuthController.logout()` — read token from cookie, clear cookie
7. `OAuthAuthenticationSuccessHandler` — set cookie instead of URL param for refresh token
8. Update integration tests — set cookie instead of JSON body
9. Update Swagger docs for new request/response shapes

### Tasks
- [x] Create `CookieUtil` class
- [x] Update `LoginResponse` (remove refreshToken)
- [x] Update `RefreshTokenRequest` (remove field)
- [x] Update `LogoutRequest` (remove field)
- [x] Update `AuthController` (login, refresh, logout)
- [x] Update `OAuthAuthenticationSuccessHandler`
- [x] Update integration tests
- [x] Run full test suite

## Syntax updates
Always browse official website to look for official syntax and current libraries versions.
