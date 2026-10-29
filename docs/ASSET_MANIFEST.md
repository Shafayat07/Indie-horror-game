# Asset manifest — THE TIDE REMEMBERS

Every texture and sound in this project is **original and generated procedurally** by scripts in `tools/`.
No third-party textures, models, sounds or music are used. The only third-party assets are two fonts.

## Third-party assets

| File | Type | Source | License | Attribution | Modifications |
|---|---|---|---|---|---|
| assets/fonts/SpecialElite-Regular.ttf | Font | https://github.com/google/fonts/tree/main/apache/specialelite (Google Fonts) | Apache License 2.0 (assets/fonts/SpecialElite-LICENSE.txt) | Special Elite by Astigmatic | None |
| assets/fonts/IBMPlexMono-Regular.ttf | Font | https://github.com/google/fonts/tree/main/ofl/ibmplexmono (Google Fonts) | SIL Open Font License 1.1 (assets/fonts/IBMPlexMono-OFL.txt) | IBM Plex Mono, © 2017 IBM Corp. | None |
| Godot Engine 4.3 (runtime) | Engine | https://godotengine.org | MIT | Godot Engine contributors | None |

## Original procedural assets

Generated with Python 3 + numpy + Pillow. Re-create them at any time with:

```bash
python3 tools/gen_textures.py
python3 tools/gen_audio.py
```

License: these files were created for this project and may be used under the same terms as the project itself.

### Textures (`assets/textures/`, 512×512 tileable PBR sets: albedo, normal, roughness)

| Set | Generator function |
|---|---|
| cliff | tools/gen_textures.py |
| concrete | tools/gen_textures.py |
| grass_coastal | tools/gen_textures.py |
| gravel | tools/gen_textures.py |
| metal_green | tools/gen_textures.py |
| metal_red | tools/gen_textures.py |
| metal_rust | tools/gen_textures.py |
| plaster_white | tools/gen_textures.py |
| rock_cave | tools/gen_textures.py |
| roof | tools/gen_textures.py |
| rope | tools/gen_textures.py |
| sand_wet | tools/gen_textures.py |
| stone_wet | tools/gen_textures.py |
| wallpaper | tools/gen_textures.py |
| wood_dark | tools/gen_textures.py |
| wood_planks | tools/gen_textures.py |

### Audio (`assets/audio/`, 22.05 kHz mono WAV)

| File | Description |
|---|---|
| amb_cave.wav | ambience loop |
| amb_drone.wav | ambience loop |
| amb_generator.wav | ambience loop |
| amb_interior.wav | ambience loop |
| amb_sea.wav | ambience loop |
| amb_signal.wav | ambience loop |
| amb_static.wav | ambience loop |
| amb_tape.wav | ambience loop |
| amb_wind.wav | ambience loop |
| bell.wav | sound effect |
| bell_drowned.wav | sound effect |
| calibration_tape.wav | sound effect |
| coupling.wav | sound effect |
| death_sting.wav | sound effect |
| door_creak_0.wav | sound effect |
| door_creak_1.wav | sound effect |
| door_locked.wav | sound effect |
| door_slam.wav | sound effect |
| echo_footsteps_dock.wav | pre-echo sequence |
| echo_footsteps_stone.wav | pre-echo sequence |
| echo_footsteps_voice.wav | pre-echo sequence |
| echo_running.wav | pre-echo sequence |
| flashlight.wav | sound effect |
| flashlight_echo.wav | sound effect |
| generator_start.wav | sound effect |
| hatch_open.wav | sound effect |
| heartbeat.wav | sound effect |
| knock3.wav | sound effect |
| listener_cry.wav | The Listener |
| listener_step_0.wav | The Listener |
| listener_step_1.wav | The Listener |
| listener_step_2.wav | The Listener |
| listener_strings.wav | The Listener |
| metal_knock.wav | sound effect |
| overload.wav | sound effect |
| paper.wav | sound effect |
| pickup.wav | sound effect |
| power_down.wav | sound effect |
| radio_burst.wav | sound effect |
| radio_voice_a.wav | distorted, deliberately unintelligible formant 'voice' (subtitled) |
| radio_voice_b.wav | distorted, deliberately unintelligible formant 'voice' (subtitled) |
| radio_voice_c.wav | distorted, deliberately unintelligible formant 'voice' (subtitled) |
| radio_voice_elias.wav | distorted, deliberately unintelligible formant 'voice' (subtitled) |
| rec_button.wav | sound effect |
| relay_0.wav | relay calibration tone |
| relay_1.wav | relay calibration tone |
| relay_2.wav | relay calibration tone |
| relay_wrong.wav | relay calibration tone |
| splash.wav | sound effect |
| step_grass_0.wav | footstep |
| step_grass_1.wav | footstep |
| step_grass_2.wav | footstep |
| step_grass_3.wav | footstep |
| step_gravel_0.wav | footstep |
| step_gravel_1.wav | footstep |
| step_gravel_2.wav | footstep |
| step_gravel_3.wav | footstep |
| step_metal_0.wav | footstep |
| step_metal_1.wav | footstep |
| step_metal_2.wav | footstep |
| step_metal_3.wav | footstep |
| step_stone_0.wav | footstep |
| step_stone_1.wav | footstep |
| step_stone_2.wav | footstep |
| step_stone_3.wav | footstep |
| step_water_0.wav | footstep |
| step_water_1.wav | footstep |
| step_water_2.wav | footstep |
| step_water_3.wav | footstep |
| step_wood_0.wav | footstep |
| step_wood_1.wav | footstep |
| step_wood_2.wav | footstep |
| step_wood_3.wav | footstep |
| tape_start.wav | sound effect |
| tape_stop.wav | sound effect |
| transmit_surge.wav | sound effect |
| ui_click.wav | sound effect |
| whisper_0.wav | breathy formant whisper |
| whisper_1.wav | breathy formant whisper |

### Models

All 3D models (The Listener, field recorder, transmitter, lighthouse, boat, buildings, furniture, rocks, cave) are generated at runtime from code in `scripts/` (procedural meshes and primitives). No model files are imported.
