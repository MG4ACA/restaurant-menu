<script setup lang="ts">
definePageMeta({ layout: 'blank' })

useSeoMeta({ title: 'Sign In — Lumicore Menu' })

const { user, signIn, signUp, init } = useAuth()
const toast = useToast()

const mode = ref<'signin' | 'signup'>('signin')
const email = ref('')
const password = ref('')
const loading = ref(false)
const errors = reactive({ email: '', password: '' })

// Redirect if already logged in
onMounted(async () => {
  await init()
  if (user.value) await navigateTo('/dashboard')
})

function validate() {
  errors.email = ''
  errors.password = ''
  let valid = true
  if (!email.value || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email.value)) {
    errors.email = 'Enter a valid email address'
    valid = false
  }
  if (!password.value || password.value.length < 6) {
    errors.password = 'Password must be at least 6 characters'
    valid = false
  }
  return valid
}

async function handleSubmit() {
  if (!validate()) return
  loading.value = true
  try {
    if (mode.value === 'signin') {
      await signIn(email.value, password.value)
      await navigateTo('/dashboard')
    } else {
      const data = await signUp(email.value, password.value)
      if (data.session) {
        toast.add({ title: 'Account created!', description: 'Welcome to Lumicore Menu', color: 'success' })
        await navigateTo('/dashboard')
      } else {
        toast.add({
          title: 'Account created!',
          description: 'Please check your email to confirm your registration or sign in.',
          color: 'info'
        })
        mode.value = 'signin'
      }
    }
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : 'Operation failed'
    toast.add({ title: mode.value === 'signin' ? 'Sign in failed' : 'Sign up failed', description: msg, color: 'error' })
  } finally {
    loading.value = false
  }
}

const DEMO_EMAIL = 'demo@lumicore-labs.com'
const DEMO_PASSWORD = 'demo123456'

async function handleDemoLogin() {
  mode.value = 'signin'
  email.value = DEMO_EMAIL
  password.value = DEMO_PASSWORD
  loading.value = true
  try {
    await signIn(DEMO_EMAIL, DEMO_PASSWORD)
    toast.add({ title: 'Welcome to the Demo!', description: 'Logged in to test the owner dashboard.', color: 'success' })
    await navigateTo('/dashboard')
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : 'Demo sign in failed'
    toast.add({
      title: 'Demo account notice',
      description: 'Make sure demo@lumicore-labs.com is created in Supabase Auth or use Sign Up tab.',
      color: 'warning'
    })
  } finally {
    loading.value = false
  }
}
</script>

<template>
  <div class="min-h-screen bg-gradient-to-br from-amber-50 via-orange-50 to-red-50 dark:from-neutral-950 dark:via-neutral-900 dark:to-neutral-950 flex items-center justify-center px-4">
    <div class="w-full max-w-md">
      <!-- Logo / branding -->
      <div class="text-center mb-8">
        <div class="inline-flex items-center justify-center size-14 rounded-2xl bg-primary-600 text-white mb-4 shadow-lg shadow-primary-500/30">
          <UIcon name="i-lucide-utensils" class="size-7" />
        </div>
        <h1 class="text-2xl font-bold text-neutral-900 dark:text-white">Lumicore Menu</h1>
        <p class="mt-1 text-sm text-neutral-500 dark:text-neutral-400">Smart digital menus for your restaurant</p>
      </div>

      <!-- Sign in card -->
      <UCard class="shadow-xl shadow-neutral-200/50 dark:shadow-neutral-900/50">
        <template #header>
          <div class="flex items-center justify-between">
            <h2 class="text-lg font-semibold text-neutral-900 dark:text-white">
              {{ mode === 'signin' ? 'Owner sign in' : 'Create owner account' }}
            </h2>
            <div class="flex gap-1 p-1 bg-neutral-100 dark:bg-neutral-800 rounded-lg text-xs font-medium">
              <button
                type="button"
                :class="['px-2.5 py-1 rounded-md transition-colors', mode === 'signin' ? 'bg-white dark:bg-neutral-700 text-neutral-900 dark:text-white shadow-sm' : 'text-neutral-500 hover:text-neutral-900 dark:text-neutral-400 dark:hover:text-white']"
                @click="mode = 'signin'"
              >
                Sign in
              </button>
              <button
                type="button"
                :class="['px-2.5 py-1 rounded-md transition-colors', mode === 'signup' ? 'bg-white dark:bg-neutral-700 text-neutral-900 dark:text-white shadow-sm' : 'text-neutral-500 hover:text-neutral-900 dark:text-neutral-400 dark:hover:text-white']"
                @click="mode = 'signup'"
              >
                Sign up
              </button>
            </div>
          </div>
        </template>

        <!-- 1-Click Demo Section -->
        <div class="mb-5 p-4 rounded-xl bg-gradient-to-r from-amber-500/10 via-orange-500/10 to-amber-500/10 border border-amber-300/60 dark:border-amber-800/60">
          <div class="flex items-center gap-2 mb-1.5 text-amber-900 dark:text-amber-200">
            <UIcon name="i-lucide-sparkles" class="size-4 text-amber-600 dark:text-amber-400 shrink-0" />
            <span class="text-xs font-bold uppercase tracking-wider">Restaurant Owner Demo</span>
          </div>
          <p class="text-xs text-neutral-600 dark:text-neutral-400 mb-3">
            Want to test the dashboard immediately? Click below for instant access with pre-configured demo data.
          </p>
          <UButton
            color="primary"
            variant="solid"
            size="sm"
            icon="i-lucide-play"
            class="w-full justify-center font-medium shadow-sm"
            :loading="loading"
            @click="handleDemoLogin"
          >
            Explore Live Demo (1-Click)
          </UButton>
          <div class="mt-2 text-[11px] text-neutral-500 text-center font-mono">
            demo@lumicore-labs.com &bull; demo123456
          </div>
        </div>

        <div class="relative flex py-1 items-center mb-4">
          <div class="flex-grow border-t border-neutral-200 dark:border-neutral-800"></div>
          <span class="flex-shrink mx-3 text-xs uppercase text-neutral-400 tracking-wider">Or sign in with email</span>
          <div class="flex-grow border-t border-neutral-200 dark:border-neutral-800"></div>
        </div>

        <form class="space-y-4" @submit.prevent="handleSubmit">
          <UFormField label="Email address" :error="errors.email" required>
            <UInput
              v-model="email"
              id="login-email"
              type="email"
              placeholder="you@restaurant.com"
              autocomplete="email"
              class="w-full"
              :disabled="loading"
            />
          </UFormField>

          <UFormField label="Password" :error="errors.password" required>
            <UInput
              v-model="password"
              id="login-password"
              type="password"
              placeholder="••••••••"
              autocomplete="current-password"
              class="w-full"
              :disabled="loading"
            />
          </UFormField>

          <UButton
            type="submit"
            class="w-full justify-center"
            :loading="loading"
            :disabled="loading"
            size="lg"
          >
            {{ mode === 'signin' ? 'Sign in' : 'Create account' }}
          </UButton>
        </form>

        <template #footer>
          <p class="text-xs text-neutral-500 dark:text-neutral-400 text-center">
            {{ mode === 'signin' ? "Don't have an account?" : 'Already have an account?' }}
            <button
              type="button"
              class="text-primary-600 dark:text-primary-400 hover:underline font-medium ml-1"
              @click="mode = mode === 'signin' ? 'signup' : 'signin'"
            >
              {{ mode === 'signin' ? 'Sign up here' : 'Sign in here' }}
            </button>
          </p>
        </template>
      </UCard>
    </div>
  </div>
</template>
