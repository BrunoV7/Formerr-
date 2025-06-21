'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';

export default function AuthErrorPage() {
  const router = useRouter();
  const [errorReason, setErrorReason] = useState<string>('');

  useEffect(() => {
    const urlParams = new URLSearchParams(window.location.search);
    const reason = urlParams.get('reason');
    setErrorReason(reason || 'unknown');
  }, []);

  const getErrorMessage = (reason: string) => {
    switch (reason) {
      case 'oauth_failed':
        return 'Falha na autenticação com GitHub. Tente novamente.';
      case 'token_invalid':
        return 'Token inválido ou expirado.';
      case 'user_denied':
        return 'Acesso negado pelo usuário.';
      default:
        return 'Ocorreu um erro durante o login.';
    }
  };

  return (
    <div className="min-h-screen flex flex-col items-center justify-center bg-gray-50">
      <div className="max-w-md w-full bg-white p-8 rounded-lg shadow-md text-center">
        <div className="w-16 h-16 bg-red-100 rounded-full flex items-center justify-center mx-auto mb-4">
          <svg className="w-8 h-8 text-red-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
          </svg>
        </div>
        
        <h1 className="text-xl font-semibold text-gray-800 mb-2">
          Erro no Login
        </h1>
        
        <p className="text-gray-600 mb-6">
          {getErrorMessage(errorReason)}
        </p>
        
        <div className="space-y-3">
          <Link 
            href="/login"
            className="w-full bg-blue-600 text-white py-3 px-4 rounded-md text-center block hover:bg-blue-700 transition-colors"
          >
            Tentar Novamente
          </Link>
          
          <Link 
            href="/"
            className="w-full bg-gray-100 text-gray-700 py-3 px-4 rounded-md text-center block hover:bg-gray-200 transition-colors"
          >
            Voltar ao Início
          </Link>
        </div>
        
        {errorReason && (
          <p className="text-xs text-gray-400 mt-4">
            Código do erro: {errorReason}
          </p>
        )}
      </div>
    </div>
  );
}
