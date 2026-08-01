CREATE DATABASE IF NOT EXISTS waka_demo
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE waka_demo;

CREATE TABLE IF NOT EXISTS users (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  identifier VARCHAR(255) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  display_name VARCHAR(120),
  role ENUM('reader', 'author', 'admin') NOT NULL DEFAULT 'reader',
  account_status ENUM('active', 'locked') NOT NULL DEFAULT 'active',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS social_accounts (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT UNSIGNED NOT NULL,
  provider VARCHAR(30) NOT NULL,
  provider_user_id VARCHAR(255) NOT NULL,
  email VARCHAR(255),
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_social_accounts_user
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  UNIQUE KEY uq_social_provider_user (provider, provider_user_id),
  INDEX idx_social_accounts_user_id (user_id)
);

CREATE TABLE IF NOT EXISTS categories (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(120) NOT NULL UNIQUE,
  slug VARCHAR(140) NOT NULL UNIQUE,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS authors (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT UNSIGNED NULL UNIQUE,
  display_name VARCHAR(160) NOT NULL,
  pen_name VARCHAR(160) NOT NULL DEFAULT '',
  email VARCHAR(255) NOT NULL DEFAULT '',
  phone VARCHAR(30) NOT NULL DEFAULT '',
  bio TEXT,
  avatar_url TEXT,
  status ENUM('active', 'locked') NOT NULL DEFAULT 'active',
  lock_reason VARCHAR(500),
  approved_by BIGINT UNSIGNED NULL,
  approved_at DATETIME NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_authors_user
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
  CONSTRAINT fk_authors_approved_by
    FOREIGN KEY (approved_by) REFERENCES users(id) ON DELETE SET NULL,
  INDEX idx_authors_status (status),
  INDEX idx_authors_display_name (display_name)
);

CREATE TABLE IF NOT EXISTS author_applications (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT UNSIGNED NOT NULL UNIQUE,
  real_name VARCHAR(160) NOT NULL,
  pen_name VARCHAR(160) NOT NULL DEFAULT '',
  email VARCHAR(255) NOT NULL,
  phone VARCHAR(30) NOT NULL DEFAULT '',
  bio TEXT,
  identity_document_url TEXT,
  portfolio_url TEXT,
  status ENUM('pending', 'approved', 'rejected') NOT NULL DEFAULT 'pending',
  review_note VARCHAR(500),
  reviewed_by BIGINT UNSIGNED NULL,
  reviewed_at DATETIME NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_author_applications_user
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_author_applications_reviewed_by
    FOREIGN KEY (reviewed_by) REFERENCES users(id) ON DELETE SET NULL,
  INDEX idx_author_applications_status_created (status, created_at)
);

CREATE TABLE IF NOT EXISTS books (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  category_id BIGINT UNSIGNED,
  author_id BIGINT UNSIGNED NULL,
  title VARCHAR(255) NOT NULL,
  author VARCHAR(160) NOT NULL DEFAULT '',
  description TEXT,
  image_url TEXT,
  source_url TEXT,
  price DECIMAL(12, 2) NOT NULL DEFAULT 0,
  discount_percent TINYINT UNSIGNED NOT NULL DEFAULT 0,
  is_featured BOOLEAN NOT NULL DEFAULT FALSE,
  moderation_status ENUM('draft', 'pending', 'approved', 'rejected')
    NOT NULL DEFAULT 'approved',
  moderation_note VARCHAR(500),
  is_locked BOOLEAN NOT NULL DEFAULT FALSE,
  lock_reason VARCHAR(500),
  submitted_by BIGINT UNSIGNED NULL,
  reviewed_by BIGINT UNSIGNED NULL,
  reviewed_at DATETIME NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_books_category
    FOREIGN KEY (category_id) REFERENCES categories(id)
    ON DELETE SET NULL,
  CONSTRAINT fk_books_author
    FOREIGN KEY (author_id) REFERENCES authors(id) ON DELETE SET NULL,
  CONSTRAINT fk_books_submitted_by
    FOREIGN KEY (submitted_by) REFERENCES users(id) ON DELETE SET NULL,
  CONSTRAINT fk_books_reviewed_by
    FOREIGN KEY (reviewed_by) REFERENCES users(id) ON DELETE SET NULL,
  INDEX idx_books_category_id (category_id),
  INDEX idx_books_author_id (author_id),
  INDEX idx_books_moderation_locked (moderation_status, is_locked),
  INDEX idx_books_title (title)
);

CREATE TABLE IF NOT EXISTS offers (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  book_id BIGINT UNSIGNED NOT NULL,
  title VARCHAR(255) NOT NULL,
  discount_percent TINYINT UNSIGNED NOT NULL,
  starts_at DATETIME,
  ends_at DATETIME,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_offers_book
    FOREIGN KEY (book_id) REFERENCES books(id)
    ON DELETE CASCADE,
  INDEX idx_offers_book_id (book_id),
  INDEX idx_offers_period (starts_at, ends_at)
);

CREATE TABLE IF NOT EXISTS rankings (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  book_id BIGINT UNSIGNED NOT NULL,
  period VARCHAR(20) NOT NULL DEFAULT 'week',
  content_type VARCHAR(40) NOT NULL DEFAULT 'ebook',
  rank_position INT UNSIGNED NOT NULL,
  score INT UNSIGNED NOT NULL DEFAULT 0,
  source_url TEXT,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_rankings_book
    FOREIGN KEY (book_id) REFERENCES books(id) ON DELETE CASCADE,
  UNIQUE KEY uq_rankings_period_type_position
    (period, content_type, rank_position),
  UNIQUE KEY uq_rankings_period_type_book
    (period, content_type, book_id),
  INDEX idx_rankings_book_id (book_id)
);

CREATE TABLE IF NOT EXISTS recommendations (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  book_id BIGINT UNSIGNED NOT NULL,
  content_type VARCHAR(40) NOT NULL DEFAULT 'ebook',
  position INT UNSIGNED NOT NULL,
  reason VARCHAR(255) NOT NULL DEFAULT '',
  source_url TEXT,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_recommendations_book
    FOREIGN KEY (book_id) REFERENCES books(id) ON DELETE CASCADE,
  UNIQUE KEY uq_recommendations_type_position (content_type, position),
  UNIQUE KEY uq_recommendations_type_book (content_type, book_id),
  INDEX idx_recommendations_book_id (book_id)
);

CREATE TABLE IF NOT EXISTS favorites (
  user_id BIGINT UNSIGNED NOT NULL,
  book_id BIGINT UNSIGNED NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (user_id, book_id),
  CONSTRAINT fk_favorites_user
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_favorites_book
    FOREIGN KEY (book_id) REFERENCES books(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS orders (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT UNSIGNED NOT NULL,
  order_code VARCHAR(80),
  payment_method ENUM('cod', 'bank_qr') NOT NULL DEFAULT 'cod',
  status ENUM(
    'payment_review', 'confirmed', 'packing', 'in_transit',
    'at_hub', 'out_for_delivery', 'delivered', 'cancelled'
  ) NOT NULL DEFAULT 'confirmed',
  total DECIMAL(12, 2) NOT NULL DEFAULT 0,
  shipping_recipient VARCHAR(160) NOT NULL DEFAULT '',
  shipping_phone VARCHAR(30) NOT NULL DEFAULT '',
  shipping_address TEXT,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_orders_user
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE RESTRICT,
  INDEX idx_orders_user_id (user_id),
  INDEX idx_orders_status_created (status, created_at),
  INDEX idx_orders_code (order_code)
);

CREATE TABLE IF NOT EXISTS order_items (
  order_id BIGINT UNSIGNED NOT NULL,
  book_id BIGINT UNSIGNED NOT NULL,
  quantity INT UNSIGNED NOT NULL DEFAULT 1,
  unit_price DECIMAL(12, 2) NOT NULL,
  PRIMARY KEY (order_id, book_id),
  CONSTRAINT fk_order_items_order
    FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
  CONSTRAINT fk_order_items_book
    FOREIGN KEY (book_id) REFERENCES books(id) ON DELETE RESTRICT
);

CREATE TABLE IF NOT EXISTS shipping_events (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  order_id BIGINT UNSIGNED NOT NULL,
  status VARCHAR(40) NOT NULL,
  location VARCHAR(255) NOT NULL DEFAULT '',
  description VARCHAR(500) NOT NULL DEFAULT '',
  created_by BIGINT UNSIGNED NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_shipping_events_order
    FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
  CONSTRAINT fk_shipping_events_creator
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
  INDEX idx_shipping_events_order_created (order_id, created_at)
);

CREATE TABLE IF NOT EXISTS cart_items (
  user_id BIGINT UNSIGNED NOT NULL,
  book_id BIGINT UNSIGNED NOT NULL,
  quantity INT UNSIGNED NOT NULL DEFAULT 1,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (user_id, book_id),
  CONSTRAINT fk_cart_items_user
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_cart_items_book
    FOREIGN KEY (book_id) REFERENCES books(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS membership_plans (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  code VARCHAR(40) NOT NULL UNIQUE,
  title VARCHAR(120) NOT NULL,
  description VARCHAR(255) NOT NULL DEFAULT '',
  duration_days SMALLINT UNSIGNED NOT NULL,
  price DECIMAL(12, 2) NOT NULL,
  list_price DECIMAL(12, 2) NOT NULL DEFAULT 0,
  payment_channel ENUM('card', 'sms') NOT NULL DEFAULT 'card',
  bonus_description VARCHAR(255) NOT NULL DEFAULT '',
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  sort_order SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_membership_plans_channel_active (payment_channel, is_active)
);

CREATE TABLE IF NOT EXISTS user_memberships (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT UNSIGNED NOT NULL,
  plan_id BIGINT UNSIGNED NOT NULL,
  status ENUM('active', 'expired', 'cancelled') NOT NULL DEFAULT 'active',
  started_at DATETIME NOT NULL,
  expires_at DATETIME NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_user_memberships_user
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_user_memberships_plan
    FOREIGN KEY (plan_id) REFERENCES membership_plans(id) ON DELETE RESTRICT,
  INDEX idx_user_memberships_user_status (user_id, status),
  INDEX idx_user_memberships_expires_at (expires_at)
);

CREATE TABLE IF NOT EXISTS payments (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT UNSIGNED NOT NULL,
  order_id BIGINT UNSIGNED NULL,
  membership_id BIGINT UNSIGNED NULL,
  provider VARCHAR(40) NOT NULL DEFAULT 'demo',
  transaction_ref VARCHAR(80) NOT NULL UNIQUE,
  amount DECIMAL(12, 2) NOT NULL,
  status ENUM('pending', 'proof_submitted', 'paid', 'failed', 'refunded')
    NOT NULL DEFAULT 'pending',
  paid_at DATETIME NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_payments_user
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE RESTRICT,
  CONSTRAINT fk_payments_order
    FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE SET NULL,
  CONSTRAINT fk_payments_membership
    FOREIGN KEY (membership_id) REFERENCES user_memberships(id) ON DELETE SET NULL,
  INDEX idx_payments_user_created (user_id, created_at),
  INDEX idx_payments_order_id (order_id),
  INDEX idx_payments_membership_id (membership_id)
);

INSERT INTO membership_plans
  (code, title, description, duration_days, price, list_price, payment_channel, bonus_description, sort_order)
VALUES
  ('WAKA_3_MONTHS', 'WAKA 3 THÁNG', '90 ngày đọc/nghe sách', 90, 199000, 207000, 'card', 'TIẾT KIỆM 10%', 10),
  ('WAKA_6_MONTHS', 'WAKA 6 THÁNG', '183 ngày đọc/nghe sách', 183, 399000, 414000, 'card', '', 20),
  ('WAKA_12_MONTHS', 'WAKA 12 THÁNG', '365 ngày đọc/nghe sách', 365, 499000, 828000, 'card', 'Tặng thêm 02 tháng', 30),
  ('WAKA_1_DAY_SMS', 'WAKA 1 NGÀY', 'Gia hạn sau 1 ngày', 1, 5000, 0, 'sms', 'Tặng 300MB DATA', 40),
  ('WAKA_7_DAYS_SMS', 'WAKA 7 NGÀY', 'Gia hạn sau 7 ngày', 7, 20000, 0, 'sms', 'Tặng 1GB DATA', 50)
ON DUPLICATE KEY UPDATE
  title = VALUES(title), description = VALUES(description),
  duration_days = VALUES(duration_days), price = VALUES(price),
  list_price = VALUES(list_price), payment_channel = VALUES(payment_channel),
  bonus_description = VALUES(bonus_description), sort_order = VALUES(sort_order);
