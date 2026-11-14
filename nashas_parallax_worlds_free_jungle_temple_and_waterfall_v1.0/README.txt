NASHA'S PARALLAX WORLDS: FREE JUNGLE TEMPLE & WATERFALL
=======================================================

Hi, and welcome! This pack is free.

Inside you'll find 2 jungle pixel art parallax backgrounds for side
scrolling games, each split into 5 seamless, looping layers:

  jungle_temple     a sunny jungle temple: steep green mountains, a
                    mossy stepped stone temple with pillars and an
                    archway, big leaves, vines and fallen carved stones
  jungle_waterfall  a jungle waterfall in the morning: tall cliffs, a
                    big white waterfall into a blue pool, a wooden
                    bridge, big leaves, mossy boulders and orange
                    flowers

Deep jungle greens, mossy stone, misty blue and warm sunlight. Nothing
in the pack carries letters or numbers (every sign and board is blank),
so it fits a game in any language.


WHERE THINGS ARE
----------------

jungle_temple/ and jungle_waterfall/ each hold two folders with the same
5 layers:

  320x180/      the native size: every layer is 180 pixels tall
  640x360/      the same layers scaled 2x (nearest neighbour), ready
                for a 640x360 screen

A layer is as wide as its loop. Some are wider than 320 pixels (up to
about 670), so the repeat is harder to spot. Place copies side by side
and they join without a seam.


THE LAYERS (back to front)
--------------------------

Every place uses the same 5 file names (the same as in the other
Parallax Worlds packs), so you can swap one world for another without
touching your code:

  file                     what it is                 suggested speed
  layer_1_sky.png          warm jungle sky            0.1
  layer_2_mountains.png    far jungle mountains       0.25
  layer_3_hills.png        temple / waterfall         0.5
  layer_4_forest.png       vines and big leaves       1.0
  layer_5_foreground.png   ferns and roots            1.6

The sky layer is fully opaque. Every other layer has a transparent
background, so you can stack them in this order and draw your level
between any two of them.

Speed is how fast a layer moves compared to the camera. 1.0 moves with
the camera (the ground your player walks on usually sits here),
smaller numbers move slower and feel further away, and the foreground
moves faster than the camera. These are only suggestions - try other
values and see what feels right for your game.


ANIMATED WATERFALL
------------------

jungle_waterfall/ also has an animated_waterfall/ folder in both sizes:
layer_3_hills_1.png to layer_3_hills_9.png are the same layer with the
waterfall flowing. Use them in place of layer_3_hills.png, looping at
about 12 frames per second. Only the water changes; the rest of the
layer and its size stay the same, so the scrolling works exactly as
before.


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
snowy valley and a volcano to sky islands and a mushroom cave. Building
a platformer? Nasha's Platformer Props has free side-view props like
crates, chests, coins and potions in a matching pixel art style. You can
find them all on my itch.io page.


USING THE PACK
--------------

You're welcome to use these backgrounds in your free and commercial
games and projects, and to edit, recolour and mix them however you
like.

Please don't resell or share the backgrounds themselves (as they are
or modified), and don't use them to train AI models. The full terms are
in LICENSE.txt.


Have fun exploring the jungle!
- Nasha
