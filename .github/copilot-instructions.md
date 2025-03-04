<!--
  Custom instructions for GitHub Copilot when working with this LÖVE 2D project
-->
# Instructions
During your interaction with the user, if you find anything reusable in this project (e.g. version of a library, model name), especially about a fix to a mistake you made or a correction you received, you should take note in the Lessons section in the .github/copilot-instructions.md file so you will not make the same mistake again.

You should also use the .github/copilot-instructions.md file's "scratchpad" section as a Scratchpad to organize your thoughts. Especially when you receive a new task, you should first review the content of the Scratchpad, clear old different task if necessary, first explain the task, and plan the steps you need to take to complete the task. You can use todo markers to indicate the progress, e.g. [X] Task 1 [ ] Task 2

Also update the progress of the task in the Scratchpad when you finish a subtask. Especially when you finished a milestone, it will help to improve your depth of task accomplishment to use the Scratchpad to reflect and plan. The goal is to help you maintain a big picture as well as the progress of the task. Always refer to the Scratchpad when you plan the next step.

This is a LÖVE 2D project that uses LuaJIT/Lua 5.1. When providing code or suggestions, ensure compatibility with this runtime version.
Respond in a friendly, collaborative style as if we're teammates working together on this project.

## Our Lua code style follows these conventions:

- We use 2 spaces for indentation (as defined in .editorconfig)
- We prefer double quotes for strings
- Line length should not exceed 120 characters
- Function calls always use parentheses
- Space is never added after function names
- Simple statements are never collapsed

## When helping with modifications or improvements:

- Suggest changes that are minimal and incremental
- Focus on clean, elegant solutions that follow Lua and LÖVE 2D best practices
- Keep functions small, manageable and focused
- Explain the rationale behind your suggestions
- Never generate test code directly, but for significant changes, briefly summarize how tests could be added
- Use sumneko Lua type annotations

## When working with LÖVE 2D specifics:

- Use the LÖVE 2D API correctly (love.graphics, love.audio, etc.) and reference the API documentation when needed from https://love2d-community.github.io/love-api/
- Use the LÖVE ParticleSystem API for particle effects. The API docs are here https://love2d-community.github.io/love-api/#type_ParticleSystem
- Respect the LÖVE 2D game loop (load, update, draw)
- Be mindful of performance considerations in game development

## Work with our project structure:

- Keep game logic, rendering, and input handling separate
- Follow our existing patterns for state management
- Maintain our approach to resource loading and management

## When suggesting code:

- Be aware of common Lua gotchas, especially with table handling and scoping
- Use local variables appropriately to avoid global namespace pollution
- Leverage Lua's strengths like tables and first-class functions
- Be mindful of garbage collection concerns in game development

# Lessons

- Read the file before you try to edit it, so you can understand the context and the structure of the file.

# Scratchpad
