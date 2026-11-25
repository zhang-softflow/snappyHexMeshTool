# foamSHM — keyword reference, templates and checks for snappyHexMeshDict

English | [日本語](README.ja.md)

snappyHexMeshDict has about 190 keywords spread over geometry / castellatedMeshControls / snapControls / addLayersControls / meshQualityControls and their sub-dictionaries. Finding out *where* a keyword goes, whether it is mandatory, what its default is and which values are allowed usually means digging through the annotated dictionary, the sources and the tutorials.

**foamSHM** builds a **keyword dictionary** of snappyHexMeshDict from

- the annotated dictionary (`etc/caseDicts/annotated/snappyHexMeshDict`, including the commented-out optional entries) and `etc/caseDicts/meshQualityDict`,
- the C++ sources that read the dictionary (`get` / `getOrDefault` / `readIfPresent` / `found` ...) — mandatory/optional and defaults,
- the Enum name tables (allowed values of `mode`, `cellZoneInside`, `faceType`, `thicknessModel`, ...),
- the searchableSurface types used in `geometry` (box, cylinder, triSurfaceMesh, ...) and their header parameter tables,
- every snappyHexMeshDict in the tutorials (real usage),

and uses it to search, show, generate and check dictionaries.

Keywords are addressed by paths with placeholders for user-chosen names, e.g. `castellatedMeshControls/refinementSurfaces/<surface>/level`.

It works like its siblings [foamFO](../functionObjects) (function objects) and [foamFV](../fvOptions) (fvOptions).

| File | Content |
|---|---|
| `foamSHM` | CLI (Python 3.8+, standard library only) |
| `catalog.html` | Searchable offline reference — just open it in a browser |
| `shmDatabase.json` | Bundled database (built from OpenFOAM-v2606) |
| `catalog_template.html` | Template of the catalog |
| `skill/openfoam-snappyhexmesh/` | Claude Code skill |
| `install.sh` | Installer (skill link, PATH) |

## Install

```bash
cd snappyHexMesh
./install.sh            # link the skill into ~/.claude/skills and print the PATH line
./install.sh --bashrc   # append the PATH line to ~/.bashrc (with backup)
./install.sh --uninstall
```

For an OpenFOAM version other than v2606, build a matching database (takes about a second):

```bash
source /usr/lib/openfoam/openfoam2412/etc/bashrc
foamSHM build           # -> ~/.local/share/foamSHM/shmDatabase-openfoam2412.json
```

Lookup order: `$FOAMSHM_DB` → `~/.local/share/foamSHM/shmDatabase-<version>.json` → bundled `shmDatabase.json`. A version mismatch with the bundled database prints a warning (silence it with `FOAMSHM_QUIET=1`).

## Usage

| Command | Description |
|---|---|
| `foamSHM tree [addLayersControls] [-d] [-a]` | Dictionary structure (R mandatory, C conditional, o optional, defaults, choices; `-d` adds descriptions) |
| `foamSHM search layer thickness` | Full-text search in keywords, descriptions and synonyms (English or Japanese) |
| `foamSHM show nCellsBetweenLevels` | Location, mandatory/optional, default, choices, conditions, annotated description and example, reading source lines, tutorial values |
| `foamSHM show level` | All places where a keyword name occurs |
| `foamSHM show refinementSurfaces/motorBike/level` | Paths with real names are resolved too |
| `foamSHM show cylinder` | Parameters of a geometry type |
| `foamSHM example refinementRegions -m 2` | Real blocks from the tutorials (needs the OpenFOAM tree or `--src`) |
| `foamSHM template -case . --layers 3 --features --shape box:refineBox` | Print a ready-to-edit dictionary |
| `foamSHM template ... --write` | Write `system/snappyHexMeshDict` (existing file saved as `.bak`) |
| `foamSHM check [case]` | Check a dictionary (`--dict-only` skips case files, `-q` hides INFO) |
| `foamSHM build [--src DIR] [-o FILE] [-v]` | Build the database (`-v` lists differences between sources and annotated dictionary) |
| `foamSHM html` | Regenerate `catalog.html` |

`check` reports
- **ERROR**: missing mandatory entries (only where they are actually read, e.g. not addLayersControls when `addLayers false`), values outside the allowed choices, missing mandatory geometry parameters, `locationInMesh` outside the blockMesh bounds;
- **WARN**: unknown keywords (with "did you mean"), names that are not geometry entries (snappyHexMesh ignores them), missing surface/eMesh files, empty `layers` with `addLayers true`;
- **INFO**: keywords only seen in tutorials (no read found in the sources), unresolved `#include`.

`#include` / `#includeEtc` (with `<system>` etc.) are expanded and dictionaries merged before checking.

## Claude Code skill
`install.sh` links it as `~/.claude/skills/openfoam-snappyhexmesh`. Ask e.g. "mesh around this STL with 3 boundary layers" or "why are no layers added" — Claude looks the keywords up with foamSHM, checks the case (surfaces, blockMesh bounds, patch names), writes the dictionary and runs `foamSHM check`.

## Limitations
- ESI OpenFOAM (openfoam.com, vYYMM) only.
- Mandatory/optional is derived from how the sources read each entry; entries read conditionally are annotated by a small table in the tool.
- Contents of `*Coeffs`, `patchInfo` and `formatOptions` are passed to other classes and not checked.
- Tested: database built for v2606 (sources) and v2412 (package); `check` on all 67 tutorial dictionaries of v2606 without false errors; a generated dictionary (motorBike, `--level 4 5 --layers 3`) meshed to completion with v2412 (186k cells, 17% layer coverage, 7 highly skewed faces in checkMesh) — tune levels and layer settings to your geometry.

## License
GPL-3.0-or-later ([LICENSE](LICENSE)). The bundled database and catalog contain comment text from the OpenFOAM sources and annotated dictionaries (GPL-3.0-or-later, © OpenCFD Ltd. and others).

OPENFOAM® is a registered trade mark of OpenCFD Limited, producer and distributor of the OpenFOAM software via www.openfoam.com. This offering is not approved or endorsed by OpenCFD Limited.
