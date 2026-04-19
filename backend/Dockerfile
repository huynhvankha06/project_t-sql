FROM node:18
WORKDIR /app
# Thêm dấu hoa thị để copy cả package-lock.json nếu có
COPY package*.json ./
RUN npm install
COPY . .
EXPOSE 5000
CMD ["node", "server.js"]