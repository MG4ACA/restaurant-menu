export default defineNuxtRouteMiddleware(async () => {
  const { user, loading, init } = useAuth()

  // Initialize auth state if not done yet
  if (loading.value) {
    await init()
  }

  if (!user.value) {
    return navigateTo('/login')
  }
})
