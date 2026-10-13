export interface Restaurant {
  id: string
  owner_id: string
  name: string
  slug: string
  description: string | null
  phone: string | null
  address: string | null
  is_published: boolean
  created_at: string
  updated_at: string
}

export interface Category {
  id: string
  restaurant_id: string
  name: string
  sort_order: number
  created_at: string
}

export interface MenuItem {
  id: string
  restaurant_id: string
  category_id: string
  name: string
  description: string | null
  price: number // in LKR whole rupees
  photo_path: string | null
  is_available: boolean
  sort_order: number
  created_at: string
  updated_at: string
}
