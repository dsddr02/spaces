# 设置Playwright环境 使用chrome
# python -m pip install playwright
# python -m playwright install-deps
# python -m playwright install chrome
# 弃用Playwright改用cloakbrowser
python -m pip install cloakbrowser
python -m cloakbrowser install
python -m cloakbrowser info
python -m playwright install-deps
# 创建虚拟显示环境 如需调用export DISPLAY=:99
Xvfb :99 -screen 0 1920x1080x24 &

npm install pm2 -g
#开启白虎服务
pm2 start "./baihu server" --name baihu

echo "10秒后开始恢复任务..."
sleep 10

#从日志中获取密码
echo  "======================从日志中获取密码========================\n"
DEFAULT_PASSWORD=$(tail -n 100 ~/.pm2/logs/baihu-out.log \
    | grep -oP '密\s*码:\s*\K[^,[:space:]]+' \
    | tail -n 1)

echo  "默认用户名: admin"
#echo  "默认密码: $DEFAULT_PASSWORD"

echo "============重置密码==============="
# 获取登陆响应Token
BHToken=$(
curl -c cookies.txt -s -D - -o /dev/null \
  'http://localhost:8052/api/v1/auth/login' \
  -H 'content-type: application/json' \
  --data-raw "{\"username\":\"admin\",\"password\":\"$DEFAULT_PASSWORD\"}" \
| awk -F'[=;]' '/Set-Cookie: BHToken=/{print $2}'
)

sleep 1

RESET_RESPONSE=$(
  curl -b cookies.txt 'http://localhost:8052/api/v1/settings/password' \
  -H 'content-type: application/json' \
  --data-raw "{\"old_password\":\"$DEFAULT_PASSWORD\",\"new_password\":\"$ADMIN_PASSWORD\"}"
)

echo  "======================写入rclone配置========================\n"
mkdir -p ~/.config/rclone
echo "$RCLONE_CONF" > ~/.config/rclone/rclone.conf

if [ -n "$RCLONE_CONF" ]; then
  echo "##########同步备份############"
  rclone mkdir $REMOTE_FOLDER
  
  OUTPUT=$(rclone ls "$REMOTE_FOLDER" 2>&1)
  EXIT_CODE=$?
  
  if [ $EXIT_CODE -eq 0 ]; then
    if [ -z "$OUTPUT" ]; then
      echo "初次安装，没有备份文件"
    else
      echo "发现备份文件，开始恢复..."
      mkdir -p /app/backup_tmp
      latest_file=$(rclone lsjson $REMOTE_FOLDER | jq -r 'sort_by(.ModTime) | last | .Path')
      echo "最新备份文件: $latest_file"
      rclone copy $REMOTE_FOLDER/$latest_file /app/backup_tmp
      
      # 解压并更新scripts文件夹（保留原备份文件）
      echo "开始解压备份文件到临时目录..."
      cd /app/backup_tmp
      BACKUP_BASENAME=$(basename "$latest_file" .zip)
      unzip -o "$latest_file" -d "${BACKUP_BASENAME}_extract"
      
      echo "克隆biili仓库到scripts文件夹..."
      git clone https://github.com/evenluyy/biili.git "${BACKUP_BASENAME}_extract/scripts/biili"
      
      echo "重新打包为临时zip文件..."
      cd "${BACKUP_BASENAME}_extract"
      zip -r "../${BACKUP_BASENAME}_temp_restore.zip" .
      cd /app/backup_tmp
      
      echo "使用临时修改的备份文件进行恢复..."
      ./baihu restore "/app/backup_tmp/${BACKUP_BASENAME}_temp_restore.zip"
      
      echo "备份恢复完成，重启服务..."
      pm2 restart baihu
      
      # 清理临时文件，保留原备份文件
      cd /app
      rm -rf /app/backup_tmp
      
      echo "恢复完成！原备份文件已保留，biili仓库已临时添加到scripts文件夹用于恢复"
    fi
  elif [[ "$OUTPUT" == *"directory not found"* ]]; then
    echo "错误：文件夹不存在"
  else
    echo "错误：$OUTPUT"
  fi
else
    echo "没有检测到Rclone配置信息"
fi

echo "容器启动完成，biili 仓库位于 /app/biili"
tail -f /dev/null
