# Dockerfile

# Build stage
FROM node:18-alpine AS build

WORKDIR /app

COPY package*.json ./
RUN npm install
COPY . .

RUN npm run build

# Production Stage
FROM node:18-alpine

WORKDIR /app

# Install serve globally
RUN npm install -g serve

# Copy built React app
COPY --from=build /app/build ./build

EXPOSE 8080

# Serve the build directory
CMD ["serve", "-s", "build", "-l", "8080"]
