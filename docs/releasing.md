# Releasing FinderOne

This guide covers the maintainer setup for the [release workflow](../.github/workflows/release-macos-app.yml). For installation and everyday use, see the [README](../README.md).

## Required secrets

Configure these GitHub Actions secrets at the repository level or make organization secrets available to this repository. Never commit secret values.

| Secret | Purpose |
| --- | --- |
| `SPARKLE_PRIVATE_KEY` | Private key exported by Sparkle's `generate_keys -x`; signs update archives. |
| `SPARKLE_PUBLIC_ED_KEY` | Matching public key exported by `generate_keys -p`; embedded in the app. |
| `APPLE_CERT_BASE64` | Base64-encoded PKCS#12 file containing the Developer ID Application certificate and private key. |
| `APPLE_CERT_PASSWORD` | Password for the PKCS#12 file. |
| `APPLE_TEAM_ID` | Expected Apple Developer team; checked against the imported identity and signed app. |
| `APPLE_API_KEY_ID` | App Store Connect API key ID used for notarization. |
| `APPLE_API_ISSUER_ID` | Issuer ID for the App Store Connect API key. |
| `APPLE_API_PRIVATE_KEY` | Contents of the corresponding `.p8` private key. |

The workflow checks for missing secrets before the release build and stops if any are unavailable.

## Sparkle 2 setup

After resolving the Xcode project's dependencies, Sparkle tools are available under `tmp/DerivedData/SourcePackages/artifacts/sparkle/Sparkle/bin` when using the repository's build commands.

Generate a key pair once with `generate_keys --account FinderOne`. Use the same `--account FinderOne` argument when exporting the public key with `-p` and the private key with `-x`. Store the exported values in the corresponding secrets and securely back up the private key. Do not generate a new key pair for every release; installed apps rely on the existing public key to verify updates.

The workflow embeds the public key in `SUPublicEDKey` and signs the final notarized ZIP with the private key. It publishes `appcast.xml` alongside the archive in the same GitHub Release. FinderOne uses this update feed:

```text
https://github.com/mohnya-org/FinderOne/releases/latest/download/appcast.xml
```

The workflow targets stable releases in this public repository. Publish the ZIP and feed together.

## Versioning and publication

A push to `main`, including a merged PR, triggers automatic release version selection. The next version increments the patch number of the highest existing stable version tag. Tags reserved by other commits are skipped and never overwritten. If there are no version tags, the first version is `v0.0.1`. No source version bump commit is required.

To choose a version explicitly, manually run **Release macOS App** on `main` and set `version` to a new stable version such as `1.5.0`, without the `v` prefix. Leave it empty for automatic selection.

The selected version is embedded in `CFBundleShortVersionString` and the archive name. `CFBundleVersion` uses the GitHub Actions run number.

After building, signing, notarizing, and generating the feed, the workflow creates a tag for the triggering commit. It uploads the ZIP, SHA-256 checksum, and appcast to a draft release before publishing it, so release publication webhooks see the complete set of assets.

## Code signing and notarization

The workflow builds with Xcode signing disabled, then signs Sparkle's nested components and the host app with Developer ID, Hardened Runtime, and a secure timestamp. It verifies that the signing identity matches `APPLE_TEAM_ID`.

The signed archive is submitted with `notarytool` using the App Store Connect API key. After notarization, the workflow staples and validates the ticket, then recreates the distribution ZIP.

ZIP creation excludes resource-fork and extended-attribute metadata with `ditto --norsrc --noextattr` to prevent AppleDouble (`._*`) files from breaking framework signature validation after extraction.

Before publication, the workflow extracts the final ZIP and checks:

- Strict signature validation for the app and nested code.
- The expected Apple Developer team.
- The stapled notarization ticket.
- Gatekeeper acceptance.

The checksum and Sparkle signature are generated from the final archive. Verification failures stop publication.

## Retrying failed releases

Rerun the same Actions run after resolving the failure. A tag or draft already created for the same commit is reused; an already published release is left unchanged. Attempts to release source older than a newer stable release are rejected.

