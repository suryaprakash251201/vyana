FROM node:20-alpine

WORKDIR /app

# Copy package files
COPY package.json package-lock.json ./

# Install dependencies
RUN npm ci

# Copy source code
COPY . .

# Expose the requested port
EXPOSE 9488

# Start Vite dev server (config handled in vite.config.ts)
CMD ["npm", "run", "dev"]
