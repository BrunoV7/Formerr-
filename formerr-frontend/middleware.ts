import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

export function middleware(request: NextRequest) {
  // Verifica se a rota começa com /v1/ (rotas protegidas)
  if (request.nextUrl.pathname.startsWith('/v1/')) {
    // Verifica se existe token de autenticação
    const token = request.cookies.get('auth_token')?.value;
    
    if (!token) {
      // Se não há token, redireciona para login
      const loginUrl = new URL('/login', request.url);
      loginUrl.searchParams.set('redirect', request.nextUrl.pathname);
      return NextResponse.redirect(loginUrl);
    }
    
    // TODO: Aqui podemos adicionar validação adicional do token se necessário
    // Por enquanto, apenas verificamos se existe
  }
  
  return NextResponse.next();
}

export const config = {
  // Aplica o middleware apenas para rotas que começam com /v1/
  matcher: '/v1/:path*'
};
