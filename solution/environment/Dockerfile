FROM node:20-bookworm-slim

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

WORKDIR /workspace

RUN apt-get update \
  && apt-get install -y --no-install-recommends python3 python3-pip \
  && ln -sf /usr/bin/python3 /usr/local/bin/python \
  && python3 -m pip install --break-system-packages --no-cache-dir pytest==8.3.4 \
  && npm install -g typescript@5.5.4 \
  && rm -rf /var/lib/apt/lists/*

CMD ["/bin/bash"]
