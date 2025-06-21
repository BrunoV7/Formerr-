'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { authService, dashboardService } from '@/services/api';
import { User, DashboardStats } from '@/types';
import Cookies from 'js-cookie';

export default function DashboardPage() {
  const router = useRouter();
  const [user, setUser] = useState<User | null>(null);
  const [stats, setStats] = useState<DashboardStats | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const loadData = async () => {
      try {
        // Verifica se tem token
        const token = Cookies.get('auth_token');
        if (!token) {
          router.push('/login');
          return;
        }

        // Busca dados do usuário e estatísticas
        const [userData, statsData] = await Promise.all([
          authService.getCurrentUser(),
          dashboardService.getStats()
        ]);

        setUser(userData);
        setStats(statsData);
      } catch (error) {
        console.error('Erro ao carregar dados:', error);
        // Se der erro de auth, remove o token e vai para login
        Cookies.remove('auth_token');
        router.push('/login');
      } finally {
        setLoading(false);
      }
    };

    loadData();
  }, [router]);

  const handleLogout = () => {
    Cookies.remove('auth_token');
    router.push('/');
  };

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-xl">Carregando...</div>
      </div>
    );
  }

  if (!user || !stats) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-xl">Erro ao carregar dados</div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <header className="bg-white shadow-sm border-b">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center py-4">
            <h1 className="text-2xl font-bold text-gray-800">Dashboard</h1>
            <div className="flex items-center gap-4">
              <div className="flex items-center gap-2">
                <img 
                  src={user.avatar_url} 
                  alt={user.name} 
                  className="w-8 h-8 rounded-full"
                />
                <span className="text-sm text-gray-600">{user.name}</span>
              </div>
              <button
                onClick={handleLogout}
                className="px-4 py-2 text-sm bg-red-600 text-white rounded hover:bg-red-700"
              >
                Sair
              </button>
            </div>
          </div>
        </div>
      </header>

      {/* Conteúdo */}
      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Estatísticas */}
        <div className="grid grid-cols-1 md:grid-cols-4 gap-6 mb-8">
          <div className="bg-white p-6 rounded-lg shadow">
            <h3 className="text-sm font-medium text-gray-500">Total de Formulários</h3>
            <p className="text-3xl font-bold text-blue-600">{stats.total_forms}</p>
          </div>
          <div className="bg-white p-6 rounded-lg shadow">
            <h3 className="text-sm font-medium text-gray-500">Formulários Ativos</h3>
            <p className="text-3xl font-bold text-green-600">{stats.active_forms}</p>
          </div>
          <div className="bg-white p-6 rounded-lg shadow">
            <h3 className="text-sm font-medium text-gray-500">Total de Respostas</h3>
            <p className="text-3xl font-bold text-purple-600">{stats.total_responses}</p>
          </div>
          <div className="bg-white p-6 rounded-lg shadow">
            <h3 className="text-sm font-medium text-gray-500">Taxa Média</h3>
            <p className="text-3xl font-bold text-orange-600">{stats.avg_response_rate}</p>
          </div>
        </div>

        {/* Formulário mais popular */}
        {stats.most_popular_form && (
          <div className="bg-white p-6 rounded-lg shadow mb-8">
            <h3 className="text-lg font-medium text-gray-800 mb-4">Formulário Mais Popular</h3>
            <div className="flex justify-between items-center">
              <div>
                <h4 className="font-medium text-gray-900">{stats.most_popular_form.title}</h4>
                <p className="text-sm text-gray-500">ID: {stats.most_popular_form.id}</p>
              </div>
              <div className="text-right">
                <p className="text-2xl font-bold text-blue-600">{stats.most_popular_form.response_count}</p>
                <p className="text-sm text-gray-500">respostas</p>
              </div>
            </div>
          </div>
        )}

        {/* Informações do usuário */}
        <div className="bg-white p-6 rounded-lg shadow">
          <h3 className="text-lg font-medium text-gray-800 mb-4">Informações da Conta</h3>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <p className="text-sm text-gray-500">Nome de usuário</p>
              <p className="font-medium">{user.username}</p>
            </div>
            <div>
              <p className="text-sm text-gray-500">Email</p>
              <p className="font-medium">{user.email}</p>
            </div>
            <div>
              <p className="text-sm text-gray-500">Plano</p>
              <p className="font-medium capitalize">{user.role}</p>
            </div>
            <div>
              <p className="text-sm text-gray-500">Limite de Formulários</p>
              <p className="font-medium">{user.limits.max_forms}</p>
            </div>
          </div>
        </div>
      </main>
    </div>
  );
}
