
import { createClient } from '@supabase/supabase-js';

const SUPABASE_URL = 'https://qrqlflmyklkssghaugig.supabase.co';
const SUPABASE_KEY = 'sb_publishable_lQLCYTkAFU9QyXh_FaFnWg_nYqfVVGy';

const supabase = createClient(SUPABASE_URL, SUPABASE_KEY);

async function testConnection() {
  console.log('Supabase bağlantısı test ediliyor...');
  try {
    const { data, error } = await supabase.from('users').select('id').limit(1);
    if (error) {
      console.error('Supabase hatası:', error.message);
      if (error.message.includes('fetch')) {
        console.log('Ağ hatası: Supabase URL\'sine ulaşılamıyor.');
      } else {
        console.log('Supabase projesi aktif ancak tablo erişiminde sorun olabilir.');
      }
    } else {
      console.log('Supabase bağlantısı başarılı! "users" tablosuna erişilebiliyor.');
    }
  } catch (err) {
    console.error('Beklenmedik hata:', err.message);
  }
}

testConnection();
