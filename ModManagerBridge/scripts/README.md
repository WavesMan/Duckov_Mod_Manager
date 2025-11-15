# ModManagerBridge Scripts

This directory contains test scripts for the ModManagerBridge mod.

## Available Scripts

### test_mod_manager.py
Basic tests for the mod manager WebSocket API.

## Usage

1. Make sure the game is running with the ModManagerBridge mod loaded
2. Run any of the test scripts:
   ```bash
   uv sync
   uv run test_mod_manager.py
   ```

## API Reference

The ModManagerBridge exposes a WebSocket API on port 9001 with the following actions:

- `get_mod_list` - Get a list of all installed mods with detailed information
- `activate_mod` - Activate a mod by name
- `deactivate_mod` - Deactivate a mod by name
- `rescan_mods` - Rescan the mods directory for new or updated mods

Each request should be a JSON object with `action` and `data` fields.
Each response will contain `success`, `message`, and optionally `data` fields.

## Troubleshooting

### Connection Issues
1. Ensure the game is running
2. Ensure the ModManagerBridge mod is loaded
3. Verify that port 9001 is not blocked by a firewall
4. Check for any other programs using port 9001

### Mod Not Displaying
1. Ensure the mod is correctly installed in the game's Mods directory
2. Run the `rescan_mods` command to refresh the mod list
3. Verify that the mod's info.ini file is correctly configured