-- Magazin MVP database schema. Run once on a fresh PostgreSQL database.
CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS branches (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name varchar(160) NOT NULL,
  address text,
  phone varchar(40),
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS users (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  username varchar(100) NOT NULL UNIQUE,
  password_hash text NOT NULL,
  full_name varchar(200),
  role varchar(30) NOT NULL CHECK (role IN ('owner','manager','cashier','warehouse','accountant','auditor')),
  branch_id uuid REFERENCES branches(id) ON DELETE RESTRICT,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS products (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name varchar(200) NOT NULL,
  barcode varchar(100),
  unit varchar(20) NOT NULL DEFAULT 'dona' CHECK (unit IN ('dona','kg','g','l','ml','quti','pachka')),
  purchase_price numeric(14,2) NOT NULL CHECK (purchase_price >= 0),
  sale_price numeric(14,2) NOT NULL CHECK (sale_price >= 0),
  stock_quantity numeric(14,3) NOT NULL DEFAULT 0 CHECK (stock_quantity >= 0),
  min_stock numeric(14,3) NOT NULL DEFAULT 0 CHECK (min_stock >= 0),
  expiry_date date,
  branch_id uuid REFERENCES branches(id) ON DELETE RESTRICT,
  created_by uuid REFERENCES users(id) ON DELETE SET NULL,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX IF NOT EXISTS products_barcode_unique ON products(branch_id, barcode) WHERE barcode IS NOT NULL;
CREATE INDEX IF NOT EXISTS products_name_idx ON products USING gin (to_tsvector('simple', name));

CREATE TABLE IF NOT EXISTS suppliers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name varchar(200) NOT NULL,
  phone varchar(40),
  address text,
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS customers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name varchar(200) NOT NULL,
  phone varchar(40),
  note text,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS purchase_documents (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  supplier_id uuid REFERENCES suppliers(id) ON DELETE SET NULL,
  supplier_name varchar(200),
  total_amount numeric(14,2) NOT NULL DEFAULT 0 CHECK (total_amount >= 0),
  paid_amount numeric(14,2) NOT NULL DEFAULT 0 CHECK (paid_amount >= 0),
  status varchar(20) NOT NULL DEFAULT 'received' CHECK (status IN ('draft','received','cancelled')),
  branch_id uuid REFERENCES branches(id) ON DELETE RESTRICT,
  created_by uuid REFERENCES users(id) ON DELETE SET NULL,
  purchased_at timestamptz NOT NULL DEFAULT now(),
  note text
);
CREATE TABLE IF NOT EXISTS purchase_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  purchase_id uuid NOT NULL REFERENCES purchase_documents(id) ON DELETE RESTRICT,
  product_id uuid NOT NULL REFERENCES products(id) ON DELETE RESTRICT,
  quantity numeric(14,3) NOT NULL CHECK (quantity > 0),
  unit_cost numeric(14,2) NOT NULL CHECK (unit_cost >= 0),
  line_total numeric(14,2) GENERATED ALWAYS AS (round(quantity * unit_cost, 2)) STORED
);

CREATE TABLE IF NOT EXISTS sales (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  receipt_number bigserial UNIQUE,
  subtotal numeric(14,2) NOT NULL CHECK (subtotal >= 0),
  discount_amount numeric(14,2) NOT NULL DEFAULT 0 CHECK (discount_amount >= 0),
  total_amount numeric(14,2) NOT NULL CHECK (total_amount >= 0),
  cost_amount numeric(14,2) NOT NULL DEFAULT 0 CHECK (cost_amount >= 0),
  gross_profit numeric(14,2) NOT NULL DEFAULT 0,
  payment_method varchar(20) NOT NULL CHECK (payment_method IN ('cash','card','qr','mixed','credit')),
  status varchar(20) NOT NULL DEFAULT 'completed' CHECK (status IN ('completed','cancelled','returned')),
  branch_id uuid REFERENCES branches(id) ON DELETE RESTRICT,
  cashier_id uuid REFERENCES users(id) ON DELETE SET NULL,
  sold_at timestamptz NOT NULL DEFAULT now(),
  note text
);
CREATE INDEX IF NOT EXISTS sales_sold_at_idx ON sales(sold_at);
CREATE TABLE IF NOT EXISTS sale_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  sale_id uuid NOT NULL REFERENCES sales(id) ON DELETE RESTRICT,
  product_id uuid NOT NULL REFERENCES products(id) ON DELETE RESTRICT,
  product_name varchar(200) NOT NULL,
  quantity numeric(14,3) NOT NULL CHECK (quantity > 0),
  unit_price numeric(14,2) NOT NULL CHECK (unit_price >= 0),
  unit_cost numeric(14,2) NOT NULL CHECK (unit_cost >= 0),
  line_total numeric(14,2) NOT NULL CHECK (line_total >= 0),
  cost_total numeric(14,2) NOT NULL CHECK (cost_total >= 0),
  gross_profit numeric(14,2) NOT NULL
);

CREATE TABLE IF NOT EXISTS payments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  sale_id uuid REFERENCES sales(id) ON DELETE RESTRICT,
  method varchar(20) NOT NULL CHECK (method IN ('cash','card','qr','credit')),
  amount numeric(14,2) NOT NULL CHECK (amount >= 0),
  reference varchar(200),
  created_by uuid REFERENCES users(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS expenses (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title varchar(200) NOT NULL,
  category varchar(100) NOT NULL,
  amount numeric(14,2) NOT NULL CHECK (amount > 0),
  expense_date date NOT NULL DEFAULT CURRENT_DATE,
  note text,
  branch_id uuid REFERENCES branches(id) ON DELETE RESTRICT,
  created_by uuid REFERENCES users(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS debts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  direction varchar(20) NOT NULL CHECK (direction IN ('receivable','payable')),
  party_name varchar(200) NOT NULL,
  phone varchar(40),
  original_amount numeric(14,2) NOT NULL CHECK (original_amount > 0),
  paid_amount numeric(14,2) NOT NULL DEFAULT 0 CHECK (paid_amount >= 0),
  remaining_amount numeric(14,2) NOT NULL CHECK (remaining_amount >= 0),
  due_date date,
  note text,
  status varchar(20) NOT NULL DEFAULT 'open' CHECK (status IN ('open','paid','cancelled')),
  branch_id uuid REFERENCES branches(id) ON DELETE RESTRICT,
  created_by uuid REFERENCES users(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS debt_transactions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  debt_id uuid NOT NULL REFERENCES debts(id) ON DELETE RESTRICT,
  transaction_type varchar(20) NOT NULL CHECK (transaction_type IN ('created','payment','adjustment','cancelled')),
  amount numeric(14,2) NOT NULL CHECK (amount >= 0),
  note text,
  created_by uuid REFERENCES users(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS stock_movements (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id uuid NOT NULL REFERENCES products(id) ON DELETE RESTRICT,
  movement_type varchar(20) NOT NULL CHECK (movement_type IN ('opening','purchase','sale','return','write_off','adjustment')),
  quantity_delta numeric(14,3) NOT NULL,
  unit_cost numeric(14,2) NOT NULL DEFAULT 0,
  reference_type varchar(40),
  reference_id uuid,
  note text,
  branch_id uuid REFERENCES branches(id) ON DELETE RESTRICT,
  created_by uuid REFERENCES users(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS stock_movements_product_idx ON stock_movements(product_id, created_at DESC);

CREATE TABLE IF NOT EXISTS cash_sessions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  cashier_id uuid NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
  branch_id uuid REFERENCES branches(id) ON DELETE RESTRICT,
  opening_amount numeric(14,2) NOT NULL DEFAULT 0 CHECK (opening_amount >= 0),
  expected_closing_amount numeric(14,2),
  counted_closing_amount numeric(14,2),
  difference_amount numeric(14,2),
  status varchar(20) NOT NULL DEFAULT 'open' CHECK (status IN ('open','closed')),
  opened_at timestamptz NOT NULL DEFAULT now(),
  closed_at timestamptz
);
CREATE UNIQUE INDEX IF NOT EXISTS one_open_session_per_cashier ON cash_sessions(cashier_id) WHERE status = 'open';

CREATE TABLE IF NOT EXISTS audit_logs (
  id bigserial PRIMARY KEY,
  user_id uuid REFERENCES users(id) ON DELETE SET NULL,
  action varchar(100) NOT NULL,
  entity_type varchar(100) NOT NULL,
  entity_id text,
  details jsonb NOT NULL DEFAULT '{}'::jsonb,
  ip_address inet,
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS audit_logs_created_idx ON audit_logs(created_at DESC);
