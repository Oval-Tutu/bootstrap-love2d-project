<!--
  Custom instructions for GitHub Copilot when working with this LÖVE 2D project
-->
This is a LÖVE 2D 11.5 project that uses LuaJIT/Lua 5.1.
When providing code or suggestions, ensure compatibility with this runtime version.
Respond in a friendly, collaborative style as if we're teammates working together on this project.

Always develop an implementation plan and read the code, so you can understand the context and the structure before suggesting any code.
The implementation plan should include the following:
- A brief description of the problem you're solving
- A high-level overview of the solution
- A list of the specific steps you'll take to implement the solution

## When helping with modifications or improvements:

- Focus on clean, elegant solutions that follow Lua and LÖVE 2D best practices
- Explain the rationale behind your suggestions
- Suggest changes that are minimal and incremental
- Keep functions small, manageable and focused and do not refactor unrelated code
- Avoid code duplication and promote reusability
- Use local variables appropriately to avoid global namespace pollution
- Leverage Lua's strengths like tables and first-class functions
- Be aware of common Lua gotchas, especially with table handling and scoping
- Provide Lua type annotations
- When refactoring, opt for low risk refactors that can be easily reviewed
- Avoid introducing new dependencies unless absolutely necessary
- Never generate test code, but always summarize what tests could be added and their purpose

## When working with LÖVE 2D specifics:

- Use the LÖVE 2D API correctly (love.graphics, love.audio, etc.) and reference the API documentation when needed from https://love2d-community.github.io/love-api/
- Use the LÖVE ParticleSystem API for particle effects. The API docs are here https://love2d-community.github.io/love-api/#type_ParticleSystem
- Respect the LÖVE 2D game loop (load, update, draw)
- Shaders should always be placed in a separate .glsl file and should target WebGL 1.0 (OpenGL ES 2.0) for compatibility
- Be mindful of performance considerations and garbage collection concerns in game development

## Work with our project structure:

- Keep game logic, rendering, and input handling separate
- Follow our existing patterns for state management
- Maintain our approach to resource loading and management
- Commits messages should be clear and concise, following the conventional commits specification (https://www.conventionalcommits.org/en/v1.0.0/)

## Our Lua code style follows these conventions:

- We use 2 spaces for indentation (as defined in .editorconfig)
- We prefer double quotes for strings
- Line length should not exceed 120 characters
- Function calls always use parentheses
- Space is never added after function names
- Simple statements are never collapsed
