FROM ghcr.io/engigu/baihu:latest

ENV REMOTE_FOLDER="huggingface:/baihu"

RUN apt-get update && apt-get install -y rclone jq xvfb git
RUN rclone config -h

# 克隆 GitHub 仓库到镜像中
RUN git clone https://github.com/evenluyy/biili.git /app/biili

COPY ./restore.sh /
RUN sed -i '/^exec \.\/baihu server$/d' /app/docker-entrypoint.sh
RUN cat /restore.sh >> /app/docker-entrypoint.sh
#RUN sed -i '50r /restore.sh' /app/docker-entrypoint.sh
RUN mise exec python@3.13.12 -- pip install requests
RUN mise use -g python@3.13.12
RUN mise use -g node@23.11.1
