import { createClient } from '@supabase/supabase-js'
import type { SupabaseClient } from '@supabase/supabase-js'

export default defineNuxtPlugin(() => {
  const config = useRuntimeConfig()

  const supabase: SupabaseClient = createClient(
    config.public.supabaseUrl as string,
    config.public.supabaseAnonKey as string,
    {
      auth: {
        persistSession: import.meta.client,
        autoRefreshToken: import.meta.client,
        detectSessionInUrl: import.meta.client
      }
    }
  )

  return {
    provide: {
      supabase
    }
  }
})
