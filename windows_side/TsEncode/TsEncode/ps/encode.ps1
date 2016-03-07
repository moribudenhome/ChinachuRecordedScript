#
# エンコードを行います
#
# 引数分解 後で引数パースを配列にしよう
# 引数: sambaのIP, 元ファイルパス, 出力先ファイルパス  

$count = 0
foreach($x in $input)
{
  switch ($count)
  {
    0 { $arg1 = $x }
    1 { $arg2 = $x }
	2 { $arg3 = $x }
  }
  $count++
}

echo $arg1 $arg2 $arg1

cd \\$arg1\share
HandBrakeCLI.exe -i "$arg2" -o "$arg3" -f mp4 -e x264 --x264-preset=medium --x264-tune=animation --h264-profile=high --h264-level="4.1" -q 21 -r auto --vfr -a 1 -E fdk_aac -6 auto -R auto -w 1280 -l 720 --crop 0:0:0:0 --decomb --detelecine -P;



