FROM eclipse-temurin:17-jdk-alpine

WORKDIR /app

RUN apk add --no-cache python3 nodejs npm

COPY package.json ./
RUN npm install --production

COPY index.js ./

ENV MEMORY_LIMIT_MB=128
EXPOSE 4001

CMD ["node", "index.js"]
