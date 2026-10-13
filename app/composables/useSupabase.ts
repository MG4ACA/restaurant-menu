import type { SupabaseClient, User } from '@supabase/supabase-js'

export function useSupabase(): SupabaseClient {
  const { $supabase } = useNuxtApp()
  return $supabase as SupabaseClient
}

export function useAuth() {
  const supabase = useSupabase()
  const user = useState<User | null>('auth_user', () => null)
  const loading = useState('auth_loading', () => true)

  async function init() {
    loading.value = true
    const { data } = await supabase.auth.getSession()
    user.value = data.session?.user ?? null
    loading.value = false

    supabase.auth.onAuthStateChange((_event, session) => {
      user.value = session?.user ?? null
    })
  }

  async function signIn(email: string, password: string) {
    const { error } = await supabase.auth.signInWithPassword({ email, password })
    if (error) throw error
  }

  async function signUp(email: string, password: string) {
    const { data, error } = await supabase.auth.signUp({ email, password })
    if (error) throw error
    return data
  }

  async function signOut() {
    const { error } = await supabase.auth.signOut()
    if (error) throw error
    user.value = null
  }

  return { user, loading, init, signIn, signUp, signOut }
}
