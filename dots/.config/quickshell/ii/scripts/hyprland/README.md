# Hyprland Scripts

## Workspace Profile Manager

The `workspace_profile_manager` is a high-performance backend written in Rust that manages saved Hyprland workspace layouts and profiles for the Cheatsheet. It communicates with `hyprctl` to capture live clients, save them as JSON profiles, and restore them upon request.

- We ship both the source code at `~/.config/quickshell/ii/scripts/hyprland/workspace_profile_manager_src` and the compiled binary at `~/.config/quickshell/ii/scripts/hyprland/workspace_profile_manager`.

### Building from Source

If you want to build or update the binary yourself, ensure you have Rust installed (`cargo`), then run the following commands:

```bash
# Navigate to the source directory
cd ~/.config/quickshell/ii/scripts/hyprland/workspace_profile_manager_src

# Build the release binary
cargo build --release

# Replace the shipped binary with your newly compiled version
cp target/release/workspace_profile_manager ../
```

### Data Storage
Workspace profiles and snapshots are automatically saved to `~/.config/illogical-impulse/workspace_profiles/` as lightweight JSON files. You can safely back up or sync this folder between your machines.
