'use client';

import { useEffect } from 'react';
import { useRouter } from 'next/navigation';
import Cookies from 'js-cookie';

export default function AuthSuccessPage() {
  const router = useRouter();

  useEffect(() => {
    // Verifica se há um token na URL (retorno do OAuth)
    const urlParams = new URLSearchParams(window.location.search);
    const token = urlParams.get('token');
    
    if (token) {
      // Salva o token no cookie
      Cookies.set('auth_token', token, { 
        expires: 30, // 30 dias
        path: '/',
        secure: process.env.NODE_ENV === 'production',
        sameSite: 'lax'
      });
      
      console.log('✅ Token salvo com sucesso');
      
      // Redireciona para o dashboard
      router.push('/v1/dashboard');
    } else {
      console.error('❌ Token não encontrado na URL');
      // Se não há token, vai para página de erro ou login
      router.push('/auth/error');
    }
  }, [router]);

  return (
    <div className="min-h-screen flex flex-col items-center justify-center bg-gray-50">
      <div className="max-w-md w-full bg-white p-8 rounded-lg shadow-md text-center">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto mb-4"></div>
        <h1 className="text-xl font-semibold text-gray-800 mb-2">
          Finalizando login...
        </h1>
        <p className="text-gray-600">
          Você será redirecionado em instantes.
        </p>
      </div>
    </div>
  );
}
