#
# エンコードを行います
#
# 引数分解 後で引数パースを配列にしよう
# 引数: sambaのIP, 元ファイルパス, 出力先ファイルパス  

param($arg0,$arg1,$arg2)

cd \\$arg0\share
#HandBrakeCLI.exe -i "$arg1" -o "$arg2" -f mp4 -e x264 --x264-preset=medium --x264-tune=animation --h264-profile=high --h264-level="4.1" -q 21 -r auto --vfr -a 1 -E fdk_aac -6 auto -R auto -w 1280 -l 720 --crop 0:0:0:0 --decomb --detelecine -P;
HandBrakeCLI -i "$arg1" -o "$arg2" -f mp4 -e x264 --x264-preset slow --x264-tune animation --h264-profile=high -q 21 --cfr -r 29.97 --ab 128 --deinterlace slow