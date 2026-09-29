# TechGolf - Golf GPS Rangefinder, Scorecard & Community Platform

Dự án ứng dụng Golf toàn diện tương tự Hole19, bao gồm GPS Rangefinder, Interactive Flyover Map, Digital Scorecard, Shot Tracking, WHS Handicap, Caddie Insights, và Golf Community.

---

## 1. Yêu cầu hệ thống (Prerequisites)

* **Node.js**: >= 20.x (Khuyên dùng v22.x)
* **npm**: >= 10.x
* **Docker & Docker Compose**: Để chạy PostgreSQL 16 (PostGIS) và Redis 7

---

## 2. Khởi chạy cơ sở dữ liệu (PostgreSQL 16 + PostGIS & Redis)

Tại thư mục gốc `E:\TechGolf`:

```bash
# Khởi chạy PostgreSQL và Redis trong nền
docker compose up -d

# Kiểm tra trạng thái containers
docker compose ps
```

Các dịch vụ sẽ mở các cổng:
* **PostgreSQL (PostGIS)**: `localhost:5432` (User: `techgolf`, Password: `techgolf_secret_password`, DB: `techgolf_db`)
* **Redis**: `localhost:6379`

---

## 3. Cài đặt và cấu hình Backend

1. Di chuyển vào thư mục backend và copy file môi trường:
```bash
cd backend
cp ../.env.example .env
```

2. Cài đặt dependencies:
```bash
npm install
```

---

## 4. Chạy Migration & Seed dữ liệu

1. **Chạy Migration**:
```bash
npm run migration:run
```

2. **Seed dữ liệu mẫu ban đầu (Test User & Golf Bag Clubs)**:
```bash
npm run seed
```
*Tài khoản thử nghiệm sau khi seed:*
* Email: `dev@techgolf.com`
* Mật khẩu: `Password123!`

---

## 5. Khởi chạy Backend API

```bash
# Chế độ phát triển (Hot reload)
npm run start:dev

# Chế độ Production
npm run build
npm run start:prod
```

Hệ thống sẽ chạy tại:
* **API Base URL**: `http://localhost:3000/api/v1`
* **Swagger OpenAPI Docs**: `http://localhost:3000/api/docs`
* **Health Check**: `http://localhost:3000/api/v1/health`

---

## 6. Kiểm thử tự động (Automated Testing) & Linting

```bash
# Chạy toàn bộ Test Suites
npm test

# Chạy Test kèm báo cáo Coverage
npm run test:cov

# Kiểm tra Lint & Code Style
npm run lint

# Build dự án
npm run build
```

---

## 7. Cấu trúc API Endpoints (Phase 1)

### Authentication
* `POST /api/v1/auth/register` — Đăng ký tài khoản golfer mới
* `POST /api/v1/auth/login` — Đăng nhập và nhận JWT access token
* `GET  /api/v1/auth/me` — Lấy thông tin tài khoản hiện tại (Yêu cầu JWT)

### User Profile
* `GET   /api/v1/users/me` — Lấy hồ sơ người dùng
* `PATCH /api/v1/users/me` — Cập nhật hồ sơ (Tên, Avatar, Handicap Index)

### Virtual Golf Bag
* `GET    /api/v1/bag/clubs` — Lấy danh sách gậy trong túi
* `POST   /api/v1/bag/clubs` — Thêm gậy mới vào túi
* `PUT    /api/v1/bag/clubs/:id` — Cập nhật thông số gậy (Chỉ chủ sở hữu)
* `DELETE /api/v1/bag/clubs/:id` — Xóa gậy khỏi túi (Chỉ chủ sở hữu)

### System Health
* `GET /api/v1/health` — Kiểm tra trạng thái Backend, PostgreSQL Database và Redis
