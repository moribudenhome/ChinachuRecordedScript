#!/bin/sh

# ログインアカウント ブラウザでchinachuのページを表示する時のアカウントと同一の物を指定
user=akari
passwd=bakuhatsu

# recorded objectを得る
query=`curl -s --user ${user}:${passwd} http://192.168.1.6:10772/api/recorded.json`

# logFile
time=`date +%s`
logExt=".log"

# ログファイル保存ディレクト
logFile="/mnt/hdd/log/log_"$time$logExt

ruby /home/chinachu/ChinachuRecordedScript/encode_reservation.rb "${1}" "${2}" "${query}" 2> $logFile
