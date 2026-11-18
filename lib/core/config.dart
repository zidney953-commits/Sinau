/// Konfigurasi Supabase project Sinau.
/// Publishable key aman ditaruh di aplikasi (akses dibatasi RLS).
/// JANGAN pernah menaruh secret / service_role key di sini.
class AppConfig {
  static const supabaseUrl = 'https://mablbfcvtnjtwlsoargy.supabase.co';
  static const publishableKey = 'sb_publishable_2IvgYes6d9jvFKIXf_LBEA_Hqhq138j';

  static const restUrl = '$supabaseUrl/rest/v1';
  static const authUrl = '$supabaseUrl/auth/v1';
  static const storageUrl = '$supabaseUrl/storage/v1';

  /// Versi aplikasi: [aplikasi ke-].[update ke-].[bulan],[tahun]
  /// 1 = aplikasi kedua KELOMPOK-4, 2 = update kedua, 11,26 = November 2026.
  static const version = '1.2.11,26';
  static const releaseDate = '17/11/2026';
  static const brand = 'KELOMPOK-4';
}
