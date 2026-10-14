<script setup lang="ts">
import type { Category, MenuItem, Restaurant } from '~/types'
import { formatPrice } from '~/utils/format'

definePageMeta({ layout: 'blank' })

const route = useRoute()
const slug = route.params.slug as string

// Use Supabase directly for server-side compatible public data fetch
const { $supabase } = useNuxtApp()
const { user, init: initAuth } = useAuth()

const { data: pageData, error } = await useAsyncData(`menu-${slug}`, async () => {
  // Fetch restaurant by slug
  const { data: restaurant, error: restaurantError } = await $supabase
    .from('restaurants')
    .select('*')
    .eq('slug', slug)
    .maybeSingle()

  if (restaurantError || !restaurant) return null

  // Fetch categories
  const { data: categories } = await $supabase
    .from('categories')
    .select('*')
    .eq('restaurant_id', restaurant.id)
    .order('sort_order')

  // Fetch menu items
  const { data: menuItems } = await $supabase
    .from('menu_items')
    .select('*')
    .eq('restaurant_id', restaurant.id)
    .order('sort_order')

  return {
    restaurant: restaurant as Restaurant,
    categories: (categories || []) as Category[],
    menuItems: (menuItems || []) as MenuItem[]
  }
})

const restaurant = computed(() => pageData.value?.restaurant ?? null)
const categories = computed(() => pageData.value?.categories ?? [])
const menuItems = computed(() => pageData.value?.menuItems ?? [])

const isOwner = computed(() => {
  return Boolean(user.value && restaurant.value && user.value.id === restaurant.value.owner_id)
})

const canView = computed(() => {
  if (!restaurant.value) return false
  return restaurant.value.is_published || isOwner.value
})

const publishing = ref(false)
async function handlePublish() {
  if (!restaurant.value) return
  publishing.value = true
  try {
    const { error: err } = await $supabase
      .from('restaurants')
      .update({ is_published: true })
      .eq('id', restaurant.value.id)
    if (err) throw err
    restaurant.value.is_published = true
  } catch (err: unknown) {
    console.error('Publish error:', err)
  } finally {
    publishing.value = false
  }
}

useSeoMeta({
  title: computed(() => restaurant.value ? `${restaurant.value.name} — Menu` : 'Menu'),
  description: computed(() => restaurant.value?.description || `View the digital menu for ${restaurant.value?.name}`),
  ogTitle: computed(() => restaurant.value?.name || 'Menu')
})

function itemsForCategory(categoryId: string) {
  return menuItems.value.filter(i => i.category_id === categoryId)
}

function getPhotoUrl(path: string) {
  const config = useRuntimeConfig()
  return `${config.public.supabaseUrl}/storage/v1/object/public/menu-photos/${path}`
}

// Active category for sticky navigation
const activeCategory = ref<string | null>(null)
const categoryRefs = ref<Record<string, HTMLElement>>({})

onMounted(async () => {
  await initAuth()
  if (categories.value.length > 0) {
    activeCategory.value = categories.value[0]?.id ?? null
  }
})

function scrollToCategory(id: string) {
  activeCategory.value = id
  const el = document.getElementById(`cat-${id}`)
  if (el) {
    el.scrollIntoView({ behavior: 'smooth', block: 'start' })
  }
}
</script>

