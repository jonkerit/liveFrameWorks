#!/bin/bash

## brew install ffmpeg
# ffmpeg -i 1024.png -vf scale=180:-1 iPhone-60-3x.png

ffmpeg -i 1024.png -vf scale=20:-1   iPad-20-1x.png
ffmpeg -i 1024.png -vf scale=40:-1   iPad-20-2x.png
ffmpeg -i 1024.png -vf scale=29:-1   iPad-29-1x.png
ffmpeg -i 1024.png -vf scale=58:-1   iPad-29-2x.png
ffmpeg -i 1024.png -vf scale=40:-1   iPad-40-1x.png
ffmpeg -i 1024.png -vf scale=80:-1   iPad-40-2x.png
ffmpeg -i 1024.png -vf scale=76:-1   iPad-76-1x.png
ffmpeg -i 1024.png -vf scale=152:-1  iPad-76-2x.png
ffmpeg -i 1024.png -vf scale=167:-1  iPad-83.5-2x.png
ffmpeg -i 1024.png -vf scale=40:-1   iPhone-20-2x.png
ffmpeg -i 1024.png -vf scale=60:-1   iPhone-20-3x.png
ffmpeg -i 1024.png -vf scale=58:-1   iPhone-29-2x.png
ffmpeg -i 1024.png -vf scale=87:-1   iPhone-29-3x.png
ffmpeg -i 1024.png -vf scale=80:-1   iPhone-40-2x.png
ffmpeg -i 1024.png -vf scale=120:-1  iPhone-40-3x.png
ffmpeg -i 1024.png -vf scale=120:-1  iPhone-60-2x.png
ffmpeg -i 1024.png -vf scale=180:-1  iPhone-60-3x.png
