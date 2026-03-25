-- CortxGPT Supabase Schema
-- PostgreSQL SQL Script

-- ==================== USERS TABLE ====================
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(255) NOT NULL,
  email VARCHAR(255) UNIQUE NOT NULL,
  password VARCHAR(255),
  provider VARCHAR(50) DEFAULT 'email',
  role VARCHAR(50) DEFAULT 'Free',
  status VARCHAR(50) DEFAULT 'active',
  verified BOOLEAN DEFAULT FALSE,
  email_verified BOOLEAN DEFAULT FALSE,
  ip VARCHAR(50),
  credits INTEGER DEFAULT 100,
  daily_credits INTEGER DEFAULT 50,
  last_active TIMESTAMP DEFAULT NOW(),
  first_login TIMESTAMP DEFAULT NOW(),
  created_at TIMESTAMP DEFAULT NOW(),
  avatar_url VARCHAR(500),
  is_vip BOOLEAN DEFAULT FALSE,
  vip_expiry TIMESTAMP,
  total_messages INTEGER DEFAULT 0,
  last_message_at TIMESTAMP,
  CONSTRAINT valid_role CHECK (role IN ('Free', 'Pro', 'VIP Premium')),
  CONSTRAINT valid_status CHECK (status IN ('active', 'passive', 'banned', 'pending', 'email_unverified'))
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_created_at ON users(created_at DESC);

-- ==================== IP LOGS TABLE ====================
CREATE TABLE IF NOT EXISTS ip_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ip VARCHAR(50) NOT NULL,
  user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  user_name VARCHAR(255),
  user_email VARCHAR(255),
  action VARCHAR(50) NOT NULL,
  path VARCHAR(500),
  user_agent VARCHAR(500),
  country VARCHAR(100),
  suspicious BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT NOW(),
  CONSTRAINT valid_action CHECK (action IN ('register', 'login', 'message', 'page_view', 'logout', 'file_upload', 'voice_message'))
);

CREATE INDEX idx_ip_logs_user_id ON ip_logs(user_id);
CREATE INDEX idx_ip_logs_ip ON ip_logs(ip);
CREATE INDEX idx_ip_logs_created_at ON ip_logs(created_at DESC);
CREATE INDEX idx_ip_logs_action ON ip_logs(action);

-- ==================== VOICE MESSAGES TABLE ====================
CREATE TABLE IF NOT EXISTS voice_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  user_name VARCHAR(255) NOT NULL,
  duration INTEGER NOT NULL,
  audio_url VARCHAR(500) NOT NULL,
  transcription TEXT,
  message_id UUID,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_voice_messages_user_id ON voice_messages(user_id);
CREATE INDEX idx_voice_messages_created_at ON voice_messages(created_at DESC);

