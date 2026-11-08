# ARCHIVE artwork

`source/` retains the user-supplied files byte for byte, flattened by basename, plus a separate cleaned far-background source. Its `.gdignore` excludes production sources from runtime imports. Original package documentation describes the original ZIP tree and retains its original pre-integration status.

`game/` contains the compiled runtime atlas, facades and far image. Rebuild with `tools/install_archive_art.ps1`. Fixed placements live in `data/archive_dressing.json`; geometry remains in the original level file. Current results: `docs/ARCHIVE_ART_INTEGRATION.md`.
