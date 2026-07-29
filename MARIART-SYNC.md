# Mariart plugin auto-sync

Keep the canonical **main Mariart** working copy (mariart.local) up to date automatically:
when the Mariart plugin is pushed from a site that *uses* it, the main copy fast-forwards
to the same commit.

```
  site clone (e.g. zoom-car-wash)          main copy (mariart.local)
  git push  --------------------------->   fast-forwarded to the pushed commit
```

Every Local site that has its own clone of `github.com/mariartau/mariart` is a "site clone".
There can be several; the one at `Local Sites\mariart\...\plugins\mariart` is the canonical
**main** copy this keeps current.

## The catch: there is no "post-push" hook

Git has **no client-side post-push hook**. The nearest automatic trigger is `pre-push`,
which fires when you run `git push`. Because every clone is on the one machine, the hook
fast-forwards the main copy **directly from the pushing repo** - the commits being pushed
already exist locally, even though the GitHub remote does not have them yet. For a normal
successful push this is identical to "pull the latest after the push", with no network
round-trip and no timing race.

## Safety - what it will and will not do

The hook is deliberately conservative. It:

- **only ever fast-forwards** the main copy - it never merges, rebases or force-updates;
- acts **only when the main copy is clean and on the target branch** (`main`). If it has
  uncommitted changes, is on another branch, or has diverged, the sync is **skipped with a
  warning and nothing is touched**;
- **never blocks your push.** It runs at pre-push but always exits 0, so even if the sync
  is skipped for any reason, your `git push` proceeds exactly as normal.

So the worst case is "the main copy was not updated, and it told you why" - never a lost
commit or a clobbered working tree.

## Setting it up

Run the installer once. It **auto-discovers** every sibling Local site that clones the same
repo and wires each one up; re-run it any time to refresh, or after cloning the plugin into
a new site.

```bash
# Windows
.\Install-MariartSync.ps1
```
```bash
# macOS / Linux
./install-mariart-sync.sh
```

| Task | Windows | macOS / Linux |
|---|---|---|
| Wire up / refresh all site clones | `.\Install-MariartSync.ps1` | `./install-mariart-sync.sh` |
| See what is wired up | `.\Install-MariartSync.ps1 -Status` | `./install-mariart-sync.sh --status` |
| Remove the hook + config | `.\Install-MariartSync.ps1 -Uninstall` | `./install-mariart-sync.sh --uninstall` |
| Wire a specific clone only | `.\Install-MariartSync.ps1 -Source "<path>"` | `./install-mariart-sync.sh --source "<path>"` |
| Point at a different main copy | `.\Install-MariartSync.ps1 -Target "<path>"` | `./install-mariart-sync.sh --target "<path>"` |

Defaults: main copy = `C:\Users\michael\Local Sites\mariart\app\public\wp-content\plugins\mariart`
(Windows) or `~/Local Sites/mariart/...` (macOS); branch `main`; remote `origin`. An existing,
non-Mariart `pre-push` hook is left in place and reported - pass `-Force` / `--force` to replace it.

## How it is wired

Each site clone gets, **locally to that clone** (nothing is committed to the plugin repo):

- a `pre-push` git hook in `.git/hooks/pre-push` (a copy of `tools/mariart-sync/pre-push.sh`);
- three git config values it reads:

  ```
  mariart.sync.target   absolute path of the main copy to fast-forward
  mariart.sync.branch   branch to keep in sync (main)
  mariart.sync.remote   only sync when pushing here (origin)
  ```

Because hooks and local git config live inside each clone's `.git` and are **not** part of
the repository, they do not travel with a clone: **re-run the installer after re-cloning a
site**, or when a new site starts using the plugin.

## The pieces (in this repo)

| File | What it is |
|---|---|
| `tools/mariart-sync/pre-push.sh` | the hook itself (source of truth; copied into each clone) |
| `Install-MariartSync.ps1` | Windows installer / status / uninstall |
| `install-mariart-sync.sh` | macOS/Linux installer / status / uninstall |
| `MARIART-SYNC.md` | this document |

For how the plugin repo is laid out across sites (canonical vs. site clones), see the
`mariart-plugin-link` note in memory.
