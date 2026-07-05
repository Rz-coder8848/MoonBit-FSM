# Release Checklist

## Before Push

- Run `moon info`.
- Run `moon fmt --check`.
- Run `moon check`.
- Run `moon test`.
- Run `powershell -ExecutionPolicy Bypass -File scripts/verify_acceptance.ps1 -SkipMooncakes`.

## Before Mooncakes Publish

- Confirm `moon.mod` metadata matches the public repository.
- Confirm `CHANGELOG.md` describes the current acceptance increment.
- Confirm `README.md` install and example commands are current.
- Confirm no generated `_build/` files are staged.

## Publish

- Authenticate the Mooncakes account that matches the chosen publisher.
- Run `moon publish`.
- Verify the module appears at `https://mooncakes.io/api/v0/modules/Rz-coder8848/moon-fsm`.

## After Publish

- Update `README.md` if the Mooncakes status changed from pending to published.
- Re-run `powershell -ExecutionPolicy Bypass -File scripts/verify_acceptance.ps1`.
- Push the final synchronized commit to GitHub and GitLink.