<template>
  <div>
    <!-- Not found / Unpublished state -->
    <div v-if="error || !restaurant || !canView" class="min-h-screen flex items-center justify-center p-6">
      <div class="text-center max-w-sm">
        <div class="inline-flex items-center justify-center size-16 rounded-2xl bg-neutral-100 dark:bg-neutral-800 text-neutral-400 mb-6">
          <UIcon name="i-lucide-utensils" class="size-8" />
        </div>
        <h1 class="text-xl font-bold text-neutral-900 dark:text-white mb-2">Menu not found</h1>
        <p class="text-neutral-500 dark:text-neutral-400 text-sm">
          {{ restaurant && !restaurant.is_published
            ? 'This menu is currently in draft mode and has not been published yet.'
            : 'This menu is not available. It may be unpublished or the link is incorrect.' }}
        </p>
      </div>
    </div>

    <template v-else>
      <!-- Owner preview draft banner -->
      <div
        v-if="!restaurant.is_published && isOwner"
        class="bg-amber-600 text-white px-4 py-2.5 text-sm font-medium flex flex-wrap items-center justify-between gap-3 sticky top-0 z-50 shadow-md"
      >
        <div class="flex items-center gap-2">
          <UIcon name="i-lucide-eye" class="size-4 shrink-0" />
          <span>Draft Preview — This menu is unpublished and hidden from customers.</span>
        </div>
        <UButton
          size="xs"
          color="neutral"
          variant="solid"
          :loading="publishing"
          @click="handlePublish"
        >
          Publish Now
        </UButton>
      </div>

      <!-- Hero header -->
      <div class="bg-gradient-to-br from-amber-600 via-orange-500 to-red-500 text-white">
        <div class="max-w-2xl mx-auto px-4 pt-6 sm:pt-8 pb-8">
          <!-- Top utility bar: Digital Menu tag + Dark/Light mode switch -->
          <div class="flex items-center justify-between mb-4">
            <div class="flex items-center gap-1.5 opacity-90">
              <UIcon name="i-lucide-utensils" class="size-4" />
              <span class="text-xs font-semibold tracking-wider uppercase">Digital Menu</span>
            </div>
            <div class="bg-black/20 hover:bg-black/30 backdrop-blur rounded-full p-0.5 border border-white/20 transition-colors">
              <UColorModeButton />
            </div>
          </div>

          <div class="flex items-center gap-4 mb-3">
            <div
              v-if="restaurant.logo_path"
              class="size-16 sm:size-20 rounded-2xl overflow-hidden bg-white/15 backdrop-blur border border-white/25 shadow-lg shrink-0 p-0.5"
            >
              <img
                :src="getPhotoUrl(restaurant.logo_path)"
                :alt="restaurant.name"
                class="size-full object-cover rounded-[14px]"
              />
            </div>
            <div>
              <h1 class="text-2xl sm:text-3xl font-bold leading-tight">{{ restaurant.name }}</h1>
            </div>
          </div>
          <p v-if="restaurant.description" class="text-white/80 text-sm sm:text-base leading-relaxed">
            {{ restaurant.description }}
          </p>
          <div v-if="restaurant.phone || restaurant.address" class="flex flex-wrap gap-4 mt-4 text-white/70 text-sm">
            <span v-if="restaurant.phone" class="flex items-center gap-1.5">
              <UIcon name="i-lucide-phone" class="size-3.5" />
              {{ restaurant.phone }}
            </span>
            <span v-if="restaurant.address" class="flex items-center gap-1.5">
              <UIcon name="i-lucide-map-pin" class="size-3.5" />
              {{ restaurant.address }}
            </span>
          </div>
        </div>
      </div>

      <!-- Sticky category nav -->
      <div v-if="categories.length > 0" class="sticky top-0 z-30 bg-white/95 dark:bg-neutral-950/95 backdrop-blur border-b border-neutral-200 dark:border-neutral-800">
        <div class="max-w-2xl mx-auto px-4">
          <div class="flex gap-1 overflow-x-auto scrollbar-none py-2">
            <button
              v-for="cat in categories"
              :key="cat.id"
              class="shrink-0 px-4 py-1.5 rounded-full text-sm font-medium transition-colors"
              :class="activeCategory === cat.id
                ? 'bg-primary-500 text-white'
                : 'text-neutral-600 dark:text-neutral-400 hover:bg-neutral-100 dark:hover:bg-neutral-800'"
              @click="scrollToCategory(cat.id)"
            >
              {{ cat.name }}
            </button>
          </div>
        </div>
      </div>

      <!-- Menu content -->
      <div class="max-w-2xl mx-auto px-4 py-6 pb-16">
        <!-- Empty menu -->
        <div v-if="categories.length === 0" class="text-center py-16">
          <UIcon name="i-lucide-clipboard-list" class="size-10 text-neutral-300 dark:text-neutral-600 mx-auto mb-3" />
          <p class="text-neutral-500 dark:text-neutral-400">Menu coming soon</p>
        </div>

        <!-- Category sections -->
        <div v-for="cat in categories" :key="cat.id" :id="`cat-${cat.id}`" class="mb-8">
          <h2 class="text-xl font-bold text-neutral-900 dark:text-white mb-4 flex items-center gap-2">
            {{ cat.name }}
            <span class="text-sm font-normal text-neutral-400">
              ({{ itemsForCategory(cat.id).length }})
            </span>
          </h2>

          <div class="space-y-3">
            <div
              v-for="item in itemsForCategory(cat.id)"
              :key="item.id"
              class="bg-white dark:bg-neutral-900 rounded-2xl border border-neutral-100 dark:border-neutral-800 overflow-hidden"
              :class="{ 'opacity-60': !item.is_available }"
            >
              <!-- Item content -->
              <div class="p-4">
                <div class="flex items-start justify-between gap-4">
                  <!-- Name, description & price (if no photo) -->
                  <div class="flex-1 min-w-0">
                    <div class="flex items-center gap-2">
                      <p class="font-semibold text-neutral-900 dark:text-white leading-snug">
                        {{ item.name }}
                      </p>
                      <UBadge
                        v-if="!item.is_available"
                        color="error"
                        variant="subtle"
                        size="xs"
                        label="Sold out"
                      />
                    </div>
                    <p v-if="item.description" class="text-sm text-neutral-500 dark:text-neutral-400 mt-1 leading-relaxed">
                      {{ item.description }}
                    </p>
                    <!-- Price below description if no photo -->
                    <div v-if="!item.photo_path" class="mt-3">
                      <span class="text-base font-bold text-primary-600 dark:text-primary-400">
                        {{ formatPrice(item.price) }}
                      </span>
                    </div>
                  </div>

                  <!-- Right side: Photo with Price directly below -->
                  <div v-if="item.photo_path" class="shrink-0 flex flex-col items-center">
                    <div class="size-20 rounded-xl overflow-hidden bg-neutral-100 dark:bg-neutral-800 shadow-sm relative mb-1.5">
                      <img
                        :src="getPhotoUrl(item.photo_path)"
                        :alt="item.name"
                        class="size-full object-cover"
                        loading="lazy"
                      />
                      <div v-if="!item.is_available" class="absolute inset-0 bg-black/40 flex items-center justify-center">
                        <span class="text-[10px] font-bold text-white bg-red-600/90 px-1.5 py-0.5 rounded">Sold out</span>
                      </div>
                    </div>
                    <span class="text-sm font-bold text-primary-600 dark:text-primary-400">
                      {{ formatPrice(item.price) }}
                    </span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Footer -->
        <div class="border-t border-neutral-200 dark:border-neutral-800 pt-6 mt-8 text-center text-xs text-neutral-400 dark:text-neutral-500">
          <p>
            Powered by
            <a
              href="https://lumicore-labs.com"
              target="_blank"
              rel="noopener noreferrer"
              class="font-semibold text-neutral-600 dark:text-neutral-300 hover:text-primary-600 dark:hover:text-primary-400 hover:underline transition-colors"
            >
              Lumicore Labs
            </a>
          </p>
        </div>
      </div>
    </template>
  </div>
</template>
