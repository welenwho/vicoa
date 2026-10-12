import { createBrowserClient } from '@supabase/ssr'
import { getDesktopConfig } from '@/lib/runtime-config'

export function createClient() {
  const desktop = getDesktopConfig()
  return createBrowserClient(
    desktop?.supabaseUrl || process.env.NEXT_PUBLIC_SUPABASE_URL || process.env.SUPABASE_URL!,
    desktop?.supabaseAnonKey || process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || process.env.SUPABASE_ANON_KEY!
  )
}