'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { authService, dashboardService } from '@/services/api';
import { User, DashboardStats, Form } from '@/types';
import { Popover, PopoverItem, PopoverSeparator } from '@/components/ui/popover';
import Cookies from 'js-cookie';

export default function FormsPage() {
  const router = useRouter();
  const [user, setUser] = useState<User | null>(null);
  const [stats, setStats] = useState<DashboardStats | null>(null);
  const [forms, setForms] = useState<Form[]>([]);
  const [filteredForms, setFilteredForms] = useState<Form[]>([]);
  const [loading, setLoading] = useState(true);
  
  // Estados para filtros
  const [statusFilter, setStatusFilter] = useState<string>('all');
  const [periodFilter, setPeriodFilter] = useState<string>('all');
  const [sortBy, setSortBy] = useState<string>('created_at');
  
  // Estado para controlar qual popover está aberto
  const [openPopover, setOpenPopover] = useState<string | null>(null);

  // Estados para feedback de ações
  const [isDeleting, setIsDeleting] = useState<string | null>(null);
  const [copyFeedback, setCopyFeedback] = useState<string | null>(null);

  // Funções de ação dos formulários
  const handleCopyLink = async (formId: string, formTitle: string) => {
    try {
      const formUrl = `${window.location.origin}/form/${formId}`;
      await navigator.clipboard.writeText(formUrl);
      setCopyFeedback(formId);
      setOpenPopover(null);
      
      // Remove o feedback após 2 segundos
      setTimeout(() => setCopyFeedback(null), 2000);
    } catch (error) {
      console.error('Erro ao copiar link:', error);
      // Fallback para navegadores que não suportam clipboard API
      const textArea = document.createElement('textarea');
      textArea.value = `${window.location.origin}/form/${formId}`;
      document.body.appendChild(textArea);
      textArea.select();
      document.execCommand('copy');
      document.body.removeChild(textArea);
      
      setCopyFeedback(formId);
      setOpenPopover(null);
      setTimeout(() => setCopyFeedback(null), 2000);
    }
  };

  const handleEditForm = (formId: string) => {
    setOpenPopover(null);
    router.push(`/v1/forms/${formId}/edit`);
  };

  const handleViewResponses = (formId: string) => {
    setOpenPopover(null);
    router.push(`/v1/forms/${formId}/responses`);
  };

  const handleDeleteForm = async (formId: string, formTitle: string) => {
    if (!confirm(`Tem certeza que deseja excluir o formulário "${formTitle}"? Esta ação não pode ser desfeita.`)) {
      return;
    }

    setIsDeleting(formId);
    setOpenPopover(null);

    try {
      // Chama a API para deletar o formulário
      await dashboardService.deleteForm(formId);
      
      // Remove da lista local
      const updatedForms = forms.filter(form => form.id !== formId);
      setForms(updatedForms);
      
      // Aplicar filtros aos formulários atualizados
      let filtered = [...updatedForms];
      
      // Aplicar filtro de status
      if (statusFilter !== 'all') {
        filtered = filtered.filter(form => form.status === statusFilter);
      }
      
      // Aplicar filtro de período
      if (periodFilter !== 'all') {
        const now = new Date();
        
        switch (periodFilter) {
          case 'today':
            filtered = filtered.filter(form => {
              const fDate = new Date(form.created_at);
              return fDate.toDateString() === now.toDateString();
            });
            break;
          case 'week':
            const weekAgo = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
            filtered = filtered.filter(form => new Date(form.created_at) >= weekAgo);
            break;
          case 'month':
            const monthAgo = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
            filtered = filtered.filter(form => new Date(form.created_at) >= monthAgo);
            break;
          case 'year':
            const yearAgo = new Date(now.getTime() - 365 * 24 * 60 * 60 * 1000);
            filtered = filtered.filter(form => new Date(form.created_at) >= yearAgo);
            break;
        }
      }
      
      setFilteredForms(filtered);
      
      // Atualizar as estatísticas
      if (stats) {
        setStats({
          ...stats,
          total_forms: stats.total_forms - 1
        });
      }
    } catch (error) {
      console.error('Erro ao excluir formulário:', error);
      alert('Erro ao excluir formulário. Tente novamente.');
    } finally {
      setIsDeleting(null);
    }
  };

  const handleCreateForm = () => {
    router.push('/v1/forms/create');
  };

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
        setFilteredForms(formsData);
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

  // Função para pegar primeiro nome
  const getFirstName = (name: string) => {
    return name ? name.split(' ')[0] : 'Usuário';
  };

  // Função para calcular estatísticas filtradas
  const getFilteredStats = () => {
    const activeForms = filteredForms.filter(form => form.status === 'public').length;
    const totalResponses = filteredForms.reduce((sum, form) => sum + form.total_responses, 0);
    
    return {
      active_forms: activeForms,
      total_responses: totalResponses,
      total_forms: filteredForms.length
    };
  };
  useEffect(() => {
    if (!forms.length) return;

    let filtered = [...forms];

    // Filtro por status
    if (statusFilter !== 'all') {
      filtered = filtered.filter(form => form.status === statusFilter);
    }

    // Filtro por período
    if (periodFilter !== 'all') {
      const now = new Date();
      const filterDate = new Date();
      
      switch (periodFilter) {
        case 'today':
          filterDate.setHours(0, 0, 0, 0);
          break;
        case 'week':
          filterDate.setDate(now.getDate() - 7);
          break;
        case 'month':
          filterDate.setDate(now.getDate() - 30);
          break;
        case 'year':
          filterDate.setDate(now.getDate() - 365);
          break;
      }
      
      if (periodFilter !== 'all') {
        filtered = filtered.filter(form => new Date(form.created_at) >= filterDate);
      }
    }

    // Ordenação
    filtered.sort((a, b) => {
      switch (sortBy) {
        case 'title':
          return a.title.localeCompare(b.title);
        case 'responses':
          return b.total_responses - a.total_responses;
        case 'status':
          return a.status.localeCompare(b.status);
        case 'created_at':
        default:
          return new Date(b.created_at).getTime() - new Date(a.created_at).getTime();
      }
    });

    setFilteredForms(filtered);
  }, [forms, statusFilter, periodFilter, sortBy]);

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'public': return 'bg-green-100 text-green-800';
      case 'draft': return 'bg-gray-100 text-gray-800';
      case 'private': return 'bg-blue-100 text-blue-800';
      case 'archived': return 'bg-red-100 text-red-800';
      case 'closed': return 'bg-orange-100 text-orange-800';
      default: return 'bg-gray-100 text-gray-800';
    }
  };

  const getStatusText = (status: string) => {
    switch (status) {
      case 'public': return 'Público';
      case 'draft': return 'Rascunho';
      case 'private': return 'Privado';
      case 'archived': return 'Arquivado';
      case 'closed': return 'Fechado';
      default: return status;
    }
  };

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-50">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto mb-4"></div>
          <div className="text-xl text-gray-600">Carregando formulários...</div>
        </div>
      </div>
    );
  }

  if (!user || !stats) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-50">
        <div className="text-center">
          <div className="text-xl text-red-600 mb-2">Erro ao carregar dados</div>
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
    <div className="min-h-screen bg-gray-50 overflow-visible">
      {/* Header */}
      <header className="bg-white shadow-sm border-b">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center py-4">
            <div className="flex items-center gap-4">
              <button
                onClick={() => router.push('/v1/dashboard')}
                className="text-gray-500 hover:text-gray-700"
              >
                <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" />
                </svg>
              </button>
              <h1 className="text-2xl font-bold text-gray-800">Formulários</h1>
              <span className="px-3 py-1 bg-gradient-to-r from-purple-100 to-blue-100 text-purple-800 text-sm rounded-full font-medium">
                {getGreeting()}, {getFirstName(user.name || user.username || '')}! 📋
              </span>
            </div>
            <div className="flex items-center gap-4">
              <div className="flex items-center gap-2">
                {user.avatar_url ? (
                  <img 
                    src={user.avatar_url} 
                    alt={user.name || user.username || 'User'} 
                    className="w-8 h-8 rounded-full border border-gray-200"
                  />
                ) : (
                  <div className="w-8 h-8 bg-blue-500 rounded-full flex items-center justify-center text-white text-sm font-medium">
                    {(user.name || user.username || 'U').charAt(0).toUpperCase()}
                  </div>
                )}
                <span className="text-sm text-gray-600">{getFirstName(user.name || user.username || '')}</span>
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
      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8 overflow-visible">
        {/* Estatísticas */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
          <div className="bg-white p-6 rounded-lg shadow">
            <div className="flex items-center">
              <div className="flex-shrink-0">
                <svg className="w-8 h-8 text-green-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
              </div>
              <div className="ml-5 w-0 flex-1">
                <dl>
                  <dt className="text-sm font-medium text-gray-500 truncate">
                    Formulários Ativos
                    {(statusFilter !== 'all' || periodFilter !== 'all') && (
                      <span className="ml-1 text-xs text-blue-600">(filtrados)</span>
                    )}
                  </dt>
                  <dd className="text-lg font-medium text-gray-900">
                    {(statusFilter !== 'all' || periodFilter !== 'all') 
                      ? getFilteredStats().active_forms 
                      : stats.active_forms}
                  </dd>
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
                  <dt className="text-sm font-medium text-gray-500 truncate">
                    Total de Respostas
                    {(statusFilter !== 'all' || periodFilter !== 'all') && (
                      <span className="ml-1 text-xs text-blue-600">(filtrados)</span>
                    )}
                  </dt>
                  <dd className="text-lg font-medium text-gray-900">
                    {(statusFilter !== 'all' || periodFilter !== 'all') 
                      ? getFilteredStats().total_responses 
                      : stats.total_responses}
                  </dd>
                </dl>
              </div>
            </div>
          </div>

          <div className="bg-white p-6 rounded-lg shadow">
            <div className="flex items-center">
              <div className="flex-shrink-0">
                <svg className="w-8 h-8 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
                </svg>
              </div>
              <div className="ml-5 w-0 flex-1">
                <dl>
                  <dt className="text-sm font-medium text-gray-500 truncate">Respostas este Mês</dt>
                  <dd className="text-lg font-medium text-gray-900">{stats.responses_this_month}</dd>
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
                  <dt className="text-sm font-medium text-gray-500 truncate">Respostas esta Semana</dt>
                  <dd className="text-lg font-medium text-gray-900">{stats.responses_this_week}</dd>
                </dl>
              </div>
            </div>
          </div>
        </div>

        {/* Filtros */}
        <div className="bg-white rounded-lg shadow p-6 mb-6">
          <div className="flex flex-col lg:flex-row lg:items-center gap-4">
            <div className="flex-1">
              <h3 className="text-sm font-medium text-gray-700 mb-2">Filtros</h3>
              <div className="flex flex-wrap gap-3">
                {/* Filtro por Status */}
                <div className="min-w-[140px]">
                  <label className="block text-xs text-gray-500 mb-1">Status</label>
                  <select
                    value={statusFilter}
                    onChange={(e) => setStatusFilter(e.target.value)}
                    className="w-full px-3 py-2 text-sm border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  >
                    <option value="all">Todos</option>
                    <option value="public">Público</option>
                    <option value="draft">Rascunho</option>
                    <option value="private">Privado</option>
                    <option value="archived">Arquivado</option>
                    <option value="closed">Fechado</option>
                  </select>
                </div>

                {/* Filtro por Período */}
                <div className="min-w-[140px]">
                  <label className="block text-xs text-gray-500 mb-1">Período</label>
                  <select
                    value={periodFilter}
                    onChange={(e) => setPeriodFilter(e.target.value)}
                    className="w-full px-3 py-2 text-sm border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  >
                    <option value="all">Todos</option>
                    <option value="today">Hoje</option>
                    <option value="week">Última semana</option>
                    <option value="month">Último mês</option>
                    <option value="year">Último ano</option>
                  </select>
                </div>

                {/* Ordenação */}
                <div className="min-w-[140px]">
                  <label className="block text-xs text-gray-500 mb-1">Ordenar por</label>
                  <select
                    value={sortBy}
                    onChange={(e) => setSortBy(e.target.value)}
                    className="w-full px-3 py-2 text-sm border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  >
                    <option value="created_at">Data de criação</option>
                    <option value="title">Nome A-Z</option>
                    <option value="responses">Mais respostas</option>
                    <option value="status">Status</option>
                  </select>
                </div>
              </div>
            </div>

            {/* Estatísticas dos filtros */}
            <div className="lg:text-right">
              <p className="text-sm text-gray-600">
                Mostrando <span className="font-medium text-blue-600">{filteredForms.length}</span> de{' '}
                <span className="font-medium">{forms.length}</span> formulários
              </p>
              {(statusFilter !== 'all' || periodFilter !== 'all') && (
                <button
                  onClick={() => {
                    setStatusFilter('all');
                    setPeriodFilter('all');
                    setSortBy('created_at');
                  }}
                  className="text-xs text-blue-600 hover:text-blue-800 mt-1"
                >
                  Limpar filtros
                </button>
              )}
            </div>
          </div>
        </div>

        {/* Filtros Ativos */}
        {(statusFilter !== 'all' || periodFilter !== 'all' || sortBy !== 'created_at') && (
          <div className="mb-4">
            <div className="flex flex-wrap items-center gap-2">
              <span className="text-sm text-gray-600">Filtros ativos:</span>
              
              {statusFilter !== 'all' && (
                <span className="inline-flex items-center px-2 py-1 bg-blue-100 text-blue-800 text-xs rounded-full">
                  Status: {getStatusText(statusFilter)}
                  <button
                    onClick={() => setStatusFilter('all')}
                    className="ml-1 text-blue-600 hover:text-blue-800"
                  >
                    ×
                  </button>
                </span>
              )}
              
              {periodFilter !== 'all' && (
                <span className="inline-flex items-center px-2 py-1 bg-green-100 text-green-800 text-xs rounded-full">
                  Período: {periodFilter === 'today' ? 'Hoje' : 
                           periodFilter === 'week' ? 'Última semana' :
                           periodFilter === 'month' ? 'Último mês' : 'Último ano'}
                  <button
                    onClick={() => setPeriodFilter('all')}
                    className="ml-1 text-green-600 hover:text-green-800"
                  >
                    ×
                  </button>
                </span>
              )}
              
              {sortBy !== 'created_at' && (
                <span className="inline-flex items-center px-2 py-1 bg-purple-100 text-purple-800 text-xs rounded-full">
                  Ordem: {sortBy === 'title' ? 'Nome A-Z' :
                          sortBy === 'responses' ? 'Mais respostas' : 'Status'}
                  <button
                    onClick={() => setSortBy('created_at')}
                    className="ml-1 text-purple-600 hover:text-purple-800"
                  >
                    ×
                  </button>
                </span>
              )}
            </div>
          </div>
        )}

        {/* Ações */}          <div className="mb-6 flex justify-between items-center">
            <div>
              <h2 className="text-xl font-semibold text-gray-900">Todos os Formulários</h2>
              <p className="text-gray-600">Gerencie todos os seus formulários em um só lugar</p>
            </div>
          <button 
            onClick={() => router.push('/v1/forms/new')}
            className="px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors flex items-center gap-2"
          >
            <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4v16m8-8H4" />
            </svg>
            Criar Novo Formulário
          </button>
        </div>

        {/* Grid de Formulários */}
        {filteredForms.length === 0 ? (
          <div className="bg-white rounded-lg shadow p-12 text-center">
            {forms.length === 0 ? (
              <>
                <svg className="w-16 h-16 text-gray-400 mx-auto mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                </svg>
                <h3 className="text-lg font-medium text-gray-900 mb-2">Nenhum formulário encontrado</h3>
                <p className="text-gray-500 mb-6">Comece criando seu primeiro formulário para coletar respostas.</p>
                <button 
                  onClick={() => router.push('/v1/forms/new')}
                  className="px-6 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
                >
                  Criar Primeiro Formulário
                </button>
              </>
            ) : (
              <>
                <svg className="w-12 h-12 text-gray-400 mx-auto mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
                </svg>
                <h3 className="text-lg font-medium text-gray-900 mb-2">Nenhum formulário encontrado</h3>
                <p className="text-gray-500 mb-4">Nenhum formulário corresponde aos filtros selecionados.</p>
                <button
                  onClick={() => {
                    setStatusFilter('all');
                    setPeriodFilter('all');
                    setSortBy('created_at');
                  }}
                  className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
                >
                  Limpar Filtros
                </button>
              </>
            )}
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 overflow-visible">
            {filteredForms.map((form) => (
              <div key={form.id} className="bg-white rounded-lg shadow hover:shadow-md transition-shadow overflow-visible">
                <div className="p-6">
                  <div className="flex items-start justify-between mb-4">
                    <div className="flex items-center">
                      <div 
                        className="w-3 h-3 rounded-full mr-3"
                        style={{ backgroundColor: form.folder_color || '#3B82F6' }}
                      ></div>
                      <span className={`inline-flex px-2 py-1 text-xs font-semibold rounded-full ${getStatusColor(form.status)}`}>
                        {getStatusText(form.status)}
                      </span>
                    </div>
                    <Popover
                      isOpen={openPopover === form.id}
                      onOpenChange={(open) => setOpenPopover(open ? form.id : null)}
                      content={
                        <div>
                          <PopoverItem
                            icon={
                              <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8.684 13.342C8.886 12.938 9 12.482 9 12c0-.482-.114-.938-.316-1.342m0 2.684a3 3 0 110-2.684m0 2.684l6.632 3.316m-6.632-6l6.632-3.316m0 0a3 3 0 105.367-2.684 3 3 0 00-5.367 2.684zm0 9.316a3 3 0 105.367 2.684 3 3 0 00-5.367-2.684z" />
                              </svg>
                            }
                            onClick={() => handleCopyLink(form.id, form.title)}
                          >
                            {copyFeedback === form.id ? 'Link copiado!' : 'Copiar link'}
                          </PopoverItem>
                          
                          <PopoverItem
                            icon={
                              <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
                              </svg>
                            }
                            onClick={() => handleEditForm(form.id)}
                          >
                            Editar
                          </PopoverItem>
                          
                          <PopoverSeparator />
                          
                          <PopoverItem
                            icon={
                              <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                              </svg>
                            }
                            onClick={() => handleDeleteForm(form.id, form.title)}
                            className="text-red-600 hover:bg-red-50"
                          >
                            {isDeleting === form.id ? 'Excluindo...' : 'Excluir'}
                          </PopoverItem>
                        </div>
                      }
                    >
                      <button 
                        onClick={() => {
                          setOpenPopover(openPopover === form.id ? null : form.id);
                        }}
                        className="text-gray-400 hover:text-gray-600"
                      >
                        <svg className="w-5 h-5" fill="currentColor" viewBox="0 0 20 20">
                          <path d="M10 6a2 2 0 110-4 2 2 0 010 4zM10 12a2 2 0 110-4 2 2 0 010 4zM10 18a2 2 0 110-4 2 2 0 010 4z" />
                        </svg>
                      </button>
                    </Popover>
                  </div>

                  <h3 className="text-lg font-medium text-gray-900 mb-2">{form.title}</h3>
                  <p className="text-gray-600 text-sm mb-4 line-clamp-2">{form.description || 'Sem descrição'}</p>

                  <div className="flex items-center justify-between text-sm text-gray-500 mb-4">
                    <span>{form.total_responses} respostas</span>
                    <span>{new Date(form.created_at).toLocaleDateString('pt-BR')}</span>
                  </div>

                  <div className="flex gap-2">
                    <button 
                      onClick={() => handleViewResponses(form.id)}
                      className="flex-1 px-3 py-2 text-sm bg-blue-600 text-white rounded hover:bg-blue-700 transition-colors"
                    >
                      Ver Respostas
                    </button>
                    <button 
                      onClick={() => handleEditForm(form.id)}
                      className="flex-1 px-3 py-2 text-sm bg-gray-100 text-gray-700 rounded hover:bg-gray-200 transition-colors"
                    >
                      Editar
                    </button>
                    <button 
                      onClick={() => handleCopyLink(form.id, form.title)}
                      className="px-3 py-2 text-sm bg-gray-100 text-gray-700 rounded hover:bg-gray-200 transition-colors"
                      title="Copiar link do formulário"
                    >
                      {copyFeedback === form.id ? (
                        <svg className="w-4 h-4 text-green-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                        </svg>
                      ) : (
                        <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8.684 13.342C8.886 12.938 9 12.482 9 12c0-.482-.114-.938-.316-1.342m0 2.684a3 3 0 110-2.684m0 2.684l6.632 3.316m-6.632-6l6.632-3.316m0 0a3 3 0 105.367-2.684 3 3 0 00-5.367 2.684zm0 9.316a3 3 0 105.367 2.684 3 3 0 00-5.367-2.684z" />
                        </svg>
                      )}
                    </button>
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}
      </main>
    </div>
  );
}
