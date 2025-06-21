'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { authService, dashboardService } from '@/services/api';
import { User, DashboardStats, Form } from '@/types';
import Cookies from 'js-cookie';

export default function V1DashboardPage() {
  const router = useRouter();
  const [user, setUser] = useState<User | null>(null);
  const [stats, setStats] = useState<DashboardStats | null>(null);
  const [forms, setForms] = useState<Form[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const loadData = async () => {
      try {
        // Busca dados do usuário, estatísticas e formulários em paralelo
        const [userData, statsData, formsData] = await Promise.all([
          authService.getCurrentUser(),
          dashboardService.getStats(),
          dashboardService.getForms()
        ]);

        setUser(userData);
        setStats(statsData);
        setForms(formsData);
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

  // Função para saudação baseada no horário
  const getGreeting = () => {
    const hour = new Date().getHours();
    if (hour < 12) return 'Bom dia';
    if (hour < 18) return 'Boa tarde';
    return 'Boa noite';
  };

  // Função para pegar o primeiro nome
  const getFirstName = (fullName: string) => {
    if (!fullName) return 'Usuário';
    return fullName.split(' ')[0];
  };

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-50">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto mb-4"></div>
          <div className="text-xl text-gray-600">Carregando dados...</div>
        </div>
      </div>
    );
  }

  if (!user) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-50">
        <div className="text-center">
          <div className="text-xl text-red-600 mb-2">Erro ao carregar dados do usuário</div>
          <button 
            onClick={() => window.location.reload()} 
            className="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700"
          >
            Tentar Novamente
          </button>
        </div>
      </div>
    );
  }

  if (!stats) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-50">
        <div className="text-center">
          <div className="text-xl text-red-600 mb-2">Erro ao carregar estatísticas</div>
          <button 
            onClick={() => window.location.reload()} 
            className="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700"
          >
            Tentar Novamente
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <header className="bg-white shadow-sm border-b">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center py-4">
            <div className="flex items-center gap-4">
              <h1 className="text-2xl font-bold text-gray-800">Dashboard</h1>
              <span className="px-3 py-1 bg-gradient-to-r from-blue-100 to-green-100 text-blue-800 text-sm rounded-full font-medium">
                {getGreeting()}, {getFirstName(user?.name || user?.username || '')}! 👋
              </span>
            </div>
            <div className="flex items-center gap-4">
              <div className="flex items-center gap-2">
                {user?.avatar_url ? (
                  <img 
                    src={user.avatar_url} 
                    alt={user.name || user.username || 'User'} 
                    className="w-8 h-8 rounded-full border border-gray-200"
                  />
                ) : (
                  <div className="w-8 h-8 bg-blue-500 rounded-full flex items-center justify-center text-white text-sm font-medium">
                    {getFirstName(user?.name || user?.username || 'U').charAt(0).toUpperCase()}
                  </div>
                )}
                <span className="text-sm text-gray-600">{getFirstName(user?.name || user?.username || 'Usuário')}</span>
              </div>
              <button
                onClick={handleLogout}
                className="px-4 py-2 text-sm bg-red-600 text-white rounded hover:bg-red-700 transition-colors"
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
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
          <div className="bg-white p-6 rounded-lg shadow">
            <div className="flex items-center">
              <div className="flex-shrink-0">
                <svg className="w-8 h-8 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                </svg>
              </div>
              <div className="ml-5 w-0 flex-1">
                <dl>
                  <dt className="text-sm font-medium text-gray-500 truncate">Total de Formulários</dt>
                  <dd className="text-lg font-medium text-gray-900">{stats.total_forms || 0}</dd>
                </dl>
              </div>
            </div>
          </div>

          <div className="bg-white p-6 rounded-lg shadow">
            <div className="flex items-center">
              <div className="flex-shrink-0">
                <svg className="w-8 h-8 text-green-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
              </div>
              <div className="ml-5 w-0 flex-1">
                <dl>
                  <dt className="text-sm font-medium text-gray-500 truncate">Formulários Ativos</dt>
                  <dd className="text-lg font-medium text-gray-900">{stats.active_forms || 0}</dd>
                </dl>
              </div>
            </div>
          </div>

          <div className="bg-white p-6 rounded-lg shadow">
            <div className="flex items-center">
              <div className="flex-shrink-0">
                <svg className="w-8 h-8 text-purple-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 8h2a2 2 0 012 2v6a2 2 0 01-2 2h-2v4l-4-4H9a1.994 1.994 0 01-1.414-.586m0 0L11 14h4a2 2 0 002-2V6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2v4l.586-.586z" />
                </svg>
              </div>
              <div className="ml-5 w-0 flex-1">
                <dl>
                  <dt className="text-sm font-medium text-gray-500 truncate">Total de Respostas</dt>
                  <dd className="text-lg font-medium text-gray-900">{stats.total_responses || 0}</dd>
                </dl>
              </div>
            </div>
          </div>

          <div className="bg-white p-6 rounded-lg shadow">
            <div className="flex items-center">
              <div className="flex-shrink-0">
                <svg className="w-8 h-8 text-orange-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 7h8m0 0v8m0-8l-8 8-4-4-6 6" />
                </svg>
              </div>
              <div className="ml-5 w-0 flex-1">
                <dl>
                  <dt className="text-sm font-medium text-gray-500 truncate">Taxa Média</dt>
                  <dd className="text-lg font-medium text-gray-900">{stats.avg_response_rate || 0}%</dd>
                </dl>
              </div>
            </div>
          </div>
        </div>

        {/* Métricas adicionais */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-8">
          <div className="bg-white p-6 rounded-lg shadow">
            <h3 className="text-lg font-medium text-gray-900 mb-4">Atividade Recente</h3>              <div className="space-y-3">
                <div className="flex justify-between">
                  <span className="text-sm text-gray-500">Respostas este mês</span>
                  <span className="text-sm font-medium">{stats.responses_this_month || 0}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-sm text-gray-500">Respostas esta semana</span>
                  <span className="text-sm font-medium">{stats.responses_this_week || 0}</span>
                </div>
              </div>
          </div>

          {stats.most_popular_form ? (
            <div className="bg-white p-6 rounded-lg shadow">
              <h3 className="text-lg font-medium text-gray-900 mb-4">Formulário Mais Popular</h3>
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
          ) : (
            <div className="bg-white p-6 rounded-lg shadow">
              <h3 className="text-lg font-medium text-gray-900 mb-4">Formulário Mais Popular</h3>
              <div className="text-center py-4">
                <p className="text-gray-500">Nenhum formulário com respostas ainda.</p>
                <p className="text-sm text-gray-400 mt-1">Crie um formulário e comece a coletar respostas!</p>
              </div>
            </div>
          )}
        </div>

        {/* Lista de Formulários */}
        <div className="bg-white rounded-lg shadow">
          <div className="px-6 py-4 border-b border-gray-200 flex justify-between items-center">
            <h3 className="text-lg font-medium text-gray-900">Seus Formulários</h3>
            <div className="flex gap-3">
              <button 
                onClick={() => router.push('/v1/forms')}
                className="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700 transition-colors text-sm"
              >
                Ver Todos os Formulários
              </button>
              <button className="px-4 py-2 bg-green-600 text-white rounded hover:bg-green-700 transition-colors text-sm">
                Criar Novo Formulário
              </button>
            </div>
          </div>
          <div className="divide-y divide-gray-200">
            {forms.length === 0 ? (
              <div className="px-6 py-8 text-center">
                <svg className="w-12 h-12 text-gray-400 mx-auto mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                </svg>
                <p className="text-gray-500">Você ainda não criou nenhum formulário.</p>
                <button className="mt-4 px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700 transition-colors">
                  Criar Primeiro Formulário
                </button>
              </div>
            ) : (
              forms.map((form) => (
                <div key={form.id} className="px-6 py-4 hover:bg-gray-50">
                  <div className="flex items-center justify-between">
                    <div className="flex items-center">
                      <div className={`w-4 h-4 rounded-full mr-3`} style={{ backgroundColor: form.folder_color }}></div>
                      <div>
                        <h4 className="text-sm font-medium text-gray-900">{form.title}</h4>
                        <p className="text-sm text-gray-500">{form.description}</p>
                      </div>
                    </div>
                    <div className="flex items-center space-x-4">
                      <div className="text-sm text-gray-500">
                        <span className={`inline-flex px-2 py-1 text-xs font-semibold rounded-full ${
                          form.status === 'public' ? 'bg-green-100 text-green-800' :
                          form.status === 'draft' ? 'bg-gray-100 text-gray-800' :
                          form.status === 'private' ? 'bg-blue-100 text-blue-800' :
                          'bg-red-100 text-red-800'
                        }`}>
                          {form.status}
                        </span>
                      </div>
                      <div className="text-sm text-gray-500">
                        {form.total_responses} respostas
                      </div>
                      <div className="text-sm text-gray-400">
                        {new Date(form.created_at).toLocaleDateString('pt-BR')}
                      </div>
                    </div>
                  </div>
                </div>
              ))
            )}
          </div>
        </div>

        {/* Informações do usuário */}
        <div className="mt-8 bg-white p-6 rounded-lg shadow">
          <div className="flex items-center mb-6">
            <img 
              src={user.avatar_url} 
              alt={user.name || user.username} 
              className="w-16 h-16 rounded-full border-2 border-gray-200 mr-4"
            />
            <div>
              <h3 className="text-xl font-medium text-gray-800">{user.name || user.username}</h3>
              <p className="text-gray-600">@{user.username}</p>
              <a 
                href={user.github_url} 
                target="_blank" 
                rel="noopener noreferrer"
                className="text-blue-600 hover:text-blue-800 text-sm flex items-center gap-1 mt-1"
              >
                <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
                  <path fillRule="evenodd" d="M10 0C4.477 0 0 4.484 0 10.017c0 4.425 2.865 8.18 6.839 9.504.5.092.682-.217.682-.483 0-.237-.008-.868-.013-1.703-2.782.605-3.369-1.343-3.369-1.343-.454-1.158-1.11-1.466-1.11-1.466-.908-.62.069-.608.069-.608 1.003.07 1.531 1.032 1.531 1.032.892 1.53 2.341 1.088 2.91.832.092-.647.35-1.088.636-1.338-2.22-.253-4.555-1.113-4.555-4.951 0-1.093.39-1.988 1.029-2.688-.103-.253-.446-1.272.098-2.65 0 0 .84-.27 2.75 1.026A9.564 9.564 0 0110 4.844c.85.004 1.705.115 2.504.337 1.909-1.296 2.747-1.027 2.747-1.027.546 1.379.203 2.398.1 2.651.64.7 1.028 1.595 1.028 2.688 0 3.848-2.339 4.695-4.566 4.942.359.31.678.921.678 1.856 0 1.338-.012 2.419-.012 2.747 0 .268.18.58.688.482A10.019 10.019 0 0020 10.017C20 4.484 15.522 0 10 0z" clipRule="evenodd" />
                </svg>
                Ver perfil no GitHub
              </a>
            </div>
          </div>
          
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
            <div className="bg-gray-50 p-4 rounded-lg">
              <p className="text-sm text-gray-500 mb-1">Email</p>
              <p className="font-medium text-gray-900">{user.email || 'N/A'}</p>
            </div>
            <div className="bg-gray-50 p-4 rounded-lg">
              <p className="text-sm text-gray-500 mb-1">Plano</p>
              <span className={`inline-flex px-2 py-1 text-xs font-semibold rounded-full ${
                user.role === 'premium' ? 'bg-purple-100 text-purple-800' :
                user.role === 'free' ? 'bg-green-100 text-green-800' :
                'bg-gray-100 text-gray-800'
              }`}>
                {user.role?.toUpperCase() || 'N/A'}
              </span>
            </div>
            <div className="bg-gray-50 p-4 rounded-lg">
              <p className="text-sm text-gray-500 mb-1">Limite de Formulários</p>
              <p className="font-medium text-gray-900">{user.limits?.max_forms || 'N/A'}</p>
            </div>
            <div className="bg-gray-50 p-4 rounded-lg">
              <p className="text-sm text-gray-500 mb-1">Membro desde</p>
              <p className="font-medium text-gray-900">
                {user.created_at ? new Date(user.created_at).toLocaleDateString('pt-BR') : 'N/A'}
              </p>
            </div>
          </div>

          {/* Limites adicionais */}
          {user.limits && (
            <div className="mt-6 pt-6 border-t border-gray-200">
              <h4 className="text-md font-medium text-gray-800 mb-4">Limites do Plano</h4>
              <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                <div className="text-center p-3 bg-blue-50 rounded-lg">
                  <p className="text-2xl font-bold text-blue-600">{user.limits.max_submissions_per_month}</p>
                  <p className="text-sm text-blue-700">Respostas/mês</p>
                </div>
                <div className="text-center p-3 bg-green-50 rounded-lg">
                  <p className="text-2xl font-bold text-green-600">{user.limits.max_questions_per_form}</p>
                  <p className="text-sm text-green-700">Perguntas/formulário</p>
                </div>
                <div className="text-center p-3 bg-purple-50 rounded-lg">
                  <p className="text-2xl font-bold text-purple-600">{user.limits.max_file_size_mb}MB</p>
                  <p className="text-sm text-purple-700">Tamanho máximo de arquivo</p>
                </div>
              </div>
            </div>
          )}
        </div>
      </main>
    </div>
  );
}
