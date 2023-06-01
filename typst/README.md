# Usage

Support is pretty basic for now.

1. `nix flake new -t github:jacg/nix-starters#typst ./target-directory`
2. `cd target-directory`
3. `direnv allow` (assuming you have `direnv` installed and configured; if not, you'll need to do `nix develop`)
4. `just` (evince will open up, displaying a PDF document)
5.  Edit the document's source in `thingy.typ`. Whenever you save it, it will be refreshed in evince.

