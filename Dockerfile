FROM node:20-alpine AS deps
WORKDIR /app
RUN corepack enable
COPY package.json yarn.lock ./
RUN (yarn --version >/dev/null 2>&1 || corepack prepare yarn@stable --activate) && \
    (yarn install --immutable || yarn install --frozen-lockfile)

######## build ########
FROM node:20-alpine AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
RUN yarn build

######## runtime (standalone) ########
FROM node:20-alpine AS runner
WORKDIR /app

# Нерутовый пользователь
RUN addgroup -S nodejs && adduser -S nextjs -G nodejs

# Копируем минимум для запуска standalone
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static
COPY --from=builder /app/public ./public

USER nextjs
EXPOSE 3000
CMD ["node", "server.js"]