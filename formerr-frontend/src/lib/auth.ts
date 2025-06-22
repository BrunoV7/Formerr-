// Função para obter o token do cookie
export function getAuthToken(): string | null {
  if (typeof window === 'undefined') return null;
  
  const cookies = document.cookie.split(';');
  const tokenCookie = cookies.find(cookie => 
    cookie.trim().startsWith('auth_token=')
  );
  
  if (!tokenCookie) return null;
  
  return tokenCookie.split('=')[1];
}

// Função para remover o token (logout)
export function removeAuthToken(): void {
  if (typeof window === 'undefined') return;
  
  document.cookie = 'auth_token=; path=/; expires=Thu, 01 Jan 1970 00:00:00 GMT';
}

// Função para verificar se o usuário está autenticado
export function isAuthenticated(): boolean {
  return getAuthToken() !== null;
}

// Headers padrão para requisições autenticadas
export function getAuthHeaders(): HeadersInit {
  const token = getAuthToken();
  
  if (!token) {
    throw new Error('Token de autenticação não encontrado');
  }
  
  return {
    'Authorization': `Bearer ${token}`,
    'Content-Type': 'application/json',
  };
}
