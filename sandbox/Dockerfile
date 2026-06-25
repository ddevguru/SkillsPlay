FROM node:22-alpine

WORKDIR /app

RUN apk add --no-cache python3

COPY package.json ./
RUN npm install --production

COPY index.js ./

EXPOSE 4001

CMD ["node", "index.js"]
