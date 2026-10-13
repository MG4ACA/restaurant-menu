<script setup lang="ts">
import type { MenuItem } from '~/types'

const props = defineProps<{
  open: boolean
  item?: MenuItem | null
  categoryId: string
}>()

const emit = defineEmits<{
  'update:open': [boolean]
  saved: []
}>()

const {
  categories,
  createMenuItem,
  updateMenuItem,
  uploadPhoto,
  removePhoto,
  getPhotoUrl
} = useRestaurant()

const toast = useToast()
const fileInput = ref<HTMLInputElement | null>(null)

const form = reactive({
  name: '',
  description: '',
  price: '',
  category_id: '',
  is_available: true
})

const errors = reactive({ name: '', price: '', category_id: '' })
const saving = ref(false)
const uploadingPhoto = ref(false)
const photoPreview = ref<string | null>(null)
const pendingFile = ref<File | null>(null)

// Reset / populate form when modal opens
watch(() => props.open, (open) => {
  if (open) {
    if (props.item) {
      form.name = props.item.name
      form.description = props.item.description || ''
      form.price = String(props.item.price)
      form.category_id = props.item.category_id
      form.is_available = props.item.is_available
      photoPreview.value = props.item.photo_path ? getPhotoUrl(props.item.photo_path) : null
    } else {
      form.name = ''
      form.description = ''
      form.price = ''
      form.category_id = props.categoryId
      form.is_available = true
      photoPreview.value = null
    }
    pendingFile.value = null
    errors.name = ''
    errors.price = ''
    errors.category_id = ''
  }
})

const categoryOptions = computed(() =>
  categories.value.map(c => ({ label: c.name, value: c.id }))
)

function validate() {
  errors.name = ''
  errors.price = ''
  errors.category_id = ''
  let valid = true

  if (!form.name.trim()) {
    errors.name = 'Item name is required'
    valid = false
  }
  const priceNum = Number(form.price)
  if (!form.price || isNaN(priceNum) || priceNum < 0) {
    errors.price = 'Enter a valid price in Rs.'
    valid = false
  }
  if (!form.category_id) {
    errors.category_id = 'Select a category'
    valid = false
  }
  return valid
}

function handleFileSelect(e: Event) {
  const file = (e.target as HTMLInputElement).files?.[0]
  if (!file) return
  if (!file.type.startsWith('image/')) {
    toast.add({ title: 'Invalid file', description: 'Please select an image file.', color: 'warning' })
    return
  }
  if (file.size > 5 * 1024 * 1024) {
    toast.add({ title: 'File too large', description: 'Max photo size is 5 MB.', color: 'warning' })
    return
  }
  pendingFile.value = file
  photoPreview.value = URL.createObjectURL(file)
}

async function handleRemovePhoto() {
  if (props.item?.photo_path) {
    uploadingPhoto.value = true
    try {
      await removePhoto(props.item.id)
      toast.add({ title: 'Photo removed', color: 'success' })
    } catch (err: unknown) {
      toast.add({ title: 'Failed to remove photo', description: (err as Error).message, color: 'error' })
    } finally {
      uploadingPhoto.value = false
    }
  }
  photoPreview.value = null
  pendingFile.value = null
  if (fileInput.value) fileInput.value.value = ''
}

async function handleSave() {
  if (!validate()) return
  saving.value = true

  try {
    const payload = {
      category_id: form.category_id,
      name: form.name.trim(),
      description: form.description.trim() || undefined,
      price: Math.round(Number(form.price)),
      is_available: form.is_available
    }

    let savedItem: MenuItem

    if (props.item) {
      savedItem = await updateMenuItem(props.item.id, payload)
    } else {
      savedItem = await createMenuItem(payload)
    }

    // Upload pending photo after item exists
    if (pendingFile.value) {
      uploadingPhoto.value = true
      await uploadPhoto(savedItem.id, pendingFile.value)
      uploadingPhoto.value = false
    }

    toast.add({ title: props.item ? 'Item updated' : 'Item added', color: 'success' })
    emit('saved')
    emit('update:open', false)
  } catch (err: unknown) {
    toast.add({ title: 'Save failed', description: (err as Error).message, color: 'error' })
  } finally {
    saving.value = false
    uploadingPhoto.value = false
  }
}
</script>

