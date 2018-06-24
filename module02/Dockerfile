FROM alpine
RUN apk update && apk add nodejs
COPY app/ /app
WORKDIR /app
CMD ["node","index.js"]
