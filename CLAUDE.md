# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

A Lethal Company-style first-person co-op horror game, for about four players, built with Godot 4.7 (Forward+, Jolt Physics) and GDScript. Development happens on a Steam Deck, so the Deck is also a real performance target.

## Working with the user

The user is learning Godot and wants to build the game step by step:

- Do one step at a time, and explain what the code does and why.
- The user usually makes the changes themselves. Give the steps and code unless they ask you to edit the files.
- Check the actual files before giving advice, because the editor and the user change them often.
- Don't edit a `.tscn` file while it's open in the Godot editor, because saving there can overwrite the change. Ask the user to save and close the scene first.

## Commands

There are no build, lint or test tools in this project yet, and `godot` wasn't on `PATH` when this file was written. Run the game from the editor:

- **Run:** F5 runs the main scene, `main.tscn`.
- **Test multiplayer:** enable multiple instances under Debug > Customize Run Instances, then run the game.
- **Test failures too:** cover joining with no host, a second host on the same port, and the host leaving.

## Architecture

The multiplayer structure below is the agreed design. It's only partly implemented, so check the files for the current state.

**Network model:** one player hosts over ENet, and Steam lobbies through GodotSteam are planned later.

- The host owns shared game state, such as items, monsters, doors, the facility seed and the quota.
- Each client owns only its own player's movement. A player node is named after its peer ID, and its multiplayer authority is set from that name in `_enter_tree()`.
- Input, camera and movement code must check `is_multiplayer_authority()`, because every window contains every player.
- Only the host instantiates players. A `MultiplayerSpawner` copies them to clients, and a `MultiplayerSynchronizer` syncs each player's position and rotation.
- Autoloads exist on every machine and don't sync themselves, so replicated game state needs a host-owned path.

**Responsibilities:**

- `Autoloads/network.gd`: hosting, joining and connection signals. It knows nothing about players, and it should be the main file that changes for Steam.
- `Autoloads/globals.gd` (autoload `G`): values shared across systems, such as settings. Values used by one system stay with that system.
- `Player/players.gd`, on the `Players` node: creates and removes players when peers connect and disconnect.
- `main.gd`: temporary host and join keys, until there's a menu.

**Physics:** player and monster movement uses `CharacterBody3D` rather than rigid-body simulation. Physics results can differ between machines, so anything using real physics is simulated on one machine and synced. In 3D, `y` is up and `-z` is forward.

## Error handling

GDScript has no exceptions, so handle each failure by its type:

- **Immediate failure:** return an `Error`, and let the caller decide what the player sees. Include `error_string(error)` in the log.
- **Later failure:** emit a signal. `create_client()` returning `OK` only means the attempt started, so the result comes from `connected_to_server` or `connection_failed`.
- **Bug in the code:** use `assert()` or `push_error()` and fix the cause. Don't add defensive null checks that hide it. `assert()` is removed from release builds, so required code must never go inside one.
- **Requests from clients:** validate them on the host and ignore invalid ones.

Use `push_warning()` for expected failures, and `push_error()` for bugs.

## Code style

Match the existing GDScript: tabs for indentation, and explicit types on constants and variables (`const WALK_SPEED: float = 4.0`).
