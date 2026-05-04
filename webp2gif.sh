#!/bin/bash
mkdir -p gifs
for f in *.webp; do
  base="${f%.webp}"
  ffmpeg -y -i "$f" \
    -filter_complex "[0:v]split[a][b];[a]palettegen=stats_mode=full[pal];[b][pal]paletteuse=dither=bayer:bayer_scale=5:new=1" \
    -vsync 0 -gifflags +transdiff \
    "gifs/${base}.gif"
done

