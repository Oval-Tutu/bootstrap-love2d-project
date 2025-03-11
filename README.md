# LÖVE Game Development & Automated Build System

Turn your [LÖVE](https://love2d.org/) game ideas into polished multi-platform releases with this powerful template! Featuring professional IDE integration, automated builds, and everything you need to go from prototype to published game. Built for LÖVE 💕

- 🛑 **Don't fork this repository directly!**
- 🟢 [**Create a new repository from this template**](https://docs.github.com/en/repositories/creating-and-managing-repositories/creating-a-repository-from-a-template) for your game.

## Features

- 🗂️ Organized with [Workspaces](https://code.visualstudio.com/docs/editor/workspaces)
  - 🌕 Rich Lua language features with [Lua Helper](https://marketplace.visualstudio.com/items?itemName=yinfei.luahelper)
    - <small>Superior, high-performance, cross-platform compatible Language Server Protocol for Lua. And so much more.</small>
    - <small>`.luarc.json` is included for people wanting to use [Lua Language Server](https://marketplace.visualstudio.com/items?itemName=sumneko.lua)</small>
  - 🩷 [Intellisense for the LÖVE API](https://marketplace.visualstudio.com/items?itemName=pixelbyte-studios.pixelbyte-love2d)
  - 🐛 Debugging with [*Second* Local Lua Debugger](https://marketplace.visualstudio.com/items?itemName=ismoh-games.second-local-lua-debugger-vscode)
    - <small>A maintained fork of the original [Local Lua Debugger](https://marketplace.visualstudio.com/items?itemName=tomblind.local-lua-debugger-vscode)</small>
  - 🎑 Deterministic Lua code formatting with [StyLua](https://marketplace.visualstudio.com/items?itemName=JohnnyMorganz.stylua)
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
  - 🪟 Windows (Installer, SFX .exe and .zip)
  - 🔐 [lua-https](https://github.com/love2d/lua-https) built-in to LÖVE 11.5
  - ⤴️ Automatic publishing to [itch.io](https://itch.io/)
- ️⚙️ [Shared product configuration](game/product.env) between the game and the GitHub Actions
- 🎮 [SteamOS DevKit](https://gitlab.steamos.cloud/devkit/steamos-devkit) integration
- 📊 Integrated performance metrics overlay
- ️❄️ Nix flake to provision a dev shell

### Prerequisites

- [Visual Studio Code](https://code.visualstudio.com/) or [VSCodium](https://vscodium.com/)
- [LÖVE 11.5](https://love2d.org/) (*currently only 11.5 is supported*)
  - **`love` should be in your `PATH`**
- `bash`
- `7z`
- [`miniserve`](https://github.com/svenstaro/miniserve) (*optional ️for local testing of HTML builds*)

## Platform Support

| Platform | Artifact Type | Extension        | Store      | lua-https |
|----------|---------------|------------------|------------|-----------|
| Android  | App Bundle    | `.aab`           | Play Store | ✅        |
| Android  | Package       | `.apk`           | Itch.io    | ✅        |
| iOS      | App Archive   | `.ipa`           | App Store  | ️🚧        |
| Linux    | AppImage      | `.AppImage`      | Itch.io    | ✅        |
| Linux    | Tarball       | `.tar.gz`        | Steam      | ✅        |
| macOS    | App Bundle    | `.app.zip`       | Steam      | ✅        |
| macOS    | Disk Image    | `.dmg`           | Itch.io    | ✅        |
| Web      | HTML5         | `-html.zip`      | Itch.io    | ❌        |
| Windows  | Install       | `-installer.exe` | Itch.io    | ✅        |
| Windows  | SFX           | `.exe`           | Itch.io    | ✅        |
| Windows  | ZIP           | `.zip`           | Steam      | ✅        |
| LÖVE     | Game          | `.love`          | -          | ️️✔️        |

- The Store column indicates which store front the artifact is best suited for.
- The lua-https column indicates if supplemental HTTPS support is included with LÖVE 11.5 builds
  - The `.love` file includes https native libraries for supported platforms, see [**USAGE.md**](USAGE.md) for more details.

## Quick Start

- **Don't fork this repository directly!**
- [**Create a new repository from this template**](https://docs.github.com/en/repositories/creating-and-managing-repositories/creating-a-repository-from-a-template) for your game, then clone that repository.
- Open the `Workspace.code-workspace` file with [Visual Studio Code](https://code.visualstudio.com/) or [VSCodium](https://vscodium.com/)
  - You will be prompted that there are recommended extensions.
    - Click *'Install'*
- Remove our example *"game"* by:
  - Rename `game/main.template.lua` to `game/main.lua`.
  - Delete `game/eyes` directory.
- Configure [`game/product.env`](game/product.env) and [`game/conf.lua`](game/conf.lua) with the settings specific to your game.
  - Disable any platforms you do not want to target.
  - Full details on configuration can be found in the [**USAGE.md**](USAGE.md) file.
- Replace `resources/icon.png` with your game's high-resolution icon.
- If you are targeting Android, you need to create a keystore for signing your game; full details are in the [**USAGE.md**](USAGE.md) file.
- If you want to publish your game to [itch.io](https://itch.io/), you need to add [`BUTLER_API_KEY`](https://itch.io/user/settings/api-keys) to your GitHub repository; full details are in the [**USAGE.md**](USAGE.md) file.

### Running

- Press <kbd>Ctrl</kbd> + <kbd>F5</kbd> to **Run** the game.
- Press <kbd>F5</kbd> to **Debug** the game.
  - In debug mode you can use breakpoints and inspect variables.
  - This does have some performance impact though.
  - You can switch to *Release mode* in the `Run and Debug` tab (<kbd>Ctrl</kbd> + <kbd>Shift</kbd> + <kbd>D</kbd>)

### Building

Builds a date stamped `.love` file and puts it in the `builds` folder.

- Press <kbd>Ctrl</kbd> + <kbd>Shift</kbd> + <kbd>B</kbd> to **Build** the game.

### Performance Metrics

When the game is running you can access the performance metrics overlay by pressing <kbd>F3</kbd>.

#### Keyboard Controls

- <kbd>F3</kbd>: Toggle Overlay
- <kbd>F5</kbd>: Toggle VSync (only when benchmark is active)

#### Controller Controls

- Select + A: Toggle Overlay
- Select + B: Toggle VSync

#### Touch Controls

- Double Tap top right corner: Toggle Overlay
- Double Tap the overlay itself: Toggle VSync

### How to Register/Unregister Particle Systems for performance metrics

#### Basic Usage

```lua
-- When creating a particle system
local particleSystem = love.graphics.newParticleSystem(imageData)
overlayStats.registerParticleSystem(particleSystem)

-- Later, when you no longer need the particle system
overlayStats.unregisterParticleSystem(particleSystem)
```

#### Implementation Details

- **Where to register**: After creating any particle system you want tracked in your stats overlay
- **When to register**: Immediately after creating the particle system, typically in your load/initialization code
- **When to unregister**: When destroying the particle system or when it's no longer relevant to track
- **Implementation note**: Only active particle systems (`particleSystem:isActive()`) are counted

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


### Credits

The sample "game" included in this template uses the following assets:
- [Aargh! (male screams)](https://opengameart.org/content/aargh-male-screams)
- [Eyeballs](https://opengameart.org/content/eyeballs)
- [Fireplace Sound Loop](https://opengameart.org/content/fireplace-sound-loop)
- [Parallax Backgrounds](https://opengameart.org/content/3-parallax-backgrounds)