Release runs are serialized, and running jobs are not canceled. GitHub Actions concurrency may replace a pending run with a newer one when commits arrive quickly. In that case, the latest commit's release includes the accumulated changes.

## Local builds

`make build` and `make debug-build` do not use organization secrets or perform Developer ID signing and notarization. They write the app to `dist/FinderOne.app`.

Automatic updates are disabled when the Sparkle public key is omitted. To configure a local build for update testing, set `SUPublicEDKey` in the built app's `Contents/Info.plist` to the matching public key before signing it. Do not modify the bundle after signing.

Users upgrading from a version without automatic update support must install an update-capable release manually once.

## First installation: signed DMG

Releases include a signed, notarized `<app>-<version>-macOS.dmg` and its SHA-256 checksum.
Open the DMG in Finder, drag the app onto its Applications shortcut, eject the image,
and launch the installed app from Applications. Sparkle continues to use the ZIP and appcast.
Do not launch the app directly from the mounted image.

The DMG uses the existing `APPLE_CERT_BASE64` / `APPLE_CERT_PASSWORD` Developer ID
Application identity and `APPLE_TEAM_ID`. Notarization reuses `APPLE_API_KEY_ID`,
`APPLE_API_ISSUER_ID`, and `APPLE_API_PRIVATE_KEY`; no separate DMG certificate or API key
is needed. Apple Distribution certificates are not a substitute for Developer ID Application.
The workflow uses a private temporary keychain without changing the default keychain.
It signs and notarizes the image, staples its ticket, then mounts it read-only to verify
Gatekeeper acceptance, the embedded app signature/version, and the Applications shortcut.
All ZIP, DMG, checksum, and appcast files must exist before publication.

To validate a trusted branch without publishing, manually dispatch `release-macos-app.yml`
with `validate_only=true`. This uses signing secrets but creates no tag or release.
The verified DMG is retained as a workflow artifact for seven days. Offline DMG tests:
`python3 -B scripts/test-macos-dmg.py`.

Prefer organization secrets scoped to selected repositories or protected environments.
Inventory all consumers before narrowing existing all-repository access. Never copy another
organization's private keys into this project. Secret names alone do not establish certificate
validity; successful signing and notarization are required verification.

## Future PKG distribution

PKG creation is not enabled. It requires a separate **Developer ID Installer** certificate,
in addition to the Developer ID Application certificate that signs the bundled app.
An account holder should create it in Apple Developer, export it with its private key as a
password-protected `.p12`, and configure `APPLE_INSTALLER_CERT_BASE64` and
`APPLE_INSTALLER_CERT_PASSWORD` for the intended repositories. Do not replace the existing
Application certificate secrets. The current notarization API credentials can be reused;
a new App Store Connect app record or API key is not required just to add PKG packaging.

A future PKG workflow must sign with that Installer identity, notarize and staple the package,
and verify it with `pkgutil --check-signature`, `stapler validate`, and Gatekeeper's install
assessment before publication. Test installation and subsequent Sparkle updates on a clean Mac.
See [Apple's Developer ID certificate guide](https://developer.apple.com/help/account/certificates/create-developer-id-certificates/).

### Finder automation entitlement

The host app must be signed with `com.apple.security.automation.apple-events` from `Corral/FinderOne.entitlements`. Hardened Runtime otherwise blocks the Apple Events used to control Finder and System Events, even when Accessibility permission is granted. `NSAppleEventsUsageDescription` alone does not grant this capability. The signing script and final archive checks verify the embedded entitlement. Sparkle helpers do not receive this host-only entitlement. Users must also allow the Automation permission when macOS requests it.

### Self-hosted runner Python

The macOS runner must provide Python 3.10 or newer with `venv` and `pip` on its service PATH. DMG layout tools are installed from the hash-pinned `scripts/dmg-requirements.txt` into a per-run virtual environment under `RUNNER_TEMP`, which is removed during cleanup. The workflow uses the existing Python installation and does not require write access to `/Users/runner/hostedtoolcache`.
