# Release Checklist

## Before Push

- Run `moon version --all`.
- Run `moon fmt --check`.
- Run `moon info`.
- Run `moon check --deny-warn --target all`.
- Run `moon test --deny-warn --target all`.
- Run `powershell -ExecutionPolicy Bypass -File scripts/verify_acceptance.ps1 -SkipMooncakes`.
- Confirm `docs/release-alignment.md` still matches the intended release state.

If the local Windows environment lacks `cl`, `gcc`, or `clang`, keep the full
multi-target `moon test --deny-warn --target all` check in CI and use
`scripts/verify_acceptance.ps1` as the local acceptance gate.

## Before Mooncakes Publish

- Confirm `moon.mod` metadata matches the public repository.
- Confirm `CHANGELOG.md` describes the `0.3.0` operational expansion after the
  `0.2.1` MoonBit 0.10.3 compatibility patch.
- Confirm `README.md` package version and Mooncakes status match `moon.mod`.
- Confirm no generated `_build/` files are staged.
- Run `moon publish --dry-run`.

## Publish

- Authenticate the Mooncakes account that matches module owner `Rz-coder8848`.
- Run `moon publish`.
- Verify the module appears at `https://mooncakes.io/api/v0/modules/Rz-coder8848/moon-fsm`.

## After Publish

- Re-run `powershell -ExecutionPolicy Bypass -File scripts/verify_acceptance.ps1`.
- Confirm README, `moon.mod`, and Mooncakes latest version are all `0.3.0`.
- Push the final synchronized commit to GitHub and GitLink.
- Verify GitHub and GitLink both expose `main` as the reviewer-facing default branch.
