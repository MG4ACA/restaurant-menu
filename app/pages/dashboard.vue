<script setup lang="ts">
definePageMeta({ layout: 'dashboard', middleware: 'auth' })
useSeoMeta({ title: 'Dashboard — Lumicore Menu' })

const { user, init } = useAuth()
const toast = useToast()
const {
  restaurant,
  categories,
  menuItems,
  loading,
  error,
  fetchRestaurant,
  fetchCategories,
  fetchMenuItems,
  togglePublished
} = useRestaurant()

const togglingPublish = ref(false)

async function handleTogglePublish() {
  if (!restaurant.value) return
  togglingPublish.value = true
  try {
    const next = !restaurant.value.is_published
    await togglePublished(next)
    toast.add({
      title: next ? 'Menu published!' : 'Menu unpublished',
      description: next ? 'Customers can now view your digital menu.' : 'Menu is now in draft mode.',
      color: next ? 'success' : 'neutral'
    })
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : 'Failed to update status'
    toast.add({ title: 'Error', description: msg, color: 'error' })
  } finally {
    togglingPublish.value = false
  }
}

onMounted(async () => {
  await init()
  await fetchRestaurant()
  if (restaurant.value) {
    await Promise.all([fetchCategories(), fetchMenuItems()])
  }
})

// Active tab
const activeTab = ref('menu')
const tabs = [
  { label: 'Menu', value: 'menu', icon: 'i-lucide-menu' },
  { label: 'Profile', value: 'profile', icon: 'i-lucide-store' },
  { label: 'QR Code', value: 'qr', icon: 'i-lucide-qr-code' }
]
</script>

<template>
  <div class="max-w-6xl mx-auto px-4 sm:px-6 py-6 sm:py-8">
    <!-- Loading state -->
    <div v-if="loading" class="flex items-center justify-center py-24">
      <UIcon name="i-lucide-loader-2" class="size-8 animate-spin text-primary-500" />
    </div>

    <!-- Error state -->
    <UAlert
      v-else-if="error"
      icon="i-lucide-alert-circle"
      color="error"
      :title="error"
      class="mb-6"
    />

    <!-- No restaurant yet — first run -->
    <template v-else-if="!restaurant">
      <div class="text-center py-16 max-w-md mx-auto">
        <div class="inline-flex items-center justify-center size-16 rounded-2xl bg-primary-100 dark:bg-primary-900/30 text-primary-600 dark:text-primary-400 mb-6">
          <UIcon name="i-lucide-store" class="size-8" />
        </div>
        <h1 class="text-2xl font-bold text-neutral-900 dark:text-white mb-2">Create your restaurant</h1>
        <p class="text-neutral-500 dark:text-neutral-400 mb-8">
          Set up your restaurant profile to start building your digital menu.
        </p>
        <DashboardRestaurantForm @saved="async () => { await fetchCategories(); await fetchMenuItems() }" />
      </div>
    </template>

    <!-- Dashboard -->
    <template v-else>
      <!-- Page header -->
      <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-6">
        <div>
          <h1 class="text-2xl font-bold text-neutral-900 dark:text-white">{{ restaurant.name }}</h1>
          <div class="flex items-center gap-2 mt-1">
            <UBadge
              :color="restaurant.is_published ? 'success' : 'warning'"
              variant="subtle"
              :label="restaurant.is_published ? 'Published' : 'Draft'"
            />
            <span class="text-sm text-neutral-500 dark:text-neutral-400">/menu/{{ restaurant.slug }}</span>
          </div>
        </div>

        <div class="flex items-center gap-2">
          <UButton
            v-if="!restaurant.is_published"
            color="primary"
            icon="i-lucide-globe"
            :loading="togglingPublish"
            size="sm"
            @click="handleTogglePublish"
          >
            Publish menu
          </UButton>
          <UButton
            v-else
            color="neutral"
            variant="ghost"
            icon="i-lucide-eye-off"
            :loading="togglingPublish"
            size="sm"
            @click="handleTogglePublish"
          >
            Unpublish
          </UButton>

          <UButton
            :to="`/menu/${restaurant.slug}`"
            target="_blank"
            icon="i-lucide-external-link"
            color="neutral"
            variant="outline"
            size="sm"
          >
            Preview menu
          </UButton>
        </div>
      </div>

      <!-- Draft warning banner -->
      <div
        v-if="!restaurant.is_published"
        class="mb-6 flex flex-col sm:flex-row sm:items-center justify-between gap-3 p-4 rounded-xl bg-amber-50 dark:bg-amber-950/30 border border-amber-200 dark:border-amber-800 text-amber-900 dark:text-amber-200"
      >
        <div class="flex items-start gap-3">
          <UIcon name="i-lucide-alert-triangle" class="size-5 text-amber-600 dark:text-amber-400 shrink-0 mt-0.5" />
          <div>
            <p class="font-medium text-sm">Your menu is currently in Draft mode</p>
            <p class="text-xs text-amber-700 dark:text-amber-400 mt-0.5">
              Customers scanning your QR code or opening the link will see "Menu not found" until you publish it.
            </p>
          </div>
        </div>
        <UButton
          color="primary"
          size="xs"
          class="shrink-0 self-start sm:self-auto"
          :loading="togglingPublish"
          @click="handleTogglePublish"
        >
          Publish now
        </UButton>
      </div>

      <!-- Tabs -->
      <div class="border-b border-neutral-200 dark:border-neutral-800 mb-6">
        <nav class="flex gap-1 -mb-px">
          <button
            v-for="tab in tabs"
            :key="tab.value"
            class="flex items-center gap-1.5 px-4 py-3 text-sm font-medium border-b-2 transition-colors"
            :class="activeTab === tab.value
              ? 'border-primary-500 text-primary-600 dark:text-primary-400'
              : 'border-transparent text-neutral-500 dark:text-neutral-400 hover:text-neutral-700 dark:hover:text-neutral-300'"
            @click="activeTab = tab.value"
          >
            <UIcon :name="tab.icon" class="size-4" />
            {{ tab.label }}
          </button>
        </nav>
      </div>

      <!-- Tab: Menu -->
      <div v-if="activeTab === 'menu'">
        <DashboardMenuManager />
      </div>

      <!-- Tab: Profile -->
      <div v-if="activeTab === 'profile'">
        <DashboardRestaurantForm :existing="restaurant" @saved="() => {}" />
      </div>

      <!-- Tab: QR Code -->
      <div v-if="activeTab === 'qr'">
        <DashboardQrCode />
      </div>
    </template>
  </div>
</template>
