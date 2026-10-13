<script setup>
useHead({
  meta: [
    { name: 'viewport', content: 'width=device-width, initial-scale=1' }
  ],
  link: [
    { rel: 'icon', href: '/favicon.ico' },
    { rel: 'preconnect', href: 'https://fonts.googleapis.com' },
    { rel: 'preconnect', href: 'https://fonts.gstatic.com', crossorigin: '' },
    { rel: 'stylesheet', href: 'https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap' }
  ],
  htmlAttrs: { lang: 'en' }
})

useSeoMeta({
  title: 'Lumicore Menu — Smart Digital Menus for Restaurants',
  description: 'Create a beautiful digital menu for your restaurant. Share via QR code or NFC tag.',
  ogTitle: 'Lumicore Menu',
  ogDescription: 'Smart digital menus for Sri Lankan restaurants.',
  twitterCard: 'summary_large_image'
})
</script>

<template>
  <UApp>
    <NuxtLayout>
      <NuxtPage />
    </NuxtLayout>
  </UApp>
</template>
