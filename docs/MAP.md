# Reference map notes

The playable campus is an estimated reconstruction, not a measured survey.

| Video | Observed features represented |
| --- | --- |
| IMG_0038 | Upper gallery door, tiered lecture room, desks, central aisle, wooden walls, podium, display, rear windows |
| IMG_0039 | Circular upper gallery, open central void, three balcony rings above the ground floor, metal and dark glass rails, panel grid, glazed dome |
| IMG_0040–0041 | Ground-floor atrium, circular floor medallion, displays, flags, internal stairs, gallery ceilings, side passage |
| IMG_0042 | Rear corridor, yellow tactile paving, glass doors, porch columns, steps, paving, grass, low service building |
| IMG_0043–0044 | Rear lawn, side paths, broad outdoor staircase and rails, neighboring pale building |
| IMG_0045–0047 | Rounded pale facade, grey plinth, tall upper windows, external stairs, side access road and perimeter wall |
| IMG_0048–0050 | Perimeter road, yellow edge line, lamps, rounded facade and raised front entrance |
| IMG_0051–0052 | Front garden, trees, paths, fences, lamps and neighboring blocks |

The atrium uses a 32-sided circle with an 8.5 m central opening and a 12 m outer gallery radius. Storeys are approximately 4 m high; the dome reaches 20 m. These are gameplay estimates. The lecture room is placed off the highest gallery; its exact geographic orientation is unknown. Outdoor block positions and garden extents are approximate.

The back entry connects the ground floor to a courtyard. The raised front entry connects to the first gallery. Internal switchback stairs reach all three upper galleries. The lecture room has a usable central aisle. A continuous campus road joins the exterior approaches.

Smooth collision ramps sit beneath the visible stair treads so the player and bots can walk upstairs. Balcony glass panels block walking into the central void. Closed room doors and exterior-only reference buildings are intentionally solid; unfilmed interiors are not fabricated.

The navigation mesh is saved in maps/campus_navigation.tres. After changing collision geometry, run:

```bash
godot --headless --path . --script res://tools/bake_navigation.gd
```

Then run tools/check.sh and rebuild the Windows package. The bake tool bypasses the saved mesh so it always regenerates from current collision shapes. Images in docs/screenshots are rendered game captures, not frames from the user's private videos.
