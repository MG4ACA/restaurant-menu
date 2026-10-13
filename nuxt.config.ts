// https://nuxt.com/docs/api/configuration/nuxt-config
export default defineNuxtConfig({
  modules: [
    '@nuxt/eslint',
    '@nuxt/ui'
  ],

  devtools: {
    enabled: true
  },

  css: ['~/assets/css/main.css'],

  runtimeConfig: {
    public: {
      supabaseUrl: '',
      supabaseAnonKey: ''
    }
  },

  routeRules: {
    '/': { prerender: true },
    '/menu/**': { ssr: true }
  },

  vite: {
    optimizeDeps: {
      include: ['@supabase/supabase-js', 'qrcode']
    }
  },

  compatibilityDate: '2026-06-30',

  eslint: {
    config: {
      stylistic: {
        commaDangle: 'never',
        braceStyle: '1tbs'
      }
    }
  }
})
