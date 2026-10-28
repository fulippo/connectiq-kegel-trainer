# Kegel Trainer Project

## Project Goals
A Garmin Connect IQ app that runs a strict interval timer for Kegel exercises.
- **Protocol:** Configurable repetitions and series.
- **Intervals:** Configurable contract and relax durations.
- **Target Devices:** 100+ Garmin devices (Fenix, Forerunner, Venu, Vivoactive, Instinct, Epix, MARQ series).

## Critical Rules
- **Monkey C Syntax:** Use strict type checking.
- **Memory:** Stay under 64KB. Use local variables over globals.
- **Vibration:** Triggers a short pulse at the start of Contract and Relax phases, and a longer pattern on completion.
- **UI:** Arc progress indicator with color coding (Red for Contract, Green for Relax).
- **Activity Recording:** Uses ActivityRecording API to keep display active and save workouts to Garmin Connect.

## State Machine Logic

The app uses these states (defined in `KegelTrainerView.mc`):
1. `STATE_READY`: Waiting for user to press Start.
2. `STATE_COUNTDOWN`: 3-second "GET READY" countdown before first exercise.
3. `STATE_CONTRACT`: Contraction phase (configurable duration).
4. `STATE_RELAX`: Rest phase (configurable duration).
5. `STATE_COMPLETE`: Shows completion screen, activity saved to Garmin Connect.

## Project Structure
```
source/
  KegelTrainerApp.mc      # Main application entry point
  KegelTrainerView.mc     # UI rendering and timer logic
  KegelTrainerDelegate.mc # Input handling
resources/
  strings/strings.xml     # Default strings (English)
  settings/
    properties.xml        # Default settings values
    settings.xml          # Settings UI configuration
resources-{lang}/
  strings/strings.xml     # Localized strings (18 languages)
```

## User Settings
Configurable via Garmin Connect app:
- **Reps per series:** 1-50 (default: 10)
- **Number of series:** 1-10 (default: 1)
- **Contract time:** 1-60 seconds (default: 10)
- **Relax time:** 1-60 seconds (default: 5)

## Supported Languages
ces, dan, deu, eng, fin, fra, ita, jpn, kor, nld, nor, pol, por, rus, spa, swe, zhs, zht

## Common Commands
Using Makefile:
- **Build:** `make build`
- **Build & Run:** `make run`
- **Start Simulator:** `make simulator`
- **Release Build:** `make release`
- **Clean:** `make clean`
- **Help:** `make help`

Manual commands:
- **Build:** `monkeyc -f monkey.jungle -d fenix7 -o bin/kegel.prg -y developer_key.der`
- **Run Simulator:** `connectiq`
- **Execute App:** `monkeydo bin/kegel.prg fenix7`

## Screenshot mode (store captures)
`source/ShotMode.mc` holds a stub in the shipping build; `monkey-shot.jungle` swaps in the real thing (the annotations `shotmode`/`noshot`). `tools/shot_build.sh DEVICE OUT.prg SCREEN [STATE] [REMAINING] [REP] [SERIES]` builds an English, frozen screen (no timer, no recording): screens ready, exercise, complete. Capture it with the plugin's `sim_shot.sh` (SIM_PRG=...). Never ship these builds.

## Permissions
- **Fit:** Required for ActivityRecording API (saves workouts to Garmin Connect)

## Current Progress
- [x] Initial project structure created
- [x] State machine implementation
- [x] Timer logic with 1-second tick
- [x] UI layout for round screens with arc progress
- [x] Vibration feedback on state transitions
- [x] Multi-language support (18 languages)
- [x] Completion screen
- [x] Activity Recording (workouts saved to Garmin Connect)
- [x] User settings (configurable reps, series, durations)
- [x] Initial 3-second countdown ("GET READY")
- [x] Series support with progress display

## Garmin SDK Context
- **Documentation Source:** Use the `context7` tool with the library ID: `/websites/developer_garmin_connect-iq`
- **Rule:** Before implementing complex UI components or sensor logic, use `context7` to verify the latest Monkey C API syntax for that specific Garmin SDK version.
- **Reference URL:** https://context7.com/websites/developer_garmin_connect-iq

## Git Conventions

### Workflow
- **Never push directly to main.** Always create a branch and open a PR.
- Use `gh` CLI with the `fulippo` GitHub account.
- Do not add `Co-Authored-By` signatures to commits.

### Commit Messages
This project uses [Conventional Commits](https://www.conventionalcommits.org/). Format:

```
<type>(<scope>): <description>

[optional body]
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, no logic change)
- `refactor`: Code refactoring
- `perf`: Performance improvements
- `test`: Adding or updating tests
- `build`: Build system or dependencies
- `ci`: CI/CD configuration
- `chore`: Other changes (e.g., updating .gitignore)

**Examples:**
```
feat(ui): add arc progress indicator for exercise phases
fix(timer): correct countdown logic for series transitions
docs: update README with build instructions
ci: add GitHub Actions workflow for release automation
```

### Branch Naming
Use descriptive branch names: `feat/feature-name`, `fix/bug-description`, `chore/task-name`

## License
This project is licensed under the Apache License 2.0, which is compatible with Garmin's Connect IQ terms and matches the license used by Garmin's own open-source Connect IQ apps.
