FROM ghcr.io/engigu/baihu:1.1.3

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

# 克隆 GitHub 仓库到镜像中
RUN git clone https://github.com/evenluyy/bilio.git /app/bilio

# 复制恢复脚本
COPY ./restore.sh /
RUN chmod +x /restore.sh

# 修改启动脚本：删除原来的 baihu server 启动命令，添加恢复脚本
RUN sed -i '/^exec baihu server$/d' /app/docker-entrypoint.sh
RUN echo "" >> /app/docker-entrypoint.sh
RUN echo "# 执行恢复脚本" >> /app/docker-entrypoint.sh
RUN echo "if [ -f /restore.sh ]; then" >> /app/docker-entrypoint.sh
RUN echo "    /restore.sh" >> /app/docker-entrypoint.sh
RUN echo "fi" >> /app/docker-entrypoint.sh

# 设置 Python 和 Node 环境
RUN mise exec python@3.13.12 -- pip install requests
RUN mise use -g python@3.13.12
RUN mise use -g node@23.11.1

# 设置工作目录
WORKDIR /app

# 暴露端口（如果 baihu 需要）
EXPOSE 8052
