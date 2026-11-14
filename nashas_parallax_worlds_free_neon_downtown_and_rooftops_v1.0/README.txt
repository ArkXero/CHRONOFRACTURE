NASHA'S PARALLAX WORLDS: FREE NEON DOWNTOWN & ROOFTOPS
======================================================

Hi, and welcome! This pack is free.

Inside you'll find 2 cyberpunk pixel art parallax backgrounds for side
scrolling games, each split into 5 seamless, looping layers:

  neon_downtown   a moonlit neon city street: giant megatowers, towers
                  with glowing billboards, an elevated monorail, food
                  stalls, vending machines, a bus stop, street lamps
                  and a wet kerb with traffic cones
  neon_rooftops   the rooftops of a neon city under low amber clouds:
                  a far skyline with blinking antennas, water tanks,
                  billboards, a satellite dish, a radio mast, a stair
                  hut and a wet roof edge with a metal railing

The neon is cyan, red and amber. Nothing in the pack carries letters
or numbers (every sign and billboard is blank), so it fits a game in
any language.


WHERE THINGS ARE
----------------

neon_downtown/ and neon_rooftops/ each hold two folders with the
same 5 layers:

  320x180/      the native size: every layer is 180 pixels tall
  640x360/      the same layers scaled 2x (nearest neighbour), ready
                for a 640x360 screen

A layer is as wide as its loop. Some are wider than 320 pixels (up to
about 620), so the repeat is harder to spot. Place copies side by side
and they join without a seam.


THE LAYERS (back to front)
--------------------------

Every place uses the same 5 file names (the same as in the other
Parallax Worlds packs), so you can swap one world for another without
touching your code:

  file                     what it is                 suggested speed
  layer_1_sky.png          night sky / cloudy sky     0.1
  layer_2_mountains.png    far city skyline           0.25
  layer_3_hills.png        towers / rooftops          0.5
  layer_4_forest.png       street / roof structures   1.0
  layer_5_foreground.png   wet kerb / roof edge       1.6

The sky layer is fully opaque. Every other layer has a transparent
background, so you can stack them in this order and draw your level
between any two of them.

Speed is how fast a layer moves compared to the camera. 1.0 moves with
the camera (the ground your player walks on usually sits here),
smaller numbers move slower and feel further away, and the foreground
moves faster than the camera. These are only suggestions - try other
values and see what feels right for your game.


USING THE LAYERS
----------------

For each layer, every frame:

  offset = (camera_x * speed) mod layer_width
  draw the layer at x = -offset, then again at x = -offset + width,
  and so on until the screen is covered

Most engines do this for you:

  Godot       ParallaxBackground + ParallaxLayer: set motion_scale.x to
              the speed and motion_mirroring.x to the layer width
              (Godot 4.3+: Parallax2D with scroll_scale and
              repeat_size)
  Unity       a tiled SpriteRenderer (Draw Mode: Tiled) per layer,
              moved by the camera position times the speed
  GameMaker   a background layer per sprite, with Horizontal Tile on and
              its x moved by camera x times the speed

Scale by whole numbers - 2x, 3x, 4x - and turn off smoothing so the
pixels stay crisp:

  Godot       set the texture Filter to Off (or Nearest)
  Unity       Filter Mode: Point, Compression: None
  GameMaker   untick "Interpolate colours between pixels"

The layers are 180 pixels tall to match a 320x180 screen. For a
1280x720 or 1920x1080 game, use the 320x180 files at 4x or 6x.


WANT MORE WORLDS?
-----------------

Nasha's Parallax Worlds has 8 more scenes in the same style, from a
snowy valley and a volcano to sky islands and a mushroom cave. For
Halloween, Nasha's Parallax Worlds: Haunted Nights has 8 spooky ones.
Making a top-down cyberpunk game? Nasha's Neon City has thousands of
neon city sprites. You can find them all on my itch.io page.


USING THE PACK
--------------

You're welcome to use these backgrounds in your free and commercial
games and projects, and to edit, recolour and mix them however you
like.

Please don't resell or share the backgrounds themselves (as they are
or modified), and don't use them to train AI models. The full terms are
in LICENSE.txt.


Have fun building your city!
- Nasha
