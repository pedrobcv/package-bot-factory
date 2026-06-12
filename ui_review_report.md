# UI Review Report — Package Bot Factory

## Overview
Reviewed 6 UI scripts (.gd) with their 6 corresponding scene files (.tscn), plus the composite scenes Main.tscn and GameWorld.tscn, and core singletons (SignalBus, GameManager, SaveManager, AudioManager, Constants, LevelManager).

---

## CRITICAL Issues

### 1. SignalBus missing 5 signals used across UI scripts
**Files:** StartMenu.gd:23,60 | LevelSelect.gd:39,130 | GameHUD.gd:121 | WinScreen.gd:36-38,161 | LoseScreen.gd:26-28,73,84 | PauseMenu.gd:46,66,81

SignalBus.gd only declares signals: `game_started, game_paused, game_resumed, level_selected, package_spawned, package_reached_bottom, tube_tapped, order_added_to_queue, order_processed, queue_cleared, package_collected, package_error, combo_updated, combo_broken, lives_changed, saturation_changed, power_up_activated, power_up_deactivated, victory, defeat, score_updated, return_to_menu, conveyor_speed_changed`

**Missing signals:**
- `change_scene(scene_path: String)` — used in StartMenu, LevelSelect, PauseMenu, WinScreen, LoseScreen
- `menu_opened(menu_name: String)` — used in StartMenu, LevelSelect
- `pause_requested()` — used in GameHUD
- `level_completed(data: Dictionary)` — used in WinScreen
- `level_failed(data: Dictionary)` — used in LoseScreen

**Severity:** CRITICAL
**Fix:** Add all 5 signals to SignalBus.gd:
```gdscript
signal change_scene(scene_path: String)
signal menu_opened(menu_name: String)
signal pause_requested()
signal level_completed(data: Dictionary)
signal level_failed(data: Dictionary)
```

---

### 2. SaveManager accesses Dictionary as Object (property syntax)
**File:** SaveManager.gd, lines 67, 109, 140, 141

```gdscript
# save_data is declared as Dictionary:
var save_data: Dictionary = { ... }

# But accessed with dot notation as if it's an object:
save_data.unlocked_levels = unlocked       # line 109 — WRITE fails!
_config_file.set_value(..., save_data.unlocked_levels)  # line 67 — READ might fail
```

In GDScript, `dict.key` read access works in Godot 4 only as syntactic sugar for `dict.get("key")`, but **`dict.key = value` assignment does NOT work on Dictionaries**. This will throw a runtime error.

**Severity:** CRITICAL
**Fix:** Replace all property-style accesses with bracket notation:
- `save_data.unlocked_levels` → `save_data["unlocked_levels"]`
- `save_data.high_scores` → `save_data["high_scores"]`
- `save_data.settings` → `save_data["settings"]`

---

### 3. GameManager references non-existent methods on UI scripts
**WinScreen.gd:41-43** calls `GameManager.get_last_level_result()` — method does not exist in GameManager.gd.
**LoseScreen.gd:31-33** calls `GameManager.get_last_fail_data()` — method does not exist in GameManager.gd.
**LevelSelect.gd:100** calls `SaveManager.get_level_score(level_num)` — method does not exist in SaveManager.gd (exists as `get_high_score`).
**StartMenu.gd:47** calls `SaveManager.get_last_unlocked_level()` — method does not exist in SaveManager.gd.
**LevelSelect.gd:81** calls `SaveManager.get_last_unlocked_level()` — method does not exist in SaveManager.gd.
**PauseMenu.gd:63** and **LoseScreen.gd:70** call `GameManager.restart_level()` — method does not exist in GameManager.gd.

**Severity:** CRITICAL
**Fix:** Either add the missing methods to the respective singletons, or use existing methods:
- `SaveManager.get_last_unlocked_level()` → `SaveManager.save_data.get("unlocked_levels", 1)` or add `func get_last_unlocked_level() -> int:` to SaveManager
- `SaveManager.get_level_score(level_num)` → `SaveManager.get_high_score(level_num)`
- `GameManager.get_last_level_result()` → add method or store result in a member variable
- `GameManager.get_last_fail_data()` → add method or store data in a member variable
- `GameManager.restart_level()` → add method (or inline the restart logic)