-- ==================== FILE UPLOADS TABLE ====================
CREATE TABLE IF NOT EXISTS file_uploads (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  file_name VARCHAR(500) NOT NULL,
  file_type VARCHAR(100),
  file_size INTEGER NOT NULL,
  file_url VARCHAR(500) NOT NULL,
  message_id UUID,
  uploaded_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_file_uploads_user_id ON file_uploads(user_id);
CREATE INDEX idx_file_uploads_uploaded_at ON file_uploads(uploaded_at DESC);

-- ==================== CREDITS TABLE ====================
CREATE TABLE IF NOT EXISTS credits (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  amount INTEGER NOT NULL,
  reason VARCHAR(255),
  balance_before INTEGER,
  balance_after INTEGER,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_credits_user_id ON credits(user_id);
CREATE INDEX idx_credits_created_at ON credits(created_at DESC);

-- ==================== ADMIN NOTIFICATIONS TABLE ====================
CREATE TABLE IF NOT EXISTS admin_notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  type VARCHAR(50) NOT NULL,
  title VARCHAR(255) NOT NULL,
  message TEXT NOT NULL,
  user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT NOW(),
  CONSTRAINT valid_notification_type CHECK (type IN ('new_user', 'support_request', 'vip_purchase', 'system_alert', 'credit_load', 'credit_depleted', 'ip_alert', 'file_upload', 'voice_message'))
);

CREATE INDEX idx_notifications_created_at ON admin_notifications(created_at DESC);
CREATE INDEX idx_notifications_read ON admin_notifications(read);

-- ==================== ACTIVE CHATTERS TABLE ====================
CREATE TABLE IF NOT EXISTS active_chatters (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  user_name VARCHAR(255) NOT NULL,
  user_email VARCHAR(255) NOT NULL,
  user_role VARCHAR(50) NOT NULL,
  credits INTEGER NOT NULL,
  ip VARCHAR(50),
  last_message TEXT,
  last_message_at TIMESTAMP,
  session_start TIMESTAMP DEFAULT NOW(),
  message_count INTEGER DEFAULT 0,
  voice_message_count INTEGER DEFAULT 0,
  file_count INTEGER DEFAULT 0,
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_active_chatters_user_id ON active_chatters(user_id);
CREATE INDEX idx_active_chatters_session_start ON active_chatters(session_start DESC);

-- ==================== EMAIL VERIFICATION TABLE ====================
CREATE TABLE IF NOT EXISTS email_verifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  email VARCHAR(255) NOT NULL,
  token VARCHAR(255) UNIQUE NOT NULL,
  expires_at TIMESTAMP NOT NULL,
  verified_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_email_verifications_user_id ON email_verifications(user_id);
CREATE INDEX idx_email_verifications_token ON email_verifications(token);
CREATE INDEX idx_email_verifications_expires_at ON email_verifications(expires_at);

-- ==================== RADIO STATIONS TABLE ====================
CREATE TABLE IF NOT EXISTS radio_stations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(255) NOT NULL,
  url VARCHAR(500) NOT NULL,
  genre VARCHAR(100),
  country VARCHAR(50),
  logo_url VARCHAR(500),
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Insert default radio stations
INSERT INTO radio_stations (name, url, genre, country, is_active) VALUES
('Radyo Eksen', 'https://radyoeksen.com.tr/radyoeksen.m3u8', 'Pop/Rock', 'TR', TRUE),
('NTV Radyo', 'https://ntv.radyotvonline.net/ntv', 'Haber/Pop', 'TR', TRUE),
('Kral FM', 'https://listen.radyotvonline.net/kralfm', 'Türkçe Pop', 'TR', TRUE),
('Power FM', 'https://listen.radyotvonline.net/powerfm', 'Pop/Dance', 'TR', TRUE),
('Lofi Hip Hop', 'https://streams.ilovemusic.de/iloveradio17.mp3', 'Lofi/Chill', 'INT', TRUE)
ON CONFLICT DO NOTHING;

-- ==================== VIEWS ====================

-- View: Recent IP Logs
CREATE OR REPLACE VIEW recent_ip_logs AS
SELECT 
  id,
  ip,
  user_id,
  user_name,
  user_email,
  action,
  suspicious,
  created_at
FROM ip_logs
ORDER BY created_at DESC
LIMIT 100;

-- View: Active Users Today
CREATE OR REPLACE VIEW active_users_today AS
SELECT 
  COUNT(DISTINCT user_id) as active_count,
  COUNT(DISTINCT CASE WHEN action = 'message' THEN user_id END) as chatting_count
FROM ip_logs
WHERE created_at >= NOW() - INTERVAL '24 hours';

-- View: Credit Statistics
CREATE OR REPLACE VIEW credit_statistics AS
SELECT 
  DATE(created_at) as date,
  COUNT(*) as transaction_count,
  SUM(CASE WHEN amount > 0 THEN amount ELSE 0 END) as credits_given,
  SUM(CASE WHEN amount < 0 THEN ABS(amount) ELSE 0 END) as credits_used
FROM credits
GROUP BY DATE(created_at)
ORDER BY date DESC;

-- ==================== FUNCTIONS ====================

-- Function: Deduct Credits
CREATE OR REPLACE FUNCTION deduct_credits(
  p_user_id UUID,
  p_amount INTEGER,
  p_reason VARCHAR
)
RETURNS TABLE (success BOOLEAN, remaining_credits INTEGER, message VARCHAR) AS $$
DECLARE
  v_current_credits INTEGER;
  v_user_role VARCHAR;
BEGIN
  -- Get current credits and role
  SELECT credits, role INTO v_current_credits, v_user_role FROM users WHERE id = p_user_id;
  
  -- If Pro or VIP, allow unlimited
  IF v_user_role IN ('Pro', 'VIP Premium') THEN
    RETURN QUERY SELECT TRUE, v_current_credits, 'Unlimited access'::VARCHAR;
    RETURN;
  END IF;
  
  -- Check if enough credits
  IF v_current_credits < p_amount THEN
    RETURN QUERY SELECT FALSE, v_current_credits, 'Insufficient credits'::VARCHAR;
    RETURN;
  END IF;
  
  -- Deduct credits
  UPDATE users SET credits = credits - p_amount WHERE id = p_user_id;
  
  -- Log transaction
  INSERT INTO credits (user_id, amount, reason, balance_before, balance_after)
  VALUES (p_user_id, -p_amount, p_reason, v_current_credits, v_current_credits - p_amount);
  
  RETURN QUERY SELECT TRUE, v_current_credits - p_amount, 'Credits deducted'::VARCHAR;
END;
$$ LANGUAGE plpgsql;

-- Function: Add Credits
CREATE OR REPLACE FUNCTION add_credits(
  p_user_id UUID,
  p_amount INTEGER,
  p_reason VARCHAR
)
RETURNS TABLE (success BOOLEAN, new_balance INTEGER) AS $$
DECLARE
  v_current_credits INTEGER;
BEGIN
  SELECT credits INTO v_current_credits FROM users WHERE id = p_user_id;
  
  UPDATE users SET credits = credits + p_amount WHERE id = p_user_id;
  
  INSERT INTO credits (user_id, amount, reason, balance_before, balance_after)
  VALUES (p_user_id, p_amount, p_reason, v_current_credits, v_current_credits + p_amount);
  
  RETURN QUERY SELECT TRUE, v_current_credits + p_amount;
END;
$$ LANGUAGE plpgsql;

-- ==================== ROW LEVEL SECURITY ====================

-- Enable RLS
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE ip_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE voice_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE file_uploads ENABLE ROW LEVEL SECURITY;
ALTER TABLE credits ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE active_chatters ENABLE ROW LEVEL SECURITY;
ALTER TABLE email_verifications ENABLE ROW LEVEL SECURITY;

-- Policies for users table
CREATE POLICY "Users can view their own data" ON users
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update their own data" ON users
  FOR UPDATE USING (auth.uid() = id);

-- Policies for ip_logs table
CREATE POLICY "IP logs are viewable by authenticated users" ON ip_logs
  FOR SELECT USING (auth.role() = 'authenticated');

-- Policies for voice_messages table
CREATE POLICY "Voice messages are viewable by owner" ON voice_messages
  FOR SELECT USING (auth.uid() = user_id);

-- Policies for file_uploads table
CREATE POLICY "File uploads are viewable by owner" ON file_uploads
  FOR SELECT USING (auth.uid() = user_id);

-- Policies for credits table
CREATE POLICY "Credits are viewable by owner" ON credits
  FOR SELECT USING (auth.uid() = user_id);

-- ==================== GRANTS ====================

GRANT SELECT, INSERT, UPDATE ON users TO authenticated;
GRANT SELECT, INSERT ON ip_logs TO authenticated;
GRANT SELECT, INSERT ON voice_messages TO authenticated;
GRANT SELECT, INSERT ON file_uploads TO authenticated;
GRANT SELECT ON credits TO authenticated;
GRANT SELECT ON admin_notifications TO authenticated;
GRANT SELECT, INSERT, UPDATE ON active_chatters TO authenticated;
GRANT SELECT, INSERT, UPDATE ON email_verifications TO authenticated;

-- ==================== TRIGGERS ====================

-- Trigger: Update user last_active
CREATE OR REPLACE FUNCTION update_user_last_active()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE users SET last_active = NOW() WHERE id = NEW.user_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_last_active
AFTER INSERT ON ip_logs
FOR EACH ROW
EXECUTE FUNCTION update_user_last_active();

-- Trigger: Update active chatter
CREATE OR REPLACE FUNCTION update_active_chatter()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE active_chatters 
  SET message_count = message_count + 1, 
      last_message_at = NOW(),
      updated_at = NOW()
  WHERE user_id = NEW.user_id;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_active_chatter
AFTER INSERT ON ip_logs
FOR EACH ROW
WHEN (NEW.action = 'message')
EXECUTE FUNCTION update_active_chatter();

-- Payment Proofs Table
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
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_payment_proofs_user_id ON payment_proofs(user_id);
CREATE INDEX idx_payment_proofs_status ON payment_proofs(status);
CREATE INDEX idx_payment_proofs_created_at ON payment_proofs(created_at DESC);

-- Enable RLS
ALTER TABLE payment_proofs ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Users can view their own payment proofs"
  ON payment_proofs FOR SELECT
  USING (auth.uid()::text = user_id OR EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid()::text AND users.role = 'admin'));

CREATE POLICY "Admin can view all payment proofs"
  ON payment_proofs FOR SELECT
  USING (EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid()::text AND users.role = 'admin'));

CREATE POLICY "Users can insert their own payment proofs"
  ON payment_proofs FOR INSERT
  WITH CHECK (auth.uid()::text = user_id);

CREATE POLICY "Admin can update payment proofs"
  ON payment_proofs FOR UPDATE
  USING (EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid()::text AND users.role = 'admin'));
