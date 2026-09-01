# bits-providers

The default **registry of repository-provider recipes** for [`bits`](https://github.com/bitsorg/bits).

`bits` builds packages from recipes it finds along a search path. This repository is
how that search path gets populated *automatically*: each `*.bits.sh` file here is a
tiny recipe that tells `bits` where to clone a recipe repository from, and how those
repositories depend on one another. Point `bits` at a community (by name) and it walks
this registry to pull in exactly the repositories that community needs.

---

## How bits uses this repository

`bits` seeds its recipe search path (`$BITS_PATH`) from local `*.bits` checkouts and
from **repository-provider recipes** — ordinary recipes carrying `provides_repository: true`
whose `source` points at a recipe repo. `bits-providers` is the default set of those
recipes (`$BITS_PROVIDERS`).

When `bits` selects a community — from `$BITS_ORGANISATION` (e.g. `ALICE` →
`alice.bits`) or because another recipe `requires:` it — it:

1. reads the matching `<name>.bits.sh` provider recipe here;
2. clones its `source` at `tag:` into `sw/REPOS/<pkg>/<hash>/`;
3. adds that checkout to `$BITS_PATH` and **rescans**, following any `requires:` to more
   providers, until the repository graph is stable;
4. folds each provider's resolved **commit hash into every package's build hash**, so
   bumping a pool (a new `tag`/commit) triggers exactly the rebuilds it should.

The result is that a community front-end repository (say `stacks.bits`) automatically
pulls in the shared recipe pools it depends on (`lcg.bits`) with no manual configuration.

---

## Provider recipe format

A provider recipe is a few lines of YAML:

```yaml
package: lcg.bits              # provider name (matches the file name)
version: "1"                   # provider version (bumped when the mapping changes)
tag: "main"                    # branch, tag, or commit of `source` to clone
provides_repository: true      # marks this recipe as a repository provider
always_load: true              # always make this repo's recipes available (shared pools)
source: https://github.com/bitsorg/lcg.bits
requires:                      # other providers to pull in first
  - some.other.bits
```

| Field | Meaning |
|---|---|
| `package` | Provider identifier; matches the `*.bits.sh` file name and the `requires:` target used elsewhere. |
| `version` | Provider-recipe version. Bump it when the provider mapping itself changes. |
| `tag` | Which branch/tag/commit of `source` to clone. Community stacks usually override this per release (e.g. `stacks.bits` pins `lcg.bits` to the release label). |
| `commit` | *(optional)* Integrity pin: the full or ≥7-char commit SHA `tag` must resolve to. When set, `bits` verifies the resolved commit and **refuses to build** (fail-closed) if it differs — so a force-push or account compromise that moves a mutable branch cannot silently change what is built. Moving the pin is a deliberate, reviewed recipe change. Omit it to track `tag` as-is. |
| `provides_repository` | Must be `true` — this is what makes `bits` treat the recipe as a repo provider rather than a buildable package. |
| `always_load` | When `true`, the repo's recipes are always made available once the provider is reached. Used for **shared recipe pools** (`lcg.bits`, `common.bits`, `alidist`) that many communities draw from. Omitted on community front-ends, which are loaded on demand. |
| `source` | Git URL of the recipe repository to clone. |
| `requires` | Other providers this one depends on; `bits` resolves them transitively. |

---

## The provider graph

Community front-ends declare `requires:` on the shared pools, so selecting one pulls in
the whole chain:

| Provider | Kind | Pulls in (`requires`) | Source |
|---|---|---|---|
| `lcg.bits` | shared pool (`always_load`) | — | `bitsorg/lcg.bits` |
| `common.bits` | shared pool (`always_load`) | — | `bitsorg/common.bits` |
| `alidist.bits` | shared pool (`always_load`) | — | `alisw/alidist` |
| `stacks.bits` | community (LCG/EP-SFT) | `lcg.bits` | `bitsorg/stacks.bits` |
| `key4hep.bits` | community (FCC) | `lcg.bits` | `bitsorg/key4hep.bits` |
| `lhcb.bits` | community | `lcg.bits` | `bitsorg/lhcb.bits` |
| `ship.bits` | community | `lcg.bits` | `bitsorg/ship.bits` |
| `cms.bits` | community (`always_load`) | — | `bitsorg/cms.bits` |
| `alice.bits` | community | `alidist.bits` | `bitsorg/alice.bits` |
| `testbed.bits` | test community | `stacks.bits` | `bitsorg/testbed.bits` |

So, for example, `testbed.bits → stacks.bits → lcg.bits`, and `alice.bits → alidist.bits`.
The recipes themselves live in the target repositories; this repo only records where they
are and how they compose. For the policy/layout each community applies on top of its pool,
see that community's own repository (e.g. [`stacks.bits`](https://github.com/bitsorg/stacks.bits)).

---

## `registry.json` — the human-facing catalog

`registry.json` is a machine-readable catalog of the same repositories, consumed by
tooling such as the bits-console UI to present a browsable list of communities. Each entry
carries presentation metadata rather than build wiring:

```json
{
  "id": "stacks.bits",
  "name": "SPI/EP-SFT Repository",
  "owner": "CERN/EP-SFT",
  "repo": "stacks.bits",
  "branch": "main",
  "description": "CERN SPI/EP-SFT project repository",
  "tags": ["hep", "cern", "lcg", "ep-sft"],
  "homepage": "https://github.com/bitsorg/stacks.bits"
}
```

| Field | Meaning |
|---|---|
| `id` | Registry key (normally the provider name). |
| `name` | Human-readable community/stack name. |
| `owner` | Owning experiment or group. |
| `repo` / `branch` | Repository name and default branch. |
| `description` | One-line summary shown in listings. |
| `tags` | Free-form labels for search/filtering. |
| `homepage` | Canonical URL of the repository. |

`registry.json` is descriptive (a catalog for discovery); the `*.bits.sh` recipes are what
`bits` actually resolves and clones. Keep the two in sync when adding or renaming a repo.

---

## Adding a provider

1. Add `<name>.bits.sh` with `provides_repository: true`, the `source` URL, the `tag` to
   track, and any `requires:` on shared pools (`lcg.bits`, `common.bits`, `alidist.bits`).
   Add `always_load: true` only for a repository whose recipes should always be available.
2. Add a matching entry to `registry.json` so the community appears in listings.
3. Bump the provider `version` when you change an existing mapping.

Users then select it with `BITS_ORGANISATION=<NAME> bits build <pkg>`, or by having their
stack `requires:` it.

---

## Related repositories

- [`bits`](https://github.com/bitsorg/bits) — the build tool that consumes these providers.
- [`lcg.bits`](https://github.com/bitsorg/lcg.bits), [`common.bits`](https://github.com/bitsorg/common.bits) — shared recipe pools.
- [`stacks.bits`](https://github.com/bitsorg/stacks.bits) and the other `*.bits` community repositories — policy/layout on top of the pools.

## License

See [`LICENSE`](LICENSE) and [`COPYRIGHT`](COPYRIGHT).
