# Euclid Release Process

## Overview

Releases are triggered by pushing git tags. The system automatically:
- Builds & signs the app
- Notarizes with Apple
- Creates DMG + ZIP artifacts
- Publishes artifacts to GitHub Releases
- Updates the GitHub-hosted Sparkle appcast

## Quick Start

```bash
# Create and push a tag
git tag v0.2.12
git push origin v0.2.12

# GitHub Actions will automatically:
# 1. Build Euclid v0.2.12
# 2. Notarize with Apple
# 3. Create/update the GitHub release with DMG + ZIP
# 4. Refresh appcast.xml in the repository
```

## Architecture

**Tag-based versioning:**
- Tag `v0.2.12` → builds version `0.2.12`
- Updates `Info.plist` and `project.pbxproj`
- Auto-increments build number

**Effect Config system:**
```typescript
// Reads from environment variables
VERSION=v0.2.12                  // From git tag
APPLE_ID=your@email.com         // CI only
APPLE_ID_PASSWORD=xxxx-xxxx     // CI only
```

**Local vs CI:**
- **Local**: Uses keychain profile `AC_PASSWORD`
- **CI**: Uses `APPLE_ID` / `APPLE_ID_PASSWORD` env vars

## Local Testing

```bash
# Setup keychain profile (one-time)
xcrun notarytool store-credentials "AC_PASSWORD"

# Test release locally (doesn't publish)
cd tools
VERSION=v0.2.12-test \
  bun run release.ts
```

## Required Secrets

Set via: `gh secret set SECRET_NAME`

### Apple (Notarization)
```bash
APPLE_ID                    # your@email.com
APPLE_ID_PASSWORD          # App-specific password from appleid.apple.com
TEAM_ID                     # QC99C9JE59
```

### Code Signing
```bash
MACOS_CERTIFICATE          # base64 -i cert.p12 | pbcopy
MACOS_CERTIFICATE_PWD      # Certificate password
```

## Artifacts

Each release creates:
- `Euclid-{version}.dmg` - Signed, notarized DMG
- `Euclid-{version}.zip` - For Homebrew cask
- `appcast.xml` - Sparkle update feed committed to the repository and served from GitHub

## Homebrew Cask

After first release, update `euclid.rb`:

```bash
# Get SHA256
curl -L https://github.com/botnetai/euclid/releases/download/v0.2.12/Euclid-v0.2.12.zip -o Euclid.zip
shasum -a 256 Euclid.zip

# Update euclid.rb with version and SHA
```

Submit to:
- **Personal tap**: `homebrew-euclid` (easier)
- **Official cask**: PR to `homebrew/homebrew-cask`

## Critical Constraints

### CFBundleVersion Requirements

**NEVER manually edit CFBundleVersion or reuse build numbers.** The release pipeline automatically increments CFBundleVersion with each release to ensure Sparkle can properly generate the appcast feed.

- `updates/` directory must only contain DMGs with strictly increasing CFBundleVersion values
- Duplicate build numbers will block appcast generation and break updates for existing users
- The release script preserves the last 3 DMGs in `updates/` for delta generation
- Older versions are automatically moved to `updates/old_updates/`

If you accidentally create a release with a duplicate CFBundleVersion:
1. Delete the problematic DMG from `updates/`
2. Move any other old DMGs to `updates/old_updates/`
3. Regenerate appcast: `./bin/generate_appcast --maximum-deltas 3 updates`
4. Re-publish cleaned artifacts to GitHub Releases and commit the regenerated `appcast.xml`

## Troubleshooting

### Notarization fails
- Check Apple ID credentials
- Verify app-specific password
- Ensure `TEAM_ID` is correct

### GitHub publish fails
- Verify `gh auth status`
- Check release permissions for the token or workflow
- Confirm the target repository exists and is reachable

### Build fails
- Check Xcode version (16.2)
- Verify code signing setup
- Check certificate validity

### Sparkle updates not appearing
- Verify appcast.xml lists versions in descending CFBundleVersion order
- Check that CFBundleVersion values are unique and strictly increasing
- Ensure no duplicate build numbers exist in updates/
- Test feed URL: https://raw.githubusercontent.com/botnetai/euclid/main/appcast.xml

## Files

- `tools/release.ts` - Main release script (Effect)
- `.github/workflows/release.yml` - CI workflow
- `bin/generate_appcast` - Sparkle appcast generator
- `euclid.rb` - Homebrew cask formula
