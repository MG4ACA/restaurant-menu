<script setup lang="ts">
import { slugify } from '~/utils/format'
import type { Restaurant } from '~/types'

const props = defineProps<{
  existing?: Restaurant | null
}>()

const emit = defineEmits<{
  saved: []
}>()

const { createRestaurant, updateRestaurant } = useRestaurant()
const toast = useToast()

const form = reactive({
  name: props.existing?.name || '',
  slug: props.existing?.slug || '',
  description: props.existing?.description || '',
  phone: props.existing?.phone || '',
  address: props.existing?.address || '',
  is_published: props.existing?.is_published || false
})

const errors = reactive({ name: '', slug: '' })
const saving = ref(false)

// Auto-slug from name (only when creating)
watch(() => form.name, (val) => {
  if (!props.existing) {
    form.slug = slugify(val)
  }
})

// Sync from prop when editing
watch(() => props.existing, (val) => {
  if (val) {
    form.name = val.name
    form.slug = val.slug
    form.description = val.description || ''
    form.phone = val.phone || ''
    form.address = val.address || ''
    form.is_published = val.is_published
  }
})

function validate() {
  errors.name = ''
  errors.slug = ''
  let valid = true
  if (!form.name.trim()) {
    errors.name = 'Restaurant name is required'
    valid = false
  }
  if (!form.slug.trim() || !/^[a-z0-9-]+$/.test(form.slug)) {
    errors.slug = 'Slug must contain only lowercase letters, numbers and hyphens'
    valid = false
  }
  return valid
}

async function handleSubmit() {
  if (!validate()) return
  saving.value = true
  try {
    if (props.existing) {
      await updateRestaurant({
        name: form.name.trim(),
        slug: form.slug.trim(),
        description: form.description.trim() || null,
        phone: form.phone.trim() || null,
        address: form.address.trim() || null,
        is_published: form.is_published
      })
      toast.add({ title: 'Profile updated', color: 'success' })
    } else {
      await createRestaurant({
        name: form.name.trim(),
        slug: form.slug.trim(),
        description: form.description.trim() || undefined,
        phone: form.phone.trim() || undefined,
        address: form.address.trim() || undefined
      })
      toast.add({ title: 'Restaurant created!', description: 'Start adding your menu categories and items.', color: 'success' })
    }
    emit('saved')
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : 'Save failed'
    toast.add({ title: 'Save failed', description: msg, color: 'error' })
  } finally {
    saving.value = false
  }
}
</script>

<template>
  <UCard>
    <template v-if="existing" #header>
      <h2 class="text-lg font-semibold text-neutral-900 dark:text-white">Restaurant profile</h2>
    </template>

    <form class="space-y-5" @submit.prevent="handleSubmit">
      <UFormField label="Restaurant name" :error="errors.name" required>
        <UInput
          v-model="form.name"
          id="restaurant-name"
          placeholder="e.g. The Spice Garden"
          class="w-full"
          :disabled="saving"
        />
      </UFormField>

      <UFormField label="URL slug" :error="errors.slug" required hint="Used in your public menu URL">
        <div class="flex items-center gap-2">
          <span class="text-sm text-neutral-400 shrink-0">/menu/</span>
          <UInput
            v-model="form.slug"
            id="restaurant-slug"
            placeholder="spice-garden"
            class="w-full"
            :disabled="saving || !!existing"
          />
        </div>
        <p v-if="!errors.slug && form.slug" class="mt-1 text-xs text-neutral-500">
          Public URL: /menu/{{ form.slug }}
        </p>
      </UFormField>

      <UFormField label="Description" hint="Optional – shown on your public menu">
        <UTextarea
          v-model="form.description"
          id="restaurant-description"
          placeholder="A short description of your restaurant"
          :rows="3"
          class="w-full"
          :disabled="saving"
        />
      </UFormField>

      <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
        <UFormField label="Phone number">
          <UInput
            v-model="form.phone"
            id="restaurant-phone"
            type="tel"
            placeholder="+94 77 123 4567"
            class="w-full"
            :disabled="saving"
          />
        </UFormField>

        <UFormField label="Address">
          <UInput
            v-model="form.address"
            id="restaurant-address"
            placeholder="Colombo 03"
            class="w-full"
            :disabled="saving"
          />
        </UFormField>
      </div>

      <div v-if="existing" class="flex items-center justify-between py-3 px-4 rounded-xl bg-neutral-50 dark:bg-neutral-800/50 border border-neutral-200 dark:border-neutral-700">
        <div>
          <p class="text-sm font-medium text-neutral-900 dark:text-white">Published</p>
          <p class="text-xs text-neutral-500 dark:text-neutral-400">Make your menu visible to customers</p>
        </div>
        <USwitch v-model="form.is_published" id="restaurant-published" :disabled="saving" />
      </div>

      <div class="pt-2">
        <UButton
          type="submit"
          :loading="saving"
          :disabled="saving"
          class="w-full sm:w-auto justify-center"
        >
          {{ existing ? 'Save changes' : 'Create restaurant' }}
        </UButton>
      </div>
    </form>
  </UCard>
</template>
