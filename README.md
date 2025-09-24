# rain.string

Tools for working with strings that we've found useful to build Rainlang.

More specialised and complex parsing logic exists in other Rainlang repos, but
this stuff is broadly applicable and low level enough to be gas efficient enough
to do what needs to be done.

Generally parsing in rainlang works like a bloom filter on individual characters.
We read characters from memory one byte at a time then bit shift to compare it
against a bitmap mask that represents characters of interest. For example we
might need to know if a character is numeric `0-9` or alphanumeric `a-zA-Z0-9`,
and we cannot rely on regexes, in-memory sets, or even loops, that might be
easily at hand for similar tasks in other languages.

Luckily, EVM values are 32 bytes and so we can fit all posssible ASCII characters
in a single value as a bloom without any ambiguity.

## Dev stuff

### Local environment & CI

Uses nixos.

Install `nix develop` - https://nixos.org/download.html.

Run `nix develop` in this repo to drop into the shell. Please ONLY use the nix
version of `foundry` for development, to ensure versions are all compatible.

Read the `flake.nix` file to find some additional commands included for dev and
CI usage.

## Legal stuff

Everything is under DecentraLicense 1.0 (DCL-1.0) which can be found in `LICENSES/`.

This is basically `CAL-1.0` which is an open source license
https://opensource.org/license/cal-1-0

The non-legal summary of DCL-1.0 is that the source is open, as expected, but
also user data in the systems that this code runs on must also be made available
to those users as relevant, and that private keys remain private.

Roughly it's "not your keys, not your coins" aware, as close as we could get in
legalese.

This is the default situation on permissionless blockchains, so shouldn't require
any additional effort by dev-users to adhere to the license terms.

This repo is REUSE 3.2 compliant https://reuse.software/spec-3.2/ and compatible
with `reuse` tooling (also available in the nix shell here).

```
nix develop -c rainix-sol-legal
```

## Contributions

Contributions are welcome **under the same license** as above.

Contributors agree and warrant that their contributions are compliant.