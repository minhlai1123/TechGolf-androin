# HƯỚNG DẪN CẤU HÌNH SUPABASE CHO TECHGOLF

Tài liệu này hướng dẫn cách thiết lập Database và dịch vụ Backend trên **Supabase** (thay thế cho NestJS).

---

## 1. Các bước thiết lập trên Supabase Dashboard

1. Đăng nhập vào [Supabase](https://supabase.com) và tạo một Project mới (ví dụ: `TechGolf`).
2. Mở mục **SQL Editor** trong thanh menu bên trái.
3. Mở file [20261025000000_techgolf_supabase_schema.sql](./migrations/20261025000000_techgolf_supabase_schema.sql), copy toàn bộ nội dung và dán vào SQL Editor -> bấm **RUN**.
   * Hệ thống sẽ tự động kích hoạt extension `postgis` và `uuid-ossp`.
   * Tạo 13 bảng: `profiles`, `golf_bag_clubs`, `courses`, `course_tees`, `holes`, `hole_tees`, `hole_polygons`, `rounds`, `round_players`, `round_scores`, `shots`, `handicap_history`, `score_differentials`.
   * Cấu hình Trigger tự động tạo 14 gậy tiêu chuẩn khi người dùng đăng ký (`auth.users`).
   * Cấu hình Row Level Security (RLS) bảo vệ dữ liệu.
   * Kích hoạt Supabase Realtime cho các bảng LivePlay (`rounds`, `round_players`, `round_scores`, `shots`).
4. Mở tiếp file [20261025000001_techgolf_seed_data.sql](./seeds/20261025000001_techgolf_seed_data.sql), copy toàn bộ nội dung và dán vào SQL Editor -> bấm **RUN**.
   * Dữ liệu sân golf mẫu **Pine Valley Championship Golf Club** (9 hố, cờ Front/Center/Back, Tee, và các đa giác Fairway, Green, Bunker, Water Hazard) sẽ được nạp sẵn.

---

## 2. Lấy thông tin kết nối cho Native Android & Native iOS

1. Vào **Project Settings** (biểu tượng bánh răng) -> chọn mục **API**.
2. Lưu lại 2 thông số:
   * **Project URL**: ví dụ `https://xyzproject.supabase.co`
   * **anon / public key**: ví dụ `eyJhbGciOiJIUzI1NiIsInR5cCI6...`

---

## 3. Kiến trúc tích hợp trong Native Apps

* **Android (Kotlin + Jetpack Compose):** Sử dụng SDK `io.github.jan-tennert.supabase:postgrest-kt`, `auth-kt`, `realtime-kt`.
* **iOS (Swift + SwiftUI):** Sử dụng Swift Package Manager `supabase-community/supabase-swift`.
* **Realtime LivePlay:** Lắng nghe kênh `realtime:public:round_scores` để cập nhật Leaderboard tức thì giữa 1–4 người chơi mà không cần WebSocket backend tùy biến.