---

## IMPORTANT Issues

### 4. Constants.has_method("MAX_SATURATION") always returns false
**File:** GameHUD.gd:25
```gdscript
saturation_bar.max_value = Constants.MAX_SATURATION if Constants.has_method("MAX_SATURATION") else 100.0
```
`has_method` only checks for methods, not constants. This condition will always fall to `else` (100.0). The first branch `Constants.MAX_SATURATION` is never reached.

**Severity:** IMPORTANT
**Fix:** Remove the conditional; just use `Constants.MAX_SATURATION` directly since Constants is an autoload that always exists:
```gdscript
saturation_bar.max_value = Constants.MAX_SATURATION
```

### 5. Main.tscn AnimationPlayer has no "fade_in" animation
**File:** scenes/main/Main.tscn (line 87) vs scenes/ui/StartMenu.tscn (lines 103-122)

When the game starts from Main.tscn, the `StartMenu` instance is embedded directly. The AnimationPlayer node exists but has **no child animation nodes** (no "fade_in" sub-resource). The script's `_ready()` tries `animation_player.has_animation("fade_in")` which returns false, falling to the manual tween fallback — which works, but the autoplay on the AnimationPlayer may log a warning or error.

**Severity:** IMPORTANT
**Fix:** Either copy the fade_in animation sub-resource to Main.tscn's AnimationPlayer, or rely on the script's tween fallback and remove `autoplay = "fade_in"` from the standalone StartMenu.tscn.

### 6. HBoxContainer children have duplicated size values
**File:** GameHUD.tscn, lines 22-38

`LevelLabel`, `ScoreLabel`, and `LivesLabel` all have `size = Vector2(200, 50)` inside a TopBar HBoxContainer. With `alignment = 1` (center) and size_flags not set, they may overlap or not distribute properly on smaller screens.

**Severity:** IMPORTANT
**Fix:** Set `size_flags_horizontal = SIZE_EXPAND_FILL` on each label and remove manual widths, or set min sizes.

### 7. LoseScreen: missing Background overlay
**File:** LoseScreen.tscn vs PauseMenu.tscn

PauseMenu has a `Background` ColorRect with black semi-transparent overlay (`Color(0, 0, 0, 0.7)`). LoseScreen (and WinScreen) lack this overlay — the game world will be visible behind them.

**Severity:** IMPORTANT
**Fix:** Add a full-screen ColorRect background with `color = Color(0, 0, 0, 0.7)` and `mouse_filter = 2` to both LoseScreen.tscn and WinScreen.tscn.

### 8. LevelSelect: dynamic buttons created in code may conflict with static TSCN structure
**File:** LevelSelect.gd, `_build_level_buttons()` (line 42)

The script programmatically creates 10 `VBoxContainer` → `Button` + `Label` children inside `LevelGrid`. The TSCN has `LevelGrid` as an empty GridContainer with 5 columns. This works fine architecturally, but there's no visual indication that buttons are being created — debugging empty grids is hard.

**Severity:** IMPORTANT (architectural note)
**Fix:** Add a comment or fallback in case no buttons get created.

---

## MINOR Issues

### 9. Setting button text in _ready() duplicates TSCN text
**Files:** StartMenu.gd:26, PauseMenu.gd:21-23, WinScreen.gd:33, LoseScreen.gd:23

Several scripts set `.text` properties in `_ready()` that are already set in the TSCN. This is harmless but redundant code — the TSCN already defines:
- StartMenu TitleLabel: "Package Bot Factory"
- PauseMenu ContinueButton: "CONTINUAR"
- WinScreen TitleLabel: "¡NIVEL COMPLETADO!"
- LoseScreen TitleLabel: "DERROTA"

