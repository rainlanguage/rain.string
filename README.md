# rain.string

Low-level string and parsing primitives used to build Rainlang. Specialised
parsing logic lives in dedicated Rainlang repos; this is the broadly-applicable,
gas-efficient base.

Parsing in Rainlang works like a bloom filter over individual characters. Read a
byte from memory, bit-shift, compare against a 32-byte mask representing
characters of interest (e.g. `0-9`, or `a-zA-Z0-9`). No regexes, in-memory sets,
or loops — every ASCII char fits unambiguously in a single 32-byte EVM word.

## Install

Via [soldeer](https://soldeer.xyz):

```sh
forge soldeer install rain-string~<version>
```

## Develop

This repo uses [nix](https://nixos.org/download.html). The default shell is the
slim `sol-shell` from [rainix](https://github.com/rainlanguage/rainix).

```sh
nix develop          # enter the shell
forge soldeer install # install deps declared in foundry.toml
forge test
```

Tasks:

- `rainix-sol-test` — `forge test`
- `rainix-sol-static` — slither
- `rainix-sol-legal` — `reuse lint`

Use the nix-pinned `forge` for all development.

## Publish

Tag `v<x.y.z>` on `main`. The
[`Publish to Soldeer`](.github/workflows/publish-soldeer.yaml) wrapper delegates
to rainix's reusable workflow, which derives the package name from the repo name
(`rain.string` → `rain-string`).

## License

DecentraLicense 1.0 (DCL-1.0) — full text in
[`LICENSES/`](LICENSES/LicenseRef-DCL-1.0.txt). Roughly `CAL-1.0`
([opensource.org](https://opensource.org/license/cal-1-0)) plus user-data
disclosure obligations consistent with permissionless-blockchain assumptions.

This repo is [REUSE 3.2](https://reuse.software/spec-3.2/) compliant. Verify
locally:

```sh
nix develop -c rainix-sol-legal
```

## Contributions

Welcome under the same license. Contributors warrant that their contributions
are compliant.
