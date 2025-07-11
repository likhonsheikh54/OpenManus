#!/bin/bash

# 解决沙盒首次创建时，存在时钟不同步的问题

# 同步阈值（单位：秒）
THRESHOLD=1
# 最小运行时间（秒）
MIN_DURATION=60

START_TIME=$(date +%s)

while true; do
  phc_time=$(sudo /usr/sbin/phc_ctl /dev/ptp0 get | cut -d' ' -f5) # 获取硬件时钟的时间
  if [[ -z "$phc_time" ]]; then
    echo "错误：无法从 /dev/ptp0 获取 PHC 时间"
    exit 1
  fi

  # 获取当前系统时间（秒.纳秒）
  sys_time=$(date +%s.%N)

  # 计算时间差绝对值
  diff=$(echo "scale=3; $phc_time - $sys_time" | bc | awk '{print ($1 < 0) ? -$1 : $1}')

  # 计算脚本已运行时间
  current_time=$(date +%s)
  elapsed_time=$((current_time - START_TIME))

  # 输出当前时间差
  echo "PHC时间: $phc_time | 系统时间: $sys_time | 差值: ${diff}秒 | 已运行: ${elapsed_time}秒"

  # 时间差 ≤阈值 且 运行时间 ≥10秒：一开始可能硬件时钟和系统时钟都是旧的
  if (( $(echo "$diff <= $THRESHOLD" | bc -l) )) && (( elapsed_time >= MIN_DURATION )); then
    echo "条件满足：时间差 ≤${THRESHOLD}秒 且 已运行 ≥${MIN_DURATION}秒，停止同步"
    exit 0
  elif (( $(echo "$diff <= $THRESHOLD" | bc -l) )); then
    echo "时间差已 ≤${THRESHOLD}秒，但运行时间不足 ${MIN_DURATION}秒，继续监控..."
  fi

  # 同步时间并显示结果
  sudo date -s "@$phc_time" # 把硬件时钟同步到系统时钟
  
   # 等待 1 秒
  sleep 1
done