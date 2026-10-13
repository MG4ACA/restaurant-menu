<script setup lang="ts">
import type { Category, MenuItem } from '~/types'

const {
  restaurant,
  categories,
  menuItems,
  createCategory,
  updateCategory,
  deleteCategory,
  fetchCategories,
  fetchMenuItems
} = useRestaurant()

const toast = useToast()

// ---- Category state ----
const newCategoryName = ref('')
const addingCategory = ref(false)
const editingCategory = ref<Category | null>(null)
const editCategoryName = ref('')

// ---- Item modal state ----
const showItemModal = ref(false)
const editingItem = ref<MenuItem | null>(null)
const itemModalCategory = ref<string>('')

function itemsForCategory(categoryId: string) {
  return menuItems.value.filter(i => i.category_id === categoryId)
}

async function handleAddCategory() {
  if (!newCategoryName.value.trim()) return
  addingCategory.value = true
  try {
    await createCategory(newCategoryName.value.trim())
    newCategoryName.value = ''
    toast.add({ title: 'Category added', color: 'success' })
  } catch (err: unknown) {
    toast.add({ title: 'Failed to add category', description: (err as Error).message, color: 'error' })
  } finally {
    addingCategory.value = false
  }
}

function startEditCategory(cat: Category) {
  editingCategory.value = cat
  editCategoryName.value = cat.name
}

async function saveEditCategory() {
  if (!editingCategory.value || !editCategoryName.value.trim()) return
  try {
    await updateCategory(editingCategory.value.id, { name: editCategoryName.value.trim() })
    editingCategory.value = null
    toast.add({ title: 'Category updated', color: 'success' })
  } catch (err: unknown) {
    toast.add({ title: 'Failed to update', description: (err as Error).message, color: 'error' })
  }
}

async function handleDeleteCategory(cat: Category) {
  const count = itemsForCategory(cat.id).length
  if (count > 0) {
    toast.add({
      title: 'Cannot delete',
      description: `Move or delete the ${count} item(s) in this category first.`,
      color: 'warning'
    })
    return
  }
  try {
    await deleteCategory(cat.id)
    toast.add({ title: 'Category deleted', color: 'success' })
  } catch (err: unknown) {
    toast.add({ title: 'Failed to delete', description: (err as Error).message, color: 'error' })
  }
}

function openAddItem(categoryId: string) {
  editingItem.value = null
  itemModalCategory.value = categoryId
  showItemModal.value = true
}

function openEditItem(item: MenuItem) {
  editingItem.value = item
  itemModalCategory.value = item.category_id
  showItemModal.value = true
}

function handleItemSaved() {
  showItemModal.value = false
}
</script>

<template>
  <div class="space-y-6">
    <!-- Empty state: no categories -->
    <div v-if="categories.length === 0" class="text-center py-12 border-2 border-dashed border-neutral-200 dark:border-neutral-700 rounded-2xl">
      <UIcon name="i-lucide-layout-list" class="size-10 text-neutral-300 dark:text-neutral-600 mx-auto mb-3" />
      <p class="text-neutral-500 dark:text-neutral-400 font-medium mb-1">No categories yet</p>
      <p class="text-sm text-neutral-400 dark:text-neutral-500">Add your first category to start building your menu</p>
    </div>

    <!-- Category sections -->
    <div
      v-for="cat in categories"
      :key="cat.id"
      class="bg-white dark:bg-neutral-900 border border-neutral-200 dark:border-neutral-800 rounded-2xl overflow-hidden"
    >
      <!-- Category header -->
      <div class="flex items-center justify-between px-5 py-4 border-b border-neutral-100 dark:border-neutral-800 bg-neutral-50 dark:bg-neutral-800/50">
        <div v-if="editingCategory?.id === cat.id" class="flex items-center gap-2 flex-1">
          <UInput
            v-model="editCategoryName"
            id="edit-category-name"
            class="max-w-xs"
            @keyup.enter="saveEditCategory"
            @keyup.escape="editingCategory = null"
          />
          <UButton size="xs" icon="i-lucide-check" @click="saveEditCategory" />
          <UButton size="xs" icon="i-lucide-x" color="neutral" variant="ghost" @click="editingCategory = null" />
        </div>
        <h3 v-else class="font-semibold text-neutral-900 dark:text-white">{{ cat.name }}</h3>

        <div v-if="editingCategory?.id !== cat.id" class="flex items-center gap-1">
          <UButton
            size="xs"
            icon="i-lucide-pencil"
            color="neutral"
            variant="ghost"
            aria-label="Edit category"
            @click="startEditCategory(cat)"
          />
          <UButton
            size="xs"
            icon="i-lucide-trash-2"
            color="error"
            variant="ghost"
            aria-label="Delete category"
            @click="handleDeleteCategory(cat)"
          />
        </div>
      </div>

      <!-- Items list -->
      <div class="divide-y divide-neutral-100 dark:divide-neutral-800">
        <DashboardMenuItemRow
          v-for="item in itemsForCategory(cat.id)"
          :key="item.id"
          :item="item"
          @edit="openEditItem(item)"
        />

        <!-- Empty category -->
        <div v-if="itemsForCategory(cat.id).length === 0" class="px-5 py-4 text-sm text-neutral-400 dark:text-neutral-500 italic">
          No items yet in this category
        </div>
      </div>

      <!-- Add item button -->
      <div class="px-5 py-3 border-t border-neutral-100 dark:border-neutral-800">
        <UButton
          icon="i-lucide-plus"
          size="sm"
          color="neutral"
          variant="ghost"
          @click="openAddItem(cat.id)"
        >
          Add item
        </UButton>
      </div>
    </div>

    <!-- Add category form -->
    <div class="flex items-center gap-3">
      <UInput
        v-model="newCategoryName"
        id="new-category-name"
        placeholder="New category name (e.g. Starters, Mains, Beverages)"
        class="flex-1"
        :disabled="addingCategory"
        @keyup.enter="handleAddCategory"
      />
      <UButton
        icon="i-lucide-plus"
        :loading="addingCategory"
        :disabled="!newCategoryName.trim() || addingCategory"
        @click="handleAddCategory"
      >
        Add category
      </UButton>
    </div>

    <!-- Item modal -->
    <DashboardMenuItemModal
      v-model:open="showItemModal"
      :item="editingItem"
      :category-id="itemModalCategory"
      @saved="handleItemSaved"
    />
  </div>
</template>
