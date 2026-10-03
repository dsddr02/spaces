FROM ghcr.io/engigu/baihu:latest

ENV REMOTE_FOLDER="huggingface:/baihu"

# 安装必要的工具
RUN apt-get update && apt-get install -y \
    rclone \
    jq \
    xvfb \
    git \
    unzip \
    zip \
    curl \
    && rm -rf /var/lib/apt/lists/*

RUN rclone config -h

# 复制恢复脚本
COPY ./restore.sh /
RUN chmod +x /restore.sh

# 修改启动脚本：删除原来的 baihu server 启动命令，添加恢复脚本
RUN sed -i '/^exec baihu server$/d' /app/docker-entrypoint.sh
RUN cat /restore.sh >> /app/docker-entrypoint.sh

# 设置 Python 和 Node 环境
RUN mise exec python@3.13.12 -- pip install requests
RUN mise use -g python@3.13.12
RUN mise use -g node@23.11.1

