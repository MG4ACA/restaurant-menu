<script setup lang="ts">
import QRCode from 'qrcode'

const { restaurant } = useRestaurant()
const toast = useToast()

const qrDataUrl = ref<string | null>(null)
const generating = ref(false)

const menuUrl = computed(() => {
  if (!restaurant.value) return ''
  const base = typeof window !== 'undefined' ? window.location.origin : ''
  return `${base}/menu/${restaurant.value.slug}`
})

async function generateQr() {
  if (!menuUrl.value) return
  generating.value = true
  try {
    qrDataUrl.value = await QRCode.toDataURL(menuUrl.value, {
      width: 400,
      margin: 2,
      color: { dark: '#1a1a1a', light: '#ffffff' }
    })
  } catch (err: unknown) {
    toast.add({ title: 'QR generation failed', description: (err as Error).message, color: 'error' })
  } finally {
    generating.value = false
  }
}

function downloadQr() {
  if (!qrDataUrl.value || !restaurant.value) return
  const a = document.createElement('a')
  a.href = qrDataUrl.value
  a.download = `${restaurant.value.slug}-menu-qr.png`
  a.click()
}

function copyUrl() {
  navigator.clipboard.writeText(menuUrl.value)
  toast.add({ title: 'URL copied!', color: 'success' })
}

onMounted(() => {
  generateQr()
})
</script>

<template>
  <div class="max-w-lg">
    <UCard>
      <template #header>
        <h2 class="text-lg font-semibold text-neutral-900 dark:text-white">QR Code & Public Link</h2>
        <p class="text-sm text-neutral-500 dark:text-neutral-400 mt-0.5">
          Share this QR code or URL with your customers. Works with NFC tags too.
        </p>
      </template>

      <div class="space-y-6">
        <!-- QR Code -->
        <div class="flex flex-col items-center gap-4">
          <div v-if="generating" class="size-48 flex items-center justify-center bg-neutral-50 dark:bg-neutral-800 rounded-2xl">
            <UIcon name="i-lucide-loader-2" class="size-8 animate-spin text-primary-500" />
          </div>
          <div v-else-if="qrDataUrl" class="p-3 bg-white rounded-2xl shadow-sm border border-neutral-200 dark:border-neutral-700">
            <img :src="qrDataUrl" alt="QR code for menu" class="size-48 rounded-xl" />
          </div>

          <div class="flex gap-2">
            <UButton
              icon="i-lucide-download"
              color="neutral"
              variant="outline"
              :disabled="!qrDataUrl"
              @click="downloadQr"
            >
              Download PNG
            </UButton>
            <UButton
              icon="i-lucide-refresh-cw"
              color="neutral"
              variant="ghost"
              :loading="generating"
              @click="generateQr"
            >
              Regenerate
            </UButton>
          </div>
        </div>

        <!-- Public URL -->
        <div>
          <p class="text-sm font-medium text-neutral-700 dark:text-neutral-300 mb-2">Public menu URL</p>
          <div class="flex items-center gap-2">
            <UInput
              :model-value="menuUrl"
              readonly
              class="flex-1 font-mono text-sm"
            />
            <UButton
              icon="i-lucide-copy"
              color="neutral"
              variant="outline"
              aria-label="Copy URL"
              @click="copyUrl"
            />
            <UButton
              :to="menuUrl"
              target="_blank"
              icon="i-lucide-external-link"
              color="neutral"
              variant="outline"
              aria-label="Open menu"
            />
          </div>
        </div>

        <!-- NFC hint -->
        <UAlert
          icon="i-lucide-wifi"
          color="info"
          variant="subtle"
          title="NFC tags"
          description="Program any NFC tag with the public URL above. Customers can tap to open the menu instantly."
        />

        <!-- Publish warning -->
        <UAlert
          v-if="!restaurant?.is_published"
          icon="i-lucide-alert-triangle"
          color="warning"
          variant="subtle"
          title="Menu not published"
          description="Your menu is currently in draft mode. Go to the Profile tab and toggle Published to make it visible to customers."
        />
      </div>
    </UCard>
  </div>
</template>
