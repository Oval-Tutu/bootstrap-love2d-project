# Bootstrap LÖVE Projects

A pre-configured template for [LÖVE](https://love2d.org/) including GitHub Actions for automated builds.
Inspired by and adapted from [LOVE VSCode Game Template](https://github.com/Keyslam/LOVE-VSCode-Game-Template) and [LÖVE Actions](https://github.com/love-actions).

## Features

- 🌕 Rich Lua language features with [Lua Language Server](https://github.com/LuaLS/lua-language-server)
- 🐛 Debugging with [Local Lua Debugger](https://github.com/tomblind/local-lua-debugger-vscode)
- 🩷 Intellisense for the LÖVE API via [Love2D Support](https://marketplace.visualstudio.com/items?itemName=pixelbyte-studios.pixelbyte-love2d)
- 👨‍💻 Consistent coding styles with [Editorconfig](https://github.com/editorconfig/editorconfig-vscode)
- ️⛱️ [Shader languages support](https://marketplace.visualstudio.com/items?itemName=slevesque.shader)
- 🐙 [GitHub Local Actions](https://marketplace.visualstudio.com/items?itemName=SanjulaGanepola.github-local-actions)
- 📦 GitHub Actions for automated builds
  - Compatible with [act](https://nektosact.com/)
- ️👷 Automated builds of the `.love` file from within Visual Studio Code
- 🗂️ Organized with [Workspaces](https://code.visualstudio.com/docs/editor/workspaces)
- ️⚙️ [Shared product configuration](game/product.env) between the game and the GitHub Actions
- ️❄️ Nix flake to provision a dev shell

## Prerequisites

- Visual Studio Code
- [LÖVE 11.5](https://love2d.org/) (*currently only 11.5 is supported*)
  - **`love` should be in your `PATH`**
- `bash`
- `7z`
- `miniserve` (*optional ️for local testing of web builds*)

## Setup

- Use this template to [create a new repository](https://docs.github.com/en/repositories/creating-and-managing-repositories/creating-a-repository-from-a-template) for your game, then clone that repository locally.
- Open the `Workspace.code-workspace` file with [Visual Studio Code](https://code.visualstudio.com/) or [VSCodium](https://vscodium.com/)
  - You will be prompted that there are recommended extensions.
    - Click 'Install'
  - If this does not happen, install:
    - [Lua](https://marketplace.visualstudio.com/items?itemName=sumneko.lua)
    - [Local Lua Debugger](https://marketplace.visualstudio.com/items?itemName=tomblind.local-lua-debugger-vscode)
    - [Love2D Support](https://marketplace.visualstudio.com/items?itemName=pixelbyte-studios.pixelbyte-love2d)
    - [Editorconfig](https://marketplace.visualstudio.com/items?itemName=EditorConfig.EditorConfig)
    - [GitHub Local Actions](https://marketplace.visualstudio.com/items?itemName=SanjulaGanepola.github-local-actions) (*optional*)
    - [Shader languages support](https://marketplace.visualstudio.com/items?itemName=slevesque.shader) (*optional*)
- Configure `game/product.env` and `game/conf.lua` with the settings specific to your game.
  - **Make sure that `PRODUCT_UUID` is changed using `uuidgen`** or the [UUID Generator](https://www.uuidgenerator.net/)
- Replace `resources/icon.png` with your game's high-resolution icon.
- Add the following secrets to your GitHub repository if you [build for Android](https://github.com/Oval-Tutu/bootstrap-love2d-project?tab=readme-ov-file#android):
  - `ANDROID_DEBUG_SIGNINGKEY_BASE64`
  - `ANDROID_DEBUG_ALIAS`
  - `ANDROID_DEBUG_KEYSTORE_PASSWORD`
  - `ANDROID_DEBUG_KEY_PASSWORD`
  - `ANDROID_RELEASE_SIGNINGKEY_BASE64`
  - `ANDROID_RELEASE_ALIAS`
  - `ANDROID_RELEASE_KEYSTORE_PASSWORD`
  - `ANDROID_RELEASE_KEY_PASSWORD`
- Add the following secret to your GitHub repository if you want to publish to Itch.io:
  - `BUTLER_API_KEY`

## Running

- Press <kbd>Ctrl</kbd> + <kbd>F5</kbd> to **Run** the game.
- Press <kbd>F5</kbd> to **Debug** the game.
  - In debug mode you can use breakpoints and inspect variables.
  - This does have some performance impact though.
  - You can switch to *Release mode* in the `Run and Debug` tab (<kbd>Ctrl</kbd> + <kbd>Shift</kbd> + <kbd>D</kbd>)

## Building

Builds a date stamped `.love` file and puts it in the `builds` folder.
Doubles up as a poor man's backup system.

- Press <kbd>Ctrl</kbd> + <kbd>Shift</kbd> + <kbd>B</kbd> to **Build** the game.

## Configuring

The game and build settings are configured using `game/product.env`.
The most important settings to change for your game:

- `PRODUCT_NAME` - The name of your game
- `PRODUCT_ID` - Unique identifier in reverse domain notation. **Can not contain spaces or hyphens**.
- `PRODUCT_UUID` - Generate new UUID using `uuidgen` command or the [UUID Generator](https://www.uuidgenerator.net/)
- `PRODUCT_DESC` - Short description of your game
- `PRODUCT_COPYRIGHT` - Copyright notice
- `PRODUCT_COMPANY` - Your company/organization name
- `PRODUCT_WEBSITE` - Your game or company website

### Build Targets

You can disable build targets by setting them to `"false"` if you don't need builds for certain platforms.

```shell
# LÖVE version to target (only 11.5 is supported)
LOVE_VERSION="11.5"

# Enable/disable microphone access
AUDIO_MIC="false"

# Android screen orientation (landscape/portrait)
ANDROID_ORIENTATION="landscape"

# Itch.io username for publishing
ITCH_USER="ovaltutu"

# Build output directory
OUTPUT_FOLDER="./builds"

# Game metadata
PRODUCT_NAME="Template"
PRODUCT_ID="com.ovaltutu.template"
PRODUCT_DESC="A template game made with LÖVE"
PRODUCT_COPYRIGHT="Copyright (c) 2025 Oval Tutu"
PRODUCT_COMPANY="Oval Tutu"
PRODUCT_WEBSITE="https://oval-tutu.com"
PRODUCT_UUID="3e64d17c-8797-4382-921f-cf488b22073f"

# Enable/disable build targets
TARGET_ANDROID="true"
TARGET_IOS="true"
TARGET_LINUX_APPIMAGE="true"
TARGET_LINUX_TARBALL="true"
TARGET_MACOS="true"
TARGET_WEB="true"
TARGET_WINDOWS_ZIP="true"
TARGET_WINDOWS_SFX="true"
```

## Releasing

Make a new release by creating a version number git tag **without the `v` prefix**.

- **Create a new tag**: Use the following command to create a new tag.
  - *Replace `1.0.0` with your desired version number.*
```bash
git tag 1.0.0
```

- **Push the tag to GitHub**: Push the tag to the remote repository.
```bash
git push origin 1.0.0
```

- **GitHub Actions**: The GitHub workflow will automatically create a release and upload packages for all the supported platforms as an assets.

### Publishing

On a full release (a tagged version), the GitHub Actions workflow will automatically publish the game artifacts for the enabled platforms to the GitHub releases page.
You can download the artifacts from the releases page and manually upload them to the appropriate stores.
But you can also automate this process for the following platforms:

#### Itch.io

The GitHub Actions workflow will automatically publish the game artifacts for *enabled platforms* to Itch.io if `BUTLER_API_KEY` secret and `ITCH_USER` are set.
Get your API key from [Itch.io account](https://itch.io/user/settings/api-keys).
`ITCH_USER` from `game/product.env` will be used as the username, and `PRODUCT_NAME` from `game/product.env` (converted to lowercase with spaces replaced with hyphens `-`) will be used as the game name.

For example this template project would attempt to publish to `ovaltutu/Template`.

Not every artifact will be published to Itch.io, as some platforms are not supported, and some artifacts are unsuitable for distribution on Itch.io:

- Android .apk files will be published to Itch.io if `TARGET_ANDROID` is enabled.
- Linux AppImage files will be published to Itch.io if `TARGET_LINUX_APPIMAGE` is enabled.
- macOS .dmg files will be published to Itch.io if `TARGET_MACOS` is enabled.
- Windows win64 self-extracting .exe files will be published to Itch.io if `TARGET_WINDOWS_SFX` is enabled.
- Web artifacts will be published to Itch.io if `TARGET_WEB` is enabled.
- Itch.io does not support iOS artifacts.

## Structure
```
.
├── .github                   GitHub Actions configuration
├── .editorconfig             EditorConfig file
├── .vscode                   Visual Studio Code configuration
│   ├── extensions.json
│   ├── launch.json
│   ├── settings.json
│   └── tasks.json
├── builds                    Game builds
├── game
│   ├── conf.lua              LÖVE configuration file
│   ├── main.lua              The main entry point of the game
│   ├── product.env           Settings shared between the game and GitHub Actions
│   ├── assets                Game assets
│   ├── lib                   3rd party libraries
│   └── src                   Source code
├── resources                 Resources use when building the game. Icons, shared libraries, etc.
└── tools                     Tools for building and packaging the game
```

### .vscode

The `.vscode` folder contains project specific configuration.

- `extensions.json`: Contains the list of recommended extensions
- `launch.json`: Contains the settings for running the game or launching the debugger
- `settings.json`: Contains the settings for the Lua extension
- `tasks.json`: Contains the settings for building the game

## GitHub Actions

The GitHub Actions workflow will automatically build and package the game for all the supported platforms that are enabled in `game/product.env` and upload them as assets to the GitHub releases page.

- Android
  - `.apk` debug and release builds for testing
  - `.aab` release build for the Play Store
- iOS (*notarization is not yet implemented*)
- Linux
  - AppImage
  - Tarball
- macOS
  - `.app` Bundle (*notarizing is not yet implemented*)
  - `.dmg` Disk Image (*notarizing is not yet implemented*)
- Web
- Windows
  - win32 .zip
  - win64 .zip
  - win64 .exe (*self-extracting*)

### Local GitHub Action via act

In order to use the GitHub Actions locally, you'll need to install [act](https://nektosact.com/) and [Podman](https://podman.io/) or [Docker](https://www.docker.com/).

This template includes `.actrc` which will source local secrets and expose as GiutHub secrets to `act`.

The `.actrc` file configures how `act` runs GitHub Actions locally:

```plaintext
# Load GitHub secrets from this file
--secret-file=$HOME/.config/act/secrets

# Store build artifacts in the ./builds directory
--artifact-server-path=./builds

# Force container architecture to linux/amd64
--container-architecture=linux/amd64

# Disable automatic pulling of container images
--pull=false
```

Key configuration explained:

- `--secret-file` - Path to file containing GitHub secrets (API keys, signing keys etc.)
- `--artifact-server-path` - Local directory where build artifacts will be stored
- `--container-architecture` - Forces x86_64 container architecture for compatibility
- `--pull` - Prevents automatic downloading of container images on each run

Create the secrets file at `~/.config/act/secrets` with your GitHub repository secrets before running act.

#### macOS

- Install [Podman Desktop](https://podman-desktop.io/) or [Docker Desktop](https://www.docker.com/products/docker-desktop/).
- Install [Xcode](https://developer.apple.com/xcode/): `xcode-select --install`
- Install additional tools via [Homebrew](https://brew.sh/): `brew install act create-dmg tree`

### Running the GitHub Actions locally

- `act` will run all the GitHub Actions locally.
- `act -l` will list all the available GitHub Actions.
- `act -j <job>` will run a specific job.
- To run jobs that runs-on: `macos-latest` on your Mac you'll need to use `act -P macos-latest=-self-hosted` which will run the job on your Mac instead of the GitHub runner. For example:
  - `act -j build-macos -P macos-latest=-self-hosted`

### Android

In order to sign the APKs and AABs, the [zipalign & Sign Android Release Action](https://github.com/kevin-david/zipalign-sign-android-release) is used. You'll need to create Debug and Release keystores and set the appropriate secrets in the GitHub repository settings.

#### Debug

This creates a standard debug keystore matching Android Studio's defaults, except it is valid for 50 years.

```shell
keytool -genkey -v \
  -keystore debug.keystore \
  -alias androiddebugkey \
  -keyalg RSA -keysize 2048 -validity 18250 \
  -storepass android \
  -keypass android \
  -dname "CN=Android Debug,O=Android,C=US"
```

Create base64 encoded signing key to sign apps in GitHub CI.

```shell
openssl base64 < debug.keystore | tr -d '\n' | tee debug.keystore.base64.txt
```

Add these secrets to the GitHub repository settings:

- `ANDROID_DEBUG_SIGNINGKEY_BASE64`
- `ANDROID_DEBUG_ALIAS`
- `ANDROID_DEBUG_KEYSTORE_PASSWORD`
- `ANDROID_DEBUG_KEY_PASSWORD`

#### Release

This creates a release keystore with a validity of 25 years.

```shell
keytool -genkey -v \
  -keystore release-key.jks \
  -alias release-key \
  -keyalg RSA -keysize 2048 -validity 9125 \
  -storepass [secure-password] \
  -keypass [secure-password] \
  -dname "CN=[your name],O=[your organisation],L=[your town/city],S=[your state/region/county],C=[your country code]"
```

Create base64 encoded signing key to sign apps in GitHub CI.

```shell
openssl base64 < release-key.jks | tr -d '\n' | tee release-key.jks.base64.txt
```

Add these secrets to the GitHub repository settings:

- `ANDROID_RELEASE_SIGNINGKEY_BASE64`
- `ANDROID_RELEASE_ALIAS`
- `ANDROID_RELEASE_KEYSTORE_PASSWORD`
- `ANDROID_RELEASE_KEY_PASSWORD`

### Web

The web build uses [love.js player](https://github.com/2dengine/love.js) from [2dengine](https://2dengine.com/).

The love.js player needs to be delivered via a web server, **it will not work if you open `index.html` locally in a browser**.
You need to set the correct [CORS policy via HTTP headers](https://developer.chrome.com/blog/enabling-shared-array-buffer/) for the game to work in the browser.
Here are some examples of how to do that.

#### Local Testing

Use [`miniserve`](https://github.com/svenstaro/miniserve) to serve the web build of the game using the correct CORS policy.
`tools/serve-web.sh` is a convenience script that does that. It take one argument which is the path to the zip file of the web build.

```shell
./tools/serve-web.sh builds/1/Template-25.009.0930_web/Template-25.009.0930_web.zip
```

Then open `http://localhost:1337` in your browser.

#### Self-Hosting

**apache**

```apache
<IfModule mod_headers.c>
  Header set Cross-Origin-Opener-Policy "same-origin"
  Header set Cross-Origin-Embedder-Policy "require-corp"
</IfModule>
<IfModule mod_mime.c>
  AddType application/wasm wasm
</IfModule>
```

**caddy**

```
example.com {
    header {
        Cross-Origin-Opener-Policy "same-origin"
        Cross-Origin-Embedder-Policy "require-corp"
        Set-Cookie "Path=/; HttpOnly; Secure"
    }
    # ... rest of your site configuration
}
```

**nginx**

```nginx
add_header Cross-Origin-Opener-Policy "same-origin";
add_header Cross-Origin-Embedder-Policy "require-corp";
add_header Set-Cookie "Path=/; HttpOnly; Secure";
```

#### Itch.io Web Player

On [itch.io](https://itch.io/), the required HTTP headers are disabled by default, but they provide experimental support for enabling them.
Learn how to [enable SharedArrayBuffer support on Itch.io](https://itch.io/t/2025776/experimental-sharedarraybuffer-support).
