<script setup lang="ts">
definePageMeta({ layout: 'blank' })

const { user, loading, init } = useAuth()

onMounted(async () => {
  await init()
  if (user.value) {
    await navigateTo('/dashboard')
  } else {
    await navigateTo('/login')
  }
})
</script>

<template>
  <div class="min-h-screen flex items-center justify-center">
    <UIcon name="i-lucide-loader-2" class="size-8 animate-spin text-primary-500" />
  </div>
</template>
