import type { Restaurant, Category, MenuItem } from '~/types'

export function useRestaurant() {
  const supabase = useSupabase()
  const { user } = useAuth()

  const restaurant = useState<Restaurant | null>('restaurant', () => null)
  const categories = useState<Category[]>('categories', () => [])
  const menuItems = useState<MenuItem[]>('menu_items', () => [])
  const loading = useState('restaurant_loading', () => false)
  const error = useState<string | null>('restaurant_error', () => null)

  // ---- Restaurant ----

  async function fetchRestaurant() {
    if (!user.value) return
    loading.value = true
    error.value = null
    const { data, error: err } = await supabase
      .from('restaurants')
      .select('*')
      .eq('owner_id', user.value.id)
      .maybeSingle()

    if (err) {
      error.value = err.message
    } else {
      restaurant.value = data
    }
    loading.value = false
  }

  async function createRestaurant(form: { name: string; slug: string; description?: string; phone?: string; address?: string; is_published?: boolean }) {
    if (!user.value) throw new Error('Not authenticated')
    const { data, error: err } = await supabase
      .from('restaurants')
      .insert({ ...form, is_published: form.is_published ?? true, owner_id: user.value.id })
      .select()
      .single()

    if (err) throw err
    restaurant.value = data
    return data
  }

  async function updateRestaurant(updates: Partial<Restaurant>) {
    if (!restaurant.value) throw new Error('No restaurant')
    const { data, error: err } = await supabase
      .from('restaurants')
      .update(updates)
      .eq('id', restaurant.value.id)
      .select()
      .single()

    if (err) throw err
    restaurant.value = data
    return data
  }

  async function togglePublished(published?: boolean) {
    if (!restaurant.value) throw new Error('No restaurant')
    const nextStatus = published !== undefined ? published : !restaurant.value.is_published
    return await updateRestaurant({ is_published: nextStatus })
  }

  // ---- Categories ----

  async function fetchCategories() {
    if (!restaurant.value) return
    const { data, error: err } = await supabase
      .from('categories')
      .select('*')
      .eq('restaurant_id', restaurant.value.id)
      .order('sort_order')

    if (err) {
      error.value = err.message
    } else {
      categories.value = data || []
    }
  }

  async function createCategory(name: string) {
    if (!restaurant.value) throw new Error('No restaurant')
    const maxOrder = categories.value.reduce((max, c) => Math.max(max, c.sort_order), -1)
    const { data, error: err } = await supabase
      .from('categories')
      .insert({
        restaurant_id: restaurant.value.id,
        name,
        sort_order: maxOrder + 1
      })
      .select()
      .single()

    if (err) throw err
    categories.value.push(data)
    return data
  }

  async function updateCategory(id: string, updates: Partial<Category>) {
    const { data, error: err } = await supabase
      .from('categories')
      .update(updates)
      .eq('id', id)
      .select()
      .single()

    if (err) throw err
    const idx = categories.value.findIndex(c => c.id === id)
    if (idx !== -1) categories.value[idx] = data
    return data
  }

  async function deleteCategory(id: string) {
    const { error: err } = await supabase
      .from('categories')
      .delete()
      .eq('id', id)

    if (err) throw err
    categories.value = categories.value.filter(c => c.id !== id)
    menuItems.value = menuItems.value.filter(i => i.category_id !== id)
  }

  // ---- Menu Items ----

  async function fetchMenuItems() {
    if (!restaurant.value) return
    const { data, error: err } = await supabase
      .from('menu_items')
      .select('*')
      .eq('restaurant_id', restaurant.value.id)
      .order('sort_order')

    if (err) {
      error.value = err.message
    } else {
      menuItems.value = data || []
    }
  }

  async function createMenuItem(form: { category_id: string; name: string; description?: string; price: number }) {
    if (!restaurant.value) throw new Error('No restaurant')
    const maxOrder = menuItems.value
      .filter(i => i.category_id === form.category_id)
      .reduce((max, i) => Math.max(max, i.sort_order), -1)

    const { data, error: err } = await supabase
      .from('menu_items')
      .insert({
        restaurant_id: restaurant.value.id,
        ...form,
        sort_order: maxOrder + 1
      })
      .select()
      .single()

    if (err) throw err
    menuItems.value.push(data)
    return data
  }

  async function updateMenuItem(id: string, updates: Partial<MenuItem>) {
    const { data, error: err } = await supabase
      .from('menu_items')
      .update(updates)
      .eq('id', id)
      .select()
      .single()

    if (err) throw err
    const idx = menuItems.value.findIndex(i => i.id === id)
    if (idx !== -1) menuItems.value[idx] = data
    return data
  }

  async function deleteMenuItem(id: string) {
    // Delete photo from storage if exists
    const item = menuItems.value.find(i => i.id === id)
    if (item?.photo_path) {
      await supabase.storage.from('menu-photos').remove([item.photo_path])
    }

    const { error: err } = await supabase
      .from('menu_items')
      .delete()
      .eq('id', id)

    if (err) throw err
    menuItems.value = menuItems.value.filter(i => i.id !== id)
  }

  // ---- Photos ----

  async function uploadPhoto(itemId: string, file: File) {
    if (!user.value || !restaurant.value) throw new Error('Not authenticated')
    const ext = file.name.split('.').pop()
    const path = `${user.value.id}/${restaurant.value.id}/${itemId}.${ext}`

    // Remove old photo if exists
    const item = menuItems.value.find(i => i.id === itemId)
    if (item?.photo_path) {
      await supabase.storage.from('menu-photos').remove([item.photo_path])
    }

    const { error: uploadErr } = await supabase.storage
      .from('menu-photos')
      .upload(path, file, { upsert: true })

    if (uploadErr) throw uploadErr

    // Update menu item with photo path
    await updateMenuItem(itemId, { photo_path: path })
    return path
  }

  async function removePhoto(itemId: string) {
    const item = menuItems.value.find(i => i.id === itemId)
    if (!item?.photo_path) return

    await supabase.storage.from('menu-photos').remove([item.photo_path])
    await updateMenuItem(itemId, { photo_path: null })
  }

  function getPhotoUrl(path: string) {
    const { data } = supabase.storage.from('menu-photos').getPublicUrl(path)
    return data.publicUrl
  }

  return {
    restaurant,
    categories,
    menuItems,
    loading,
    error,
    fetchRestaurant,
    createRestaurant,
    updateRestaurant,
    togglePublished,
    fetchCategories,
    createCategory,
    updateCategory,
    deleteCategory,
    fetchMenuItems,
    createMenuItem,
    updateMenuItem,
    deleteMenuItem,
    uploadPhoto,
    removePhoto,
    getPhotoUrl
  }
}
