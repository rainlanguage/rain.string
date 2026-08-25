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

## Breaking changes

### 0.3.0

The content of 0.3.0 is already present in registry revisions 0.2.4–0.2.14,
which were published without a major-version signal. Treat 0.2.3–0.2.14 as
skipped and bump directly from 0.2.2 to 0.3.0.

- All `CMASK_*` constants widened from `uint128` to `uint256`. Audit every bare
  `~CMASK_*` complement in consuming code: bits 128–255 (bytes 0x80–0xFF) are
  now SET in complements that previously cleared them, so scans over
  hand-complemented masks change acceptance of high bytes with no compile error.
- `CMASK_NOT_IDENTIFIER_TAIL` is now the full byte-domain complement of
  `CMASK_IDENTIFIER_TAIL`: bytes 0x80–0xFF are in the mask.
- `LibConformString.conformStringToMask(str, mask, max)` is now
  `conformStringToMask(str, mask)`; the reroll bound derives from the mask's bit
  length and the `max` parameter is gone from every overload.
- `CMASK_COMMENT_END_SEQUENCE_END` renamed to `COMMENT_END_SEQUENCE_END` and
  `CMASK_LITERAL_HEX_DISPATCH_START` renamed to
  `LITERAL_HEX_DISPATCH_START_SEQUENCE` (they are byte values, not character
  masks).
- `LibParseDecimal.unsafeDecimalStringToInt` and
  `unsafeDecimalStringToSignedInt` return `ParseInvalidDecimalChar.selector` for
  any non-digit byte instead of silent garbage arithmetic, and revert
  `ZeroStringStartPointer` on a zero start pointer before any memory read.
- `LibConformString.charFromMask` consults the seed on every draw (first
  candidate is the seed's low byte), so outputs differ from 0.2.x for every
  `(seed, mask)` pair; `corruptSingleChar` can now produce corruption bytes ≥
  0x80.

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
