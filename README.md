# LÖVE Template for Visual Studio Code

A pre-configured Visual Studio Code template for [LÖVE](https://love2d.org/) including GitHub Actions for automated builds.
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

## Setup

- Use this template to [create a new repository](https://docs.github.com/en/repositories/creating-and-managing-repositories/creating-a-repository-from-a-template) for your game, then clone that repository locally.
- Open the `Workspace.code-workspace` file with Visual Studio Code.
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
  - **Make sure that `PRODUCT_UUID` is changed using `uuidgen`**.
- Replace `resources/icon.png` with your game's high-resolution icon.

## Running

- Press <kbd>Alt</kbd> + <kbd>L</kbd> or <kbd>Ctrl</kbd> + <kbd>F5</kbd> to **Run** the game.
- Press <kbd>F5</kbd> to **Debug** the game.
  - In debug mode you can use breakpoints and inspect variables.
  - This does have some performance impact though.
  - You can switch to *Release mode* in the `Run and Debug` tab (<kbd>Ctrl</kbd> + <kbd>Shift</kbd> + <kbd>D</kbd>)

## Building

Builds a date stamped `.love` file and puts it in the `builds` folder.
Doubles up as a poor man's backup system.

- Press <kbd>Ctrl</kbd> + <kbd>Shift</kbd> + <kbd>B</kbd> to **Build** the game.

# Releasing

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

The GitHub Actions workflow will automatically build and package the game for all the supported platforms.

- Android
  - `.apk` debug and release builds for testing
  - `.aab` release build for the Play Store
- iOS (🚧)
- Linux
  - AppImage
  - Tarball
- macOS (🚧)
  - portable .dmg
  - App Store
- Web (️🚧)
- Windows
  - win32
  - win64
  - Self-extracting archive (*64-bit only*)

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
