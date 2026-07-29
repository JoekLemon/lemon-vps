FROM alpine:latest
RUN apk add --no-cache ffmpeg
COPY stream.sh /stream.sh
RUN chmod +x /stream.sh
ENTRYPOINT ["/stream.sh"]