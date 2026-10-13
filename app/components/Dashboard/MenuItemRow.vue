<script setup lang="ts">
import { formatPrice } from '~/utils/format'
import type { MenuItem } from '~/types'

const props = defineProps<{
  item: MenuItem
}>()

const emit = defineEmits<{
  edit: []
}>()

const { updateMenuItem, deleteMenuItem, getPhotoUrl } = useRestaurant()
const toast = useToast()

const toggling = ref(false)
const deleting = ref(false)

const photoUrl = computed(() =>
  props.item.photo_path ? getPhotoUrl(props.item.photo_path) : null
)

async function toggleAvailability() {
  toggling.value = true
  try {
    await updateMenuItem(props.item.id, { is_available: !props.item.is_available })
  } catch (err: unknown) {
    toast.add({ title: 'Update failed', description: (err as Error).message, color: 'error' })
  } finally {
    toggling.value = false
  }
}

async function handleDelete() {
  deleting.value = true
  try {
    await deleteMenuItem(props.item.id)
    toast.add({ title: 'Item deleted', color: 'success' })
  } catch (err: unknown) {
    toast.add({ title: 'Delete failed', description: (err as Error).message, color: 'error' })
    deleting.value = false
  }
}
</script>

<template>
  <div class="flex items-start gap-4 px-5 py-4 hover:bg-neutral-50 dark:hover:bg-neutral-800/40 transition-colors">
    <!-- Photo thumbnail -->
    <div class="shrink-0 size-14 rounded-xl overflow-hidden bg-neutral-100 dark:bg-neutral-800 flex items-center justify-center">
      <img v-if="photoUrl" :src="photoUrl" :alt="item.name" class="size-full object-cover" />
      <UIcon v-else name="i-lucide-image" class="size-6 text-neutral-300 dark:text-neutral-600" />
    </div>

    <!-- Info -->
    <div class="flex-1 min-w-0">
      <div class="flex items-start justify-between gap-2">
        <div>
          <p class="font-medium text-neutral-900 dark:text-white leading-tight" :class="{ 'opacity-50 line-through': !item.is_available }">
            {{ item.name }}
          </p>
          <p v-if="item.description" class="text-sm text-neutral-500 dark:text-neutral-400 mt-0.5 line-clamp-1">
            {{ item.description }}
          </p>
        </div>
        <span class="text-sm font-semibold text-primary-600 dark:text-primary-400 shrink-0">
          {{ formatPrice(item.price) }}
        </span>
      </div>

      <!-- Status + actions -->
      <div class="flex items-center gap-2 mt-2">
        <UBadge
          :color="item.is_available ? 'success' : 'error'"
          variant="subtle"
          size="sm"
          :label="item.is_available ? 'Available' : 'Sold out'"
        />

        <div class="flex items-center gap-1 ml-auto">
          <UButton
            size="xs"
            :icon="item.is_available ? 'i-lucide-x-circle' : 'i-lucide-check-circle'"
            :color="item.is_available ? 'warning' : 'success'"
            variant="ghost"
            :loading="toggling"
            :aria-label="item.is_available ? 'Mark sold out' : 'Mark available'"
            @click="toggleAvailability"
          />
          <UButton
            size="xs"
            icon="i-lucide-pencil"
            color="neutral"
            variant="ghost"
            aria-label="Edit item"
            @click="emit('edit')"
          />
          <UButton
            size="xs"
            icon="i-lucide-trash-2"
            color="error"
            variant="ghost"
            :loading="deleting"
            aria-label="Delete item"
            @click="handleDelete"
          />
        </div>
      </div>
    </div>
  </div>
</template>
