-- ==========================================
-- CORTXGPT - SUPABASE FULL SETUP (25 Mart 2026)
-- ==========================================

-- 1. USERS TABLE
CREATE TABLE IF NOT EXISTS users (
  id TEXT PRIMARY KEY, -- auth.uid()::text
  email TEXT UNIQUE NOT NULL,
  username TEXT,
  role TEXT DEFAULT 'free', -- free, pro, vip, admin
  credits INTEGER DEFAULT 1000,
  status TEXT DEFAULT 'active', -- active, suspended
  verified BOOLEAN DEFAULT FALSE,
  background_preference TEXT DEFAULT 'default',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. IP LOGS TABLE
CREATE TABLE IF NOT EXISTS ip_logs (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id TEXT,
  ip_address TEXT NOT NULL,
  action TEXT NOT NULL, -- login, register, message, payment, etc.
  path TEXT,
  user_agent TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. EMAIL VERIFICATIONS (OTP) TABLE
CREATE TABLE IF NOT EXISTS email_verifications (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id TEXT NOT NULL,
  email TEXT NOT NULL,
  code TEXT NOT NULL,
  expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
  verified_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. PAYMENT PROOFS (DEKONT) TABLE
CREATE TABLE IF NOT EXISTS payment_proofs (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id TEXT NOT NULL,
  plan_name TEXT NOT NULL,
  plan_price TEXT NOT NULL,
  file_name TEXT NOT NULL,
  file_data TEXT NOT NULL, -- Base64 encoded file
  file_type TEXT,
  file_size INTEGER,
  coupon_used TEXT,
  discount_amount NUMERIC DEFAULT 0,
  status TEXT DEFAULT 'pending', -- pending, approved, rejected
  rejection_reason TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. COUPONS TABLE
CREATE TABLE IF NOT EXISTS coupons (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  code TEXT UNIQUE NOT NULL,
  discount_percent INTEGER NOT NULL,
  expires_at TIMESTAMP WITH TIME ZONE,
  usage_limit INTEGER DEFAULT 100,
  used_count INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 6. API SETTINGS TABLE
CREATE TABLE IF NOT EXISTS api_settings (
  id TEXT PRIMARY KEY DEFAULT 'current',
  openai_key TEXT,
  supabase_url TEXT,
  supabase_key TEXT,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ==========================================
-- REALTIME & SECURITY (RLS)
-- ==========================================

-- Enable Realtime for all tables
ALTER PUBLICATION supabase_realtime ADD TABLE users, ip_logs, payment_proofs, email_verifications;

-- Enable RLS
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE ip_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE email_verifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment_proofs ENABLE ROW LEVEL SECURITY;
ALTER TABLE coupons ENABLE ROW LEVEL SECURITY;
ALTER TABLE api_settings ENABLE ROW LEVEL SECURITY;

-- RLS POLICIES
-- Users can read their own data
CREATE POLICY "Users can read own data" ON users FOR SELECT USING (auth.uid()::text = id);
CREATE POLICY "Users can update own data" ON users FOR UPDATE USING (auth.uid()::text = id);

-- Admin can read everything
CREATE POLICY "Admin can read all users" ON users FOR ALL USING (EXISTS (SELECT 1 FROM users WHERE id = auth.uid()::text AND role = 'admin'));
CREATE POLICY "Admin can read all logs" ON ip_logs FOR ALL USING (EXISTS (SELECT 1 FROM users WHERE id = auth.uid()::text AND role = 'admin'));
CREATE POLICY "Admin can read all proofs" ON payment_proofs FOR ALL USING (EXISTS (SELECT 1 FROM users WHERE id = auth.uid()::text AND role = 'admin'));

-- Public can insert logs (for tracking)
CREATE POLICY "Public can insert logs" ON ip_logs FOR INSERT WITH CHECK (TRUE);

-- Users can insert their own proofs
CREATE POLICY "Users can insert own proofs" ON payment_proofs FOR INSERT WITH CHECK (auth.uid()::text = user_id);

-- ==========================================
-- INITIAL DATA
-- ==========================================
INSERT INTO api_settings (id, openai_key) VALUES ('current', '') ON CONFLICT (id) DO NOTHING;
