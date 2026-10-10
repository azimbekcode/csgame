# Reference map — circular university building

This revision follows the user's front-elevation photograph and the reuploaded
IMG_0038–IMG_0042 and IMG_0044–IMG_0047 videos. There are **four playable levels,
numbered 0, 1, 2 and 3**. The photographs show three facade bands: the tall upper
arched windows span the two upper internal levels.

The previous rectangular auditorium and stair extensions have been removed.
All classrooms, the tiered lecture room and the switchback staircase now fit
inside the round shell. Every level has five accessible rooms. The room layout
and dimensions remain estimates where the videos do not show a complete plan;
this is a reference-based game reconstruction, not a surveyed digital twin.

## Entrances and circulation

- A wide central front stair reaches level 1 through the framed front portal.
- The rear entrance has two lateral stair flights meeting at a shared level-1
  landing, as seen in IMG_0045. The door beneath the landing reaches level 0.
- The rear interior passage follows IMG_0042: pale wood panels, glass doorway,
  tactile paving and small plants. The old long projecting rectangular porch
  is removed.
- The lift is on the right when walking out through the rear passage, and on
  the left when entering. Walk into the cabin, press **E** for the next level
  or **Q** for the previous level. **E** on a landing calls the lift. Its four
  stops are 0–3; landing gates close while the cabin is away or moving.
- The internal stairs provide a continuous route for both the player and bots.
  Navigation does not depend on the moving lift.

## Visual references

IMG_0038 informs the stepped lecture-room seating. IMG_0039–0041 inform the open
central atrium, wood panel joints, polished floor medallion, dark glass balcony
rails, ceiling lights and glazed skylight. IMG_0045–0047 inform the grey plinth,
cream facade, pilasters, cornices and arched bronze-framed windows.

Trees use tapered trunks, branching twigs and individually varied leaf meshes;
foliage is instanced to limit draw calls. Soldiers use original articulated
human-shaped meshes, procedural camouflage, helmet, goggles, plate carrier,
magazine pouches, knee protection, boots and walking animation. These remain
procedural game assets, not photogrammetric humans or scanned vegetation.

The building radius is approximately 20 m, atrium opening radius 6.5 m, floors
are at 0/4/8/12 m, and the main roof is at 16 m. These are gameplay dimensions.
Original videos, private frames and the people visible in them are not shipped.

## Rebuild and validation

```bash
godot --headless --path . --script res://tools/bake_navigation.gd
bash tools/check.sh
bash tools/build_windows.sh
bash tools/build_linux.sh
```

The test suite walks every room entrance, all internal flights, front and rear
stairs, and the four-stop lift, then checks combat/economy/bomb mechanics and a
two-round bot match. Navigation is baked from collision geometry. Screenshot
capture requires a display; on Linux it can run under Xvfb:

```bash
godot --path . --audio-driver Dummy --script res://tools/capture_map.gd
```

Screenshots in `docs/screenshots` are actual game renders. Windows export is
cross-built on Linux; native Windows execution requires a Windows machine.
