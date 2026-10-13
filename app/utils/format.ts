/**
 * Format a price in LKR (Sri Lankan Rupees)
 * e.g. 1250 => "Rs. 1,250"
 */
export function formatPrice(price: number): string {
  return `Rs. ${price.toLocaleString('en-LK')}`
}

/**
 * Generate a URL-safe slug from a string
 */
export function slugify(text: string): string {
  return text
    .toLowerCase()
    .trim()
    .replace(/[^\w\s-]/g, '')
    .replace(/[\s_]+/g, '-')
    .replace(/^-+|-+$/g, '')
}
