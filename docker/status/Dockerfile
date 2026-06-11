FROM python:3.12-alpine

RUN apk add --no-cache ca-certificates curl

RUN curl -#SfLo /usr/local/bin/bercon-cli \
  https://github.com/WoozyMasta/bercon-cli/releases/latest/download/bercon-cli-linux-amd64 \
  && chmod +x /usr/local/bin/bercon-cli

WORKDIR /app
COPY app.py /app/app.py

EXPOSE 8090
CMD ["python", "/app/app.py"]