<template>
  <UModal
    :open="open"
    :title="item ? 'Edit menu item' : 'Add menu item'"
    @update:open="emit('update:open', $event)"
  >
    <template #body>
      <form class="space-y-4" @submit.prevent="handleSave">
        <!-- Photo -->
        <div>
          <p class="text-sm font-medium text-neutral-700 dark:text-neutral-300 mb-2">Photo <span class="text-neutral-400 font-normal">(optional)</span></p>
          <div class="flex items-start gap-4">
            <div class="size-20 rounded-xl overflow-hidden bg-neutral-100 dark:bg-neutral-800 flex items-center justify-center shrink-0">
              <img v-if="photoPreview" :src="photoPreview" alt="Preview" class="size-full object-cover" />
              <UIcon v-else name="i-lucide-image" class="size-7 text-neutral-300 dark:text-neutral-600" />
            </div>
            <div class="space-y-2">
              <UButton
                type="button"
                icon="i-lucide-upload"
                color="neutral"
                variant="outline"
                size="sm"
                :loading="uploadingPhoto"
                @click="fileInput?.click()"
              >
                {{ photoPreview ? 'Replace photo' : 'Upload photo' }}
              </UButton>
              <UButton
                v-if="photoPreview"
                type="button"
                icon="i-lucide-trash-2"
                color="error"
                variant="ghost"
                size="sm"
                @click="handleRemovePhoto"
              >
                Remove
              </UButton>
              <p class="text-xs text-neutral-400">JPEG, PNG, WebP · max 5 MB</p>
              <input
                ref="fileInput"
                type="file"
                accept="image/jpeg,image/png,image/webp"
                class="hidden"
                @change="handleFileSelect"
              />
            </div>
          </div>
        </div>

        <UFormField label="Item name" :error="errors.name" required>
          <UInput
            v-model="form.name"
            id="item-name"
            placeholder="e.g. Chicken Kottu Roti"
            class="w-full"
            :disabled="saving"
          />
        </UFormField>

        <UFormField label="Description">
          <UTextarea
            v-model="form.description"
            id="item-description"
            placeholder="Short description of the dish"
            :rows="2"
            class="w-full"
            :disabled="saving"
          />
        </UFormField>

        <div class="grid grid-cols-2 gap-4">
          <UFormField label="Price (Rs.)" :error="errors.price" required>
            <UInput
              v-model="form.price"
              id="item-price"
              type="number"
              min="0"
              step="1"
              placeholder="0"
              class="w-full"
              :disabled="saving"
            />
          </UFormField>

          <UFormField label="Category" :error="errors.category_id" required>
            <USelect
              v-model="form.category_id"
              id="item-category"
              :items="categoryOptions"
              class="w-full"
              :disabled="saving"
            />
          </UFormField>
        </div>

        <div class="flex items-center justify-between py-3 px-4 rounded-xl bg-neutral-50 dark:bg-neutral-800/50">
          <div>
            <p class="text-sm font-medium text-neutral-900 dark:text-white">Available</p>
            <p class="text-xs text-neutral-500 dark:text-neutral-400">Uncheck to mark as sold out</p>
          </div>
          <UToggle v-model="form.is_available" id="item-available" :disabled="saving" />
        </div>
      </form>
    </template>

    <template #footer>
      <div class="flex justify-end gap-3">
        <UButton
          color="neutral"
          variant="outline"
          :disabled="saving"
          @click="emit('update:open', false)"
        >
          Cancel
        </UButton>
        <UButton
          :loading="saving || uploadingPhoto"
          :disabled="saving || uploadingPhoto"
          @click="handleSave"
        >
          {{ item ? 'Save changes' : 'Add item' }}
        </UButton>
      </div>
    </template>
  </UModal>
</template>
