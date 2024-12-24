# LÖVE Template for Visual Studio Code

A pre-configured Visual Studio Code template for LÖVE.
Adapted from <https://github.com/Keyslam/LOVE-VSCode-Game-Template>

## Features

- 🌕 Rich Lua language features with [Lua Language Server](https://github.com/LuaLS/lua-language-server)
- 🐛 Debugging with [Local Lua Debugger](https://github.com/tomblind/local-lua-debugger-vscode)
- 🩷 Intellisense for the LÖVE API via [Love2D Support](https://marketplace.visualstudio.com/items?itemName=pixelbyte-studios.pixelbyte-love2d)
- 👨‍💻 Consistent coding styles with [Editorconfig](https://github.com/editorconfig/editorconfig-vscode)
- ️⛱️ [Shader languages support](https://marketplace.visualstudio.com/items?itemName=slevesque.shader)
- ️👷 Automated builds of the `.love` file.
- 🗂️ Organized with [Workspaces](https://code.visualstudio.com/docs/editor/workspaces)
- ️❄️ Nix flake to provision a dev shell

## Prerequisites

- Visual Studio Code
- [LÖVE 11.5](https://love2d.org/)
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
    - [Shader languages support](https://marketplace.visualstudio.com/items?itemName=slevesque.shader)
- Configure the `game/conf.lua` with the settings specific for your game.
- Configure `.github/workflows/build.yml` with the settings specific for your game.
  - **Make sure that `PRODUCT_UUID` is changed using `uuidgen`.
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

## Releasing

Make a new release by creating a git tag:

- **Create a new tag**: Use the following command to create a new tag.
  - *Replace `v1.0.0` with your desired version number.*
```bash
git tag v1.0.0
```

- **Push the tag to GitHub**: Push the tag to the remote repository.
```bash
git push origin v1.0.0
```

- **GitHub Actions**: The GitHub workflow will automatically create a release and upload packages for all the supported platforms as an assets.

## Structure
```
.
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