**Severity:** MINOR
**Fix:** Remove redundant assignments from _ready() (keep only those truly needed for dynamic data).

### 10. `tween.play()` is unnecessary
**Files:** StartMenu.gd:36, PauseMenu.gd:30, WinScreen.gd:50, LoseScreen.gd:40

In Godot 4, tweens auto-play after creation via `create_tween()`. Calling `.play()` is a no-op (doesn't error, but is redundant).

**Severity:** MINOR
**Fix:** Remove all `.play()` calls after `create_tween()`/`tween_property()`.

### 11. StartMenu: redundant Button.text set in TSCN (already in Spanish)
**File:** StartMenu.tscn lines 67, 84, 101

The standalone StartMenu.tscn has buttons with texts "JUGAR", "SELECCIONAR NIVEL", "SALIR", but Main.tscn has them too. Both are identical — no conflict, but duplication of scene data.

**Severity:** MINOR
**Fix:** Consider whether Main.tscn should instance StartMenu.tscn instead of duplicating its node tree.

---

## VERIFIED CORRECT

✅ All @onready node paths in scripts match their TSCN node structure:
- **StartMenu.gd**: `$TitleLabel`, `$PlayButton`, `$LevelSelectButton`, `$QuitButton`, `$AnimationPlayer` — all present in StartMenu.tscn
- **LevelSelect.gd**: `$LevelGrid`, `$BackButton` — both present in LevelSelect.tscn
- **GameHUD.gd**: `$TopBar/LevelLabel`, `$TopBar/ScoreLabel`, `$TopBar/LivesLabel`, `$ComboLabel`, `$SaturationBar`, `$PauseButton`, `$FloatingTextContainer` — all present in GameHUD.tscn
- **PauseMenu.gd**: `$Background`, `$Panel/ContinueButton`, `$Panel/RestartButton`, `$Panel/MenuButton`, `$Panel` — all present in PauseMenu.tscn
- **WinScreen.gd**: `$Panel`, `$Panel/TitleLabel`, `$Panel/ScoreLabel`, `$Panel/PackagesLabel`, `$Panel/ErrorsLabel`, `$Panel/MaxComboLabel`, `$Panel/StarsContainer`, `$Panel/NextButton`, `$Panel/MenuButton` — all present in WinScreen.tscn
- **LoseScreen.gd**: `$Panel/TitleLabel`, `$Panel/CauseLabel`, `$Panel/RetryButton`, `$Panel/MenuButton`, `$Panel` — all present in LoseScreen.tscn

✅ No `%UniqueName` syntax used anywhere in UI scripts (so no risk of missing unique name markers)

✅ Signal connections in `_ready()` match existing signals where signals exist:
- `play_button.pressed`, `pause_button.pressed`, etc. — these are built-in Button.pressed, always available

✅ AudioManager and AudioManager.play_sfx("click") — both exist (line 78 in AudioManager.gd)

✅ Scene inheritance: GameWorld.tscn has proper gameplay nodes (ConveyorBelt, PackageSpawner, etc.) with scripts attached

✅ Constants autoload exists with all referenced constants (MAX_SATURATION, MAX_LIVES, COMBO_THRESHOLDS, GameState enum)

✅ LevelManager.load_level() exists and is correctly called from GameManager.start_level()

✅ File structure: All .gd scripts referenced in .tscn files exist at their `res://` paths

---

## Summary

| Severity | Count | Key issues |
|----------|-------|-----------|
| CRITICAL | 3 | 🚨 SignalBus missing 5 signals; 🚨 SaveManager dict-as-object bug; 🚨 6 non-existent methods called on singletons |
| IMPORTANT | 4 | Constants.has_method() misused; Main.tscn missing animations; No background overlays on Win/Lose screens; HBox children sizing |
| MINOR | 3 | Redundant text overrides; Unnecessary tween.play(); Duplicated scene data |

**Total bugs found: 10**

The 3 CRITICAL bugs will cause immediate runtime errors (signal emission failures, type errors on dictionary writes, method-not-found errors). These should be fixed before any test build.
