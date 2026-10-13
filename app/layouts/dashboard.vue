<script setup lang="ts">
const { user, signOut } = useAuth()

async function handleSignOut() {
  await signOut()
  await navigateTo('/login')
}
</script>

<template>
  <div class="min-h-screen bg-neutral-50 dark:bg-neutral-950 flex flex-col">
    <!-- Top nav -->
    <header class="bg-white dark:bg-neutral-900 border-b border-neutral-200 dark:border-neutral-800 sticky top-0 z-50">
      <div class="max-w-6xl mx-auto px-4 sm:px-6 h-16 flex items-center justify-between gap-4">
        <NuxtLink to="/dashboard" class="flex items-center gap-2 font-bold text-lg text-primary-600 dark:text-primary-400 hover:opacity-80 transition-opacity">
          <UIcon name="i-lucide-utensils" class="size-5" />
          <span class="hidden sm:inline">Lumicore Menu</span>
        </NuxtLink>

        <div class="flex items-center gap-2 sm:gap-3">
          <span class="hidden sm:block text-sm text-neutral-500 dark:text-neutral-400 truncate max-w-48">
            {{ user?.email }}
          </span>
          <UColorModeButton />
          <UButton
            icon="i-lucide-log-out"
            color="neutral"
            variant="ghost"
            size="sm"
            aria-label="Sign out"
            @click="handleSignOut"
          />
        </div>
      </div>
    </header>

    <!-- Page content -->
    <main class="flex-1">
      <slot />
    </main>
  </div>
</template>
