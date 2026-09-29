# TechGolf - Golf GPS Rangefinder, Scorecard & Community Platform

Dự án ứng dụng Golf toàn diện tương tự Hole19, bao gồm GPS Rangefinder, Interactive Flyover Map, Digital Scorecard, Shot Tracking, WHS Handicap, Caddie Insights, và Golf Community.

---

## 1. Yêu cầu hệ thống (Prerequisites)

* **Node.js**: >= 20.x (Khuyên dùng v22.x)
* **npm**: >= 10.x
* **Docker & Docker Compose**: Để chạy PostgreSQL 16 (PostGIS) và Redis 7 *(Lưu ý: Nếu Docker Desktop chưa cài đặt trên máy host, cần cài đặt Docker Desktop để khởi chạy container)*.

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

3. **Chạy Migrations**:
```bash
# Thực thi toàn bộ Migration Phase 1 và Phase 2 (Course Database & PostGIS)
npm run migration:run
```

4. **Seed dữ liệu phát triển**:
```bash
# Seed tài khoản người dùng mẫu
npm run seed

# Seed dữ liệu sân golf demo (9 hố, Tees, Green F/M/B, Polygons Fairway/Rough/Green/Bunker/Water)
npm run seed:courses
```
*Tài khoản thử nghiệm sau khi seed:*
* **Admin**: `admin@techgolf.com` / `AdminPassword123!` (Toàn quyền quản trị GIS Mapping)
* **Golfer**: `dev@techgolf.com` / `Password123!` (Người chơi thông thường)

5. **Khởi chạy Backend API**:
```bash
# Chế độ phát triển (Hot reload)
npm run start:dev

# Chế độ Production
npm run build
npm run start:prod
```

Hệ thống backend sẽ chạy tại:
* **API Base URL**: `http://localhost:3000/api/v1`
* **Swagger OpenAPI Docs**: `http://localhost:3000/api/docs`
* **Health Check**: `http://localhost:3000/api/v1/health`

---

## 4. Khởi chạy Web Admin Tool (GIS & Course Mapping Tool)

1. Di chuyển vào thư mục admin và cài đặt dependencies:
```bash
cd admin
npm install
```

2. Khởi chạy Web Admin ở chế độ phát triển:
```bash
npm run dev
```

* **Admin Web URL**: `http://localhost:5173`
* Tích hợp sẵn:
  * Quản lý danh sách sân golf (Tìm kiếm, Thêm, Sửa, Xóa).
  * Điều hướng hố golf (Hole 1 - 18, Par, Stroke Index).
  * **Interactive GIS Canvas**: Ảnh vệ tinh độ phân giải cao (ESRI World Imagery), vẽ vector Fairway, Green, Bunker, Water Hazard, Rough, và đặt các điểm ghim cờ Green (F/M/B), ghim vị trí Tee Markers.

---

## 5. Kiểm thử tự động (Automated Testing) & Linting

```bash
# Backend Test Suites (53 tests pass)
cd backend
npm test

# Backend Lint & Build
npm run lint
npm run build

# Admin Web Build
cd ../admin
npm run build
```

---

## 6. Cấu trúc API Endpoints (Phase 1 & Phase 2)

### Authentication & Users
* `POST /api/v1/auth/register` — Đăng ký tài khoản
* `POST /api/v1/auth/login` — Đăng nhập và nhận JWT
* `GET  /api/v1/auth/me` — Lấy thông tin tài khoản hiện tại
* `GET  /api/v1/users/me` — Lấy hồ sơ cá nhân
* `PATCH /api/v1/users/me` — Cập nhật hồ sơ cá nhân

### Virtual Golf Bag
* `GET    /api/v1/bag/clubs` — Lấy danh sách gậy trong túi
* `POST   /api/v1/bag/clubs` — Thêm gậy mới vào túi
* `PUT    /api/v1/bag/clubs/:id` — Cập nhật thông số gậy
* `DELETE /api/v1/bag/clubs/:id` — Xóa gậy khỏi túi

### Courses & GIS Database (Phase 2)
* `GET    /api/v1/courses` — Tìm kiếm và liệt kê sân golf
* `GET    /api/v1/courses/:id` — Chi tiết sân golf kèm hố và tees
* `POST   /api/v1/courses` — [Admin] Tạo sân golf mới kèm tọa độ không gian
* `PATCH  /api/v1/courses/:id` — [Admin] Cập nhật thông tin sân golf
* `DELETE /api/v1/courses/:id` — [Admin] Xóa sân golf

