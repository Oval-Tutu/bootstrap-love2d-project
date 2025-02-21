# LÖVE Game Development & Automated Build System

Turn your [LÖVE](https://love2d.org/) game ideas into polished multi-platform releases with this powerful template! Featuring professional IDE integration, automated builds, and everything you need to go from prototype to published game. Built for LÖVE 💕

## Features

- 🗂️ Organized with [Workspaces](https://code.visualstudio.com/docs/editor/workspaces)
  - 🌕 Rich Lua language features with [Lua Language Server](https://marketplace.visualstudio.com/items?itemName=sumneko.lua)
  - 🐛 Debugging with [Local Lua Debugger](https://marketplace.visualstudio.com/items?itemName=tomblind.local-lua-debugger-vscode)
  - 🩷 Intellisense for the LÖVE API
  - 👨‍💻 Consistent coding styles with [Editorconfig](https://marketplace.visualstudio.com/items?itemName=EditorConfig.EditorConfig)
  - ️⛱️ [Shader languages support](https://marketplace.visualstudio.com/items?itemName=slevesque.shader)
  - 🐙 [GitHub Local Actions](https://marketplace.visualstudio.com/items?itemName=SanjulaGanepola.github-local-actions)
  - ️👷 Automated builds of the `.love` file from within the IDE
- 📦 GitHub Actions for automated builds - compatible with [act](https://nektosact.com/)
  - 🤖 Android (.aab and .apk)
  - 📱 iOS (.ipa)
  - 🌐 HTML5
  - 🐧 Linux (.AppImage and tarball)
  - 🍏 macOS (App bundle and .dmg Disk Image)
  - 🪟 Windows (.exe and .zip)
  - 🎮 Automatic publishing to [itch.io](https://itch.io/)
- ️⚙️ [Shared product configuration](game/product.env) between the game and the GitHub Actions
- ️❄️ Nix flake to provision a dev shell

### Prerequisites

- [Visual Studio Code](https://code.visualstudio.com/) or [VSCodium](https://vscodium.com/)
- [LÖVE 11.5](https://love2d.org/) (*currently only 11.5 is supported*)
  - **`love` should be in your `PATH`**
- `bash`
- `7z`
- [`miniserve`](https://github.com/svenstaro/miniserve) (*optional ️for local testing of web builds*)

## Quick Start

Use this template to [create a new repository](https://docs.github.com/en/repositories/creating-and-managing-repositories/creating-a-repository-from-a-template) for your game, then clone that repository locally.

- Open the `Workspace.code-workspace` file with [Visual Studio Code](https://code.visualstudio.com/) or [VSCodium](https://vscodium.com/)
  - You will be prompted that there are recommended extensions.
    - Click *'Install'*
- Replace [`game/main.lua`](game/main.lua) with your game's code.
- Configure [`game/product.env`](game/product.env) and [`game/conf.lua`](game/conf.lua) with the settings specific to your game.
  - Disable any platforms you do not want to target.
  - Full details on configuration can be found in the [**USAGE.md**](USAGE.md) file.
- Replace `resources/icon.png` with your game's high-resolution icon.
- If you are targetting Android, you need to create a keystore for signing your game; full details are in the [**USAGE.md**](USAGE.md) file.
- If you want to publish your game to [itch.io](https://itch.io/), you need to add [`BUTLER_API_KEY`](https://itch.io/user/settings/api-keys) to your GitHub repository; full details are in the [**USAGE.md**](USAGE.md) file.

### Running

- Press <kbd>Ctrl</kbd> + <kbd>F5</kbd> to **Run** the game.
- Press <kbd>F5</kbd> to **Debug** the game.
  - In debug mode you can use breakpoints and inspect variables.
  - This does have some performance impact though.
  - You can switch to *Release mode* in the `Run and Debug` tab (<kbd>Ctrl</kbd> + <kbd>Shift</kbd> + <kbd>D</kbd>)

### Building

Builds a date stamped `.love` file and puts it in the `builds` folder.
This doubles up as a simple backup system.

- Press <kbd>Ctrl</kbd> + <kbd>Shift</kbd> + <kbd>B</kbd> to **Build** the game.

## Detailed Documentation

- [**USAGE.md**](USAGE.md)

For more detailed technical information about development workflows, build configurations, and deployment processes, please see [**USAGE.md**](USAGE.md). This companion document covers:

- Complete project structure and file organization
- Project configuration and settings
- Local development and GitHub Actions workflow details
- Platform-specific build configurations
- Release management and publishing workflows
- Web deployment configurations
- Android signing setup
- Local testing procedures

## References

Inspired by and adapted from [LOVE VSCode Game Template](https://github.com/Keyslam/LOVE-VSCode-Game-Template), [LÖVE Actions](https://github.com/love-actions) and [love.js player](https://github.com/2dengine/love.js) from [2dengine](https://2dengine.com/).
