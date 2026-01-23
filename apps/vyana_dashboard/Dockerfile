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

# Start Vite dev server on port 9488 with explicit host binding
CMD ["npx", "vite", "--host", "0.0.0.0", "--port", "9488"]