### Holes & Mapping Data
* `GET    /api/v1/courses/:courseId/holes` — Danh sách các hố của sân
* `POST   /api/v1/courses/:courseId/holes` — [Admin] Thêm hố vào sân (Par, Stroke Index)
* `GET    /api/v1/holes/:id` — Chi tiết hố golf
* `PATCH  /api/v1/holes/:id` — [Admin] Cập nhật thông số hố & tọa độ Green F/M/B
* `DELETE /api/v1/holes/:id` — [Admin] Xóa hố
* `GET    /api/v1/holes/:id/map` — **GeoJSON FeatureCollection** của hố (Green F/M/B, Tee Markers, Vector Polygons) phục vụ render bản đồ Mobile & Admin

### Course Tees & Markers
* `GET    /api/v1/courses/:courseId/tees` — Danh sách các Tee của sân (Red, White, Blue, Black...)
* `POST   /api/v1/courses/:courseId/tees` — [Admin] Thêm loại Tee kèm Course Rating và Slope Rating
* `PATCH  /api/v1/course-tees/:id` — [Admin] Sửa thông số Tee
* `DELETE /api/v1/course-tees/:id` — [Admin] Xóa loại Tee
* `GET    /api/v1/holes/:holeId/tees` — Danh sách ghim Tee trên hố
* `POST   /api/v1/holes/:holeId/tees` — [Admin] Đặt/Cập nhật tọa độ ghim Tee trên hố
* `DELETE /api/v1/hole-tees/:id` — [Admin] Gỡ ghim Tee trên hố

### Vector Polygons (Course Mapping Tool)
* `GET    /api/v1/holes/:holeId/polygons` — Danh sách polygon của hố
* `POST   /api/v1/holes/:holeId/polygons` — [Admin] Lưu polygon vector (Fairway, Green, Bunker, Water Hazard, Rough, Tee)
* `PATCH  /api/v1/polygons/:id` — [Admin] Sửa tọa độ polygon
* `DELETE /api/v1/polygons/:id` — [Admin] Xóa polygon

### Course Bundles (Phase 3 Offline Engine)
* `GET    /api/v1/courses/:id/bundle` — Tải toàn bộ course metadata, holes, tees, green F/M/B, và GeoJSON polygons gói trọn trong 1 request phục vụ offline play.

---

## 7. Khởi chạy Ứng dụng Mobile (Phase 3 - Flutter App)

TechGolf Mobile được xây dựng bằng Flutter/Dart tại thư mục `mobile/`:

```bash
cd mobile

# Cài đặt dependencies
flutter pub get

# Kiểm tra phân tích tĩnh code (0 issues)
flutter analyze

# Chạy toàn bộ 20 unit tests tự động
flutter test

# Khởi chạy trên thiết bị / emulator / desktop
flutter run
```

### Các tính năng cốt lõi đã hoàn thành:
1. **WGS84 Geodesic Distance Engine**: Tính khoảng cách trắc địa bằng công thức Haversine hình cầu WGS84, chuyển đổi m <-> yd chính xác.
2. **F/M/B Distance Dashboard**: Màn hình HUD độ tương phản cao ngoài trời, số to rõ ràng cho người chơi dưới ánh nắng gắt, cập nhật khoảng cách thực tế đến Front, Center, Back Green.
3. **Interactive Map & ESRI World Imagery Satellite**: Hiển thị lớp bản đồ vệ tinh độ phân giải cao kết hợp vector polygon màu chuẩn (Green, Fairway, Tee box, Bunker, Water hazard, Rough).
4. **Target / Layup Dragging**: Ghim mục tiêu kéo thả linh hoạt trên màn hình, tính toán song song 2 khoảng cách (Player -> Target và Target -> Green).
5. **Distance Arcs (Hole19 Signature)**: Các cung tròn khoảng cách 150yd (137.16m), 200yd (182.88m), 250yd (228.6m) đồng tâm quanh vị trí người chơi.
6. **Auto-Hole Geofencing**: Bộ máy trạng thái phát hiện rời green hiện tại (`Green Exit` > 35m) và tiến vào tee box hố kế tiếp (`Next Tee Entry` < 30m) có lọc nhiễu GPS jitter (> 15m) và debounce 2 chu kỳ.
7. **Offline Course Data Bundle**: Tải và lưu trữ trọn gói sân golf vào local cache, tự động phát hiện offline để tiếp tục vòng golf không gián đoạn.
8. **1-18 Hole Navigation**: Chuyển hố thủ công và bảng chọn lưới 18 hố trực quan.
