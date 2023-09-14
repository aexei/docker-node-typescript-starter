# Build Stage 1
# This build created a staging docker image
#
FROM node:18-alpine AS build

RUN apk update && apk add -y --quiet --no-interactive dumb-init

WORKDIR /usr/src/app

COPY package.json ./
COPY package-lock.json ./
COPY tsconfig.json ./

RUN --mount=type=secret,mode=0644,id=npmrc,target=/usr/src/app/.npmrc npm ci

COPY ./src ./src

RUN npm run build

# Build Stage 2
# This build takes the production build from staging build
#
FROM node:18-alpine

COPY --from=build /usr/bin/dumb-init /usr/bin/dumb-init

USER node

WORKDIR /usr/src/app

COPY --chown=node:node --from=build /usr/src/app/package.json ./
COPY --chown=node:node --from=build /usr/src/app/package-lock.json ./

RUN --mount=type=secret,mode=0644,id=npmrc,target=/usr/src/app/.npmrc npm ci --only=production

COPY --chown=node:node --from=build /usr/src/app/dist ./dist

CMD ["dumb-init", "node", "dist/main.js"]
