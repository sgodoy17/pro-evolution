FROM node:18-alpine As development
WORKDIR /usr/src/app
COPY package*.json ./
COPY .npmrc .
RUN apk --no-cache add curl
RUN npm install
COPY . .
RUN npm run build
FROM node:18-alpine As production
WORKDIR /usr/src/app
COPY package*.json ./
COPY .npmrc .
RUN apk --no-cache add curl
RUN npm ci --only=production
COPY . .
COPY --from=development /usr/src/app/dist ./dist
CMD [ "node", "dist/main.js", "npm", "run", "start:prod" ]
