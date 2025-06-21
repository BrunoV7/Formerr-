'use client';

import { useState, useEffect } from 'react';
import { useParams, useRouter } from 'next/navigation';
import { formsService } from '@/services/api';
import { FormAnalytics, ResponseSession, ResponseDetail } from '@/types';
import {
  DndContext,
  closestCenter,
  KeyboardSensor,
  PointerSensor,
  useSensor,
  useSensors,
} from '@dnd-kit/core';
import {
  arrayMove,
  SortableContext,
  sortableKeyboardCoordinates,
  verticalListSortingStrategy,
} from '@dnd-kit/sortable';
import {
  useSortable,
} from '@dnd-kit/sortable';
import { CSS } from '@dnd-kit/utilities';
import { ChevronDownIcon, ChevronUpIcon, PencilIcon, CheckIcon, XMarkIcon } from '@heroicons/react/24/outline';

interface FormData {
  id: string;
  title: string;
  description: string;
  status: string;
}

interface Question {
  id: string;
  type: string;
  title: string;
  description?: string;
  required: boolean;
  order: number;
}

interface Section {
  id: string;
  title: string;
  description: string;
  order: number;
  questions: Question[];
}

// Componente para seção sortable
function SortableSection({ section, isCollapsed, onToggleCollapse }: { 
  section: Section; 
  isCollapsed: boolean; 
  onToggleCollapse: () => void; 
}) {
  const {
    attributes,
    listeners,
    setNodeRef,
    transform,
    transition,
  } = useSortable({ id: section.id });

  const style = {
    transform: CSS.Transform.toString(transform),
    transition,
  };

  return (
    <div ref={setNodeRef} style={style} className="bg-white border border-gray-200 rounded-lg">
      <div className="flex items-center justify-between p-4 hover:bg-gray-50">
        <div 
          className="flex-1 cursor-move"
          {...attributes}
          {...listeners}
        >
          <h3 className="font-semibold text-gray-900">{section.title}</h3>
          <p className="text-gray-600 text-sm mt-1">{section.description}</p>
          <div className="flex items-center gap-2 mt-2">
            <span className="text-xs px-2 py-1 bg-blue-100 text-blue-700 rounded">
              {section.questions.length} pergunta{section.questions.length !== 1 ? 's' : ''}
            </span>
          </div>
        </div>
        <button
          onClick={(e) => {
            e.stopPropagation();
            onToggleCollapse();
          }}
          className="ml-4 p-2 hover:bg-gray-100 rounded transition-colors border border-transparent hover:border-gray-300"
          title={isCollapsed ? "Expandir seção" : "Colapsar seção"}
        >
          {isCollapsed ? (
            <ChevronDownIcon className="w-5 h-5 text-gray-500" />
          ) : (
            <ChevronUpIcon className="w-5 h-5 text-gray-500" />
          )}
        </button>
      </div>
      
      {!isCollapsed && (
        <div className="px-4 pb-4 border-t border-gray-100">
          <div className="mt-3 space-y-2">
            {section.questions.map((question, questionIndex) => (
              <div key={question.id} className="flex items-start gap-3 py-2">
                <span className="text-sm text-gray-500 font-mono bg-gray-100 px-2 py-1 rounded">
                  {questionIndex + 1}
                </span>
                <div className="flex-1">
                  <p className="text-gray-900">{question.title}</p>
                  {question.description && (
                    <p className="text-gray-500 text-sm">{question.description}</p>
                  )}
                  <div className="flex items-center gap-2 mt-1">
                    <span className="text-xs px-2 py-1 bg-blue-100 text-blue-700 rounded">
                      {question.type}
                    </span>
                    {question.required && (
                      <span className="text-xs px-2 py-1 bg-red-100 text-red-700 rounded">
                        Obrigatória
                      </span>
                    )}
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}

export default function FormSummaryPage() {
  const params = useParams();
  const router = useRouter();
  const formId = params.id as string;
  
  const [formData, setFormData] = useState<FormData | null>(null);
  const [sections, setSections] = useState<Section[]>([]);
  const [analytics, setAnalytics] = useState<FormAnalytics | null>(null);
  const [responseSessions, setResponseSessions] = useState<ResponseSession[]>([]);
  const [selectedResponseDetail, setSelectedResponseDetail] = useState<ResponseDetail | null>(null);
  
  const [isLoading, setIsLoading] = useState(true);
  const [isPublishing, setIsPublishing] = useState(false);
  const [isSaving, setIsSaving] = useState(false);
  
  const [activeTab, setActiveTab] = useState<'sections' | 'analytics' | 'responses'>('sections');
  const [collapsedSections, setCollapsedSections] = useState<Set<string>>(new Set());
  
  // Estados para edição
  const [isEditingTitle, setIsEditingTitle] = useState(false);
  const [isEditingDescription, setIsEditingDescription] = useState(false);
  const [editTitle, setEditTitle] = useState('');
  const [editDescription, setEditDescription] = useState('');

  const sensors = useSensors(
    useSensor(PointerSensor),
    useSensor(KeyboardSensor, {
      coordinateGetter: sortableKeyboardCoordinates,
    })
  );

  useEffect(() => {
    const loadData = async () => {
      try {
        setIsLoading(true);
        
        // Carregar dados do formulário
        const form = await formsService.getForm(formId);
        const formInfo = {
          id: form.id,
          title: form.title,
          description: form.description || '',
          status: form.status
        };
        setFormData(formInfo);
        setEditTitle(formInfo.title);
        setEditDescription(formInfo.description);
        
        // Carregar seções
        const sectionsData = await formsService.getSections(formId);
        setSections(sectionsData.sections.sort((a: Section, b: Section) => a.order - b.order));
        
        // Carregar analytics se o formulário for público
        if (form.status === 'public') {
          try {
            const analyticsData = await formsService.getAnalytics(formId);
            
            // Parse dos dados de analytics que podem vir com JSON strings
            const parsedAnalytics = {
              ...analyticsData,
              responses_per_question: analyticsData.responses_per_question?.map((questionStats: any) => {
                // Parse da distribuição se existir
                const parsedDistribution: Record<string, number> = {};
                if (questionStats.distribution) {
                  Object.entries(questionStats.distribution).forEach(([key, value]) => {
                    try {
                      // Tenta fazer parse da chave se for JSON string
                      const parsedKey = JSON.parse(key);
                      const displayKey = Array.isArray(parsedKey) ? parsedKey.join(', ') : parsedKey.toString();
                      parsedDistribution[displayKey] = value as number;
                    } catch (e) {
                      // Se não conseguir fazer parse, usa a chave original
                      parsedDistribution[key] = value as number;
                    }
                  });
                }
                
                return {
                  ...questionStats,
                  distribution: Object.keys(parsedDistribution).length > 0 ? parsedDistribution : questionStats.distribution
                };
              }) || []
            };
            
            setAnalytics(parsedAnalytics);
            
            const responsesData = await formsService.getResponses(formId);
            setResponseSessions(responsesData);
          } catch (error) {
            console.error('Erro ao carregar analytics:', error);
          }
        }
        
      } catch (error) {
        console.error('Erro ao carregar dados:', error);
      } finally {
        setIsLoading(false);
      }
    };

    loadData();
  }, [formId]);

  const handleSaveTitle = async () => {
    if (!formData) return;
    
    try {
      setIsSaving(true);
      await formsService.updateForm(formId, { title: editTitle });
      setFormData({ ...formData, title: editTitle });
      setIsEditingTitle(false);
    } catch (error) {
      console.error('Erro ao salvar título:', error);
    } finally {
      setIsSaving(false);
    }
  };

  const handleSaveDescription = async () => {
    if (!formData) return;
    
    try {
      setIsSaving(true);
      await formsService.updateForm(formId, { description: editDescription });
      setFormData({ ...formData, description: editDescription });
      setIsEditingDescription(false);
    } catch (error) {
      console.error('Erro ao salvar descrição:', error);
    } finally {
      setIsSaving(false);
    }
  };

  const handleStatusChange = async (newStatus: string) => {
    if (!formData) return;
    
    try {
      setIsSaving(true);
      await formsService.updateForm(formId, { status: newStatus });
      setFormData({ ...formData, status: newStatus });
      
      // Se mudou para público, carregar analytics
      if (newStatus === 'public' && !analytics) {
        try {
          const analyticsData = await formsService.getAnalytics(formId);
          
          // Parse dos dados de analytics que podem vir com JSON strings
          const parsedAnalytics = {
            ...analyticsData,
            responses_per_question: analyticsData.responses_per_question?.map((questionStats: any) => {
              // Parse da distribuição se existir
              const parsedDistribution: Record<string, number> = {};
              if (questionStats.distribution) {
                Object.entries(questionStats.distribution).forEach(([key, value]) => {
                  try {
                    // Tenta fazer parse da chave se for JSON string
                    const parsedKey = JSON.parse(key);
                    const displayKey = Array.isArray(parsedKey) ? parsedKey.join(', ') : parsedKey.toString();
                    parsedDistribution[displayKey] = value as number;
                  } catch (e) {
                    // Se não conseguir fazer parse, usa a chave original
                    parsedDistribution[key] = value as number;
                  }
                });
              }
              
              return {
                ...questionStats,
                distribution: Object.keys(parsedDistribution).length > 0 ? parsedDistribution : questionStats.distribution
              };
            }) || []
          };
          
          setAnalytics(parsedAnalytics);
          
          const responsesData = await formsService.getResponses(formId);
          setResponseSessions(responsesData);
        } catch (error) {
          console.error('Erro ao carregar analytics:', error);
        }
      }
    } catch (error) {
      console.error('Erro ao atualizar status:', error);
    } finally {
      setIsSaving(false);
    }
  };

  const handleDragEnd = async (event: any) => {
    const { active, over } = event;

    if (active.id !== over.id) {
      const oldIndex = sections.findIndex((section) => section.id === active.id);
      const newIndex = sections.findIndex((section) => section.id === over.id);
      
      const newSections = arrayMove(sections, oldIndex, newIndex);
      setSections(newSections);
      
      // Salvar nova ordem no backend
      try {
        await formsService.updateSectionOrder(formId, active.id, newIndex + 1);
      } catch (error) {
        console.error('Erro ao salvar ordem das seções:', error);
        // Reverter em caso de erro
        setSections(sections);
      }
    }
  };

  const handleToggleSection = (sectionId: string) => {
    const newCollapsed = new Set(collapsedSections);
    if (newCollapsed.has(sectionId)) {
      newCollapsed.delete(sectionId);
    } else {
      newCollapsed.add(sectionId);
    }
    setCollapsedSections(newCollapsed);
  };

  const handleViewResponseDetail = async (sessionId: string) => {
    try {
      const detail = await formsService.getResponseDetail(sessionId);
      
      // Parse dos valores que vêm como JSON strings do backend
      const parsedDetail = {
        ...detail,
        answers: detail.answers.map((answer: any) => {
          let parsedValue = answer.value;
          
          try {
            // Tenta fazer parse do JSON string
            const parsed = JSON.parse(answer.value);
            if (Array.isArray(parsed)) {
              // Se for array, junta com vírgulas (para checkboxes)
              parsedValue = parsed.join(', ');
            } else {
              parsedValue = parsed.toString();
            }
          } catch (e) {
            // Se não conseguir fazer parse, usa o valor original
            parsedValue = answer.value;
          }
          
          return {
            ...answer,
            value: parsedValue
          };
        })
      };
      
      setSelectedResponseDetail(parsedDetail);
    } catch (error) {
      console.error('Erro ao carregar detalhes da resposta:', error);
    }
  };

  const getTotalQuestions = () => {
    return sections.reduce((total, section) => total + section.questions.length, 0);
  };

  const getRequiredQuestions = () => {
    return sections.reduce((total, section) => 
      total + section.questions.filter(q => q.required).length, 0
    );
  };

  if (isLoading) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600 mx-auto mb-4"></div>
          <p className="text-gray-600">Carregando resumo...</p>
        </div>
      </div>
    );
  }

  if (!formData) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-center">
          <p className="text-red-600">Erro ao carregar formulário</p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-white shadow-sm border-b">
        <div className="max-w-7xl mx-auto px-6 py-4">
          <div className="flex items-center justify-between">
            <div>
              <h1 className="text-2xl font-bold text-gray-900">Resumo do Formulário</h1>
              <p className="text-gray-600 mt-1">Gerencie e analise seu formulário</p>
            </div>
            <div className="flex items-center gap-3">
              <button
                onClick={() => router.push(`/v1/forms/${formId}/edit`)}
                className="px-4 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 transition-colors"
              >
                ← Voltar ao Editor
              </button>
              <button
                onClick={() => router.push('/v1/forms')}
                className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
              >
                Meus Formulários
              </button>
            </div>
          </div>
        </div>
      </div>

      <div className="max-w-7xl mx-auto px-6 py-8">
        <div className="grid grid-cols-1 lg:grid-cols-4 gap-8">
          {/* Main Content */}
          <div className="lg:col-span-3 space-y-6">
            {/* Form Info - Editável */}
            <div className="bg-white rounded-lg shadow-sm border p-6">
              <h2 className="text-xl font-semibold text-gray-900 mb-4">Informações do Formulário</h2>
              <div className="space-y-4">
                {/* Título editável */}
                <div>
                  <label className="text-sm font-medium text-gray-700">Título</label>
                  {isEditingTitle ? (
                    <div className="flex items-center gap-2 mt-1">
                      <input
                        type="text"
                        value={editTitle}
                        onChange={(e) => setEditTitle(e.target.value)}
                        className="flex-1 px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                        autoFocus
                      />
                      <button
                        onClick={handleSaveTitle}
                        disabled={isSaving}
                        className="p-2 text-green-600 hover:bg-green-50 rounded-md"
                      >
                        <CheckIcon className="w-5 h-5" />
                      </button>
                      <button
                        onClick={() => {
                          setIsEditingTitle(false);
                          setEditTitle(formData.title);
                        }}
                        className="p-2 text-red-600 hover:bg-red-50 rounded-md"
                      >
                        <XMarkIcon className="w-5 h-5" />
                      </button>
                    </div>
                  ) : (
                    <div className="flex items-center gap-2 mt-1">
                      <p className="text-gray-900 flex-1">{formData.title}</p>
                      <button
                        onClick={() => setIsEditingTitle(true)}
                        className="p-1 text-gray-400 hover:text-gray-600 hover:bg-gray-50 rounded"
                      >
                        <PencilIcon className="w-4 h-4" />
                      </button>
                    </div>
                  )}
                </div>

                {/* Descrição editável */}
                <div>
                  <label className="text-sm font-medium text-gray-700">Descrição</label>
                  {isEditingDescription ? (
                    <div className="flex items-start gap-2 mt-1">
                      <textarea
                        value={editDescription}
                        onChange={(e) => setEditDescription(e.target.value)}
                        className="flex-1 px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                        rows={3}
                        autoFocus
                      />
                      <div className="flex flex-col gap-2">
                        <button
                          onClick={handleSaveDescription}
                          disabled={isSaving}
                          className="p-2 text-green-600 hover:bg-green-50 rounded-md"
                        >
                          <CheckIcon className="w-5 h-5" />
                        </button>
                        <button
                          onClick={() => {
                            setIsEditingDescription(false);
                            setEditDescription(formData.description);
                          }}
                          className="p-2 text-red-600 hover:bg-red-50 rounded-md"
                        >
                          <XMarkIcon className="w-5 h-5" />
                        </button>
                      </div>
                    </div>
                  ) : (
                    <div className="flex items-start gap-2 mt-1">
                      <p className="text-gray-600 flex-1">{formData.description || 'Nenhuma descrição'}</p>
                      <button
                        onClick={() => setIsEditingDescription(true)}
                        className="p-1 text-gray-400 hover:text-gray-600 hover:bg-gray-50 rounded"
                      >
                        <PencilIcon className="w-4 h-4" />
                      </button>
                    </div>
                  )}
                </div>

                {/* Status editável */}
                <div>
                  <label className="text-sm font-medium text-gray-700">Status</label>
                  <div className="mt-1">
                    <select
                      value={formData.status}
                      onChange={(e) => handleStatusChange(e.target.value)}
                      disabled={isSaving}
                      className="px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                    >
                      <option value="draft">Rascunho</option>
                      <option value="public">Público</option>
                      <option value="closed">Fechado</option>
                    </select>
                  </div>
                </div>
              </div>
            </div>

            {/* Tabs */}
            <div className="bg-white rounded-lg shadow-sm border">
              <div className="border-b border-gray-200">
                <nav className="flex space-x-8 px-6">
                  <button
                    onClick={() => setActiveTab('sections')}
                    className={`py-4 px-1 border-b-2 font-medium text-sm ${
                      activeTab === 'sections'
                        ? 'border-blue-500 text-blue-600'
                        : 'border-transparent text-gray-500 hover:text-gray-700'
                    }`}
                  >
                    Seções ({sections.length})
                  </button>
                  <button
                    onClick={() => setActiveTab('analytics')}
                    className={`py-4 px-1 border-b-2 font-medium text-sm ${
                      activeTab === 'analytics'
                        ? 'border-blue-500 text-blue-600'
                        : 'border-transparent text-gray-500 hover:text-gray-700'
                    }`}
                  >
                    Resumo de Respostas ({analytics?.total_responses || 0})
                  </button>
                  <button
                    onClick={() => setActiveTab('responses')}
                    className={`py-4 px-1 border-b-2 font-medium text-sm ${
                      activeTab === 'responses'
                        ? 'border-blue-500 text-blue-600'
                        : 'border-transparent text-gray-500 hover:text-gray-700'
                    }`}
                  >
                    Respostas Específicas ({responseSessions.length})
                  </button>
                </nav>
              </div>

              <div className="p-6">
                {/* Tab Content: Seções */}
                {activeTab === 'sections' && (
                  <div>
                    <div className="flex items-center justify-between mb-6">
                      <h3 className="text-lg font-semibold text-gray-900">Seções do Formulário</h3>
                      <div className="text-sm text-gray-500">
                        Arraste para reordenar • Clique para expandir/colapsar
                      </div>
                    </div>
                    
                    {sections.length === 0 ? (
                      <div className="text-center py-12 text-gray-500">
                        <p>Nenhuma seção encontrada</p>
                        <button
                          onClick={() => router.push(`/v1/forms/${formId}/edit`)}
                          className="mt-2 text-blue-600 hover:text-blue-800"
                        >
                          Ir para o editor para adicionar seções
                        </button>
                      </div>
                    ) : (
                      <DndContext 
                        collisionDetection={closestCenter}
                        onDragEnd={handleDragEnd}
                        sensors={sensors}
                      >
                        <SortableContext
                          items={sections.map(s => s.id)}
                          strategy={verticalListSortingStrategy}
                        >
                          <div className="space-y-4">
                            {sections.map((section) => (
                              <SortableSection
                                key={section.id}
                                section={section}
                                isCollapsed={collapsedSections.has(section.id)}
                                onToggleCollapse={() => handleToggleSection(section.id)}
                              />
                            ))}
                          </div>
                        </SortableContext>
                      </DndContext>
                    )}
                  </div>
                )}

                {/* Tab Content: Analytics */}
                {activeTab === 'analytics' && (
                  <div>
                    <h3 className="text-lg font-semibold text-gray-900 mb-6">Resumo de Respostas</h3>
                    
                    {!analytics ? (
                      <div className="text-center py-12 text-gray-500">
                        <p>Analytics disponível apenas para formulários públicos</p>
                        {formData.status !== 'public' && (
                          <button
                            onClick={() => handleStatusChange('public')}
                            className="mt-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
                          >
                            Tornar formulário público
                          </button>
                        )}
                      </div>
                    ) : (
                      <div className="space-y-6">
                        {/* Resumo geral */}
                        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                          <div className="bg-blue-50 rounded-lg p-4">
                            <div className="text-2xl font-bold text-blue-900">{analytics.total_responses || 0}</div>
                            <div className="text-blue-700">Total de Respostas</div>
                          </div>
                          <div className="bg-green-50 rounded-lg p-4">
                            <div className="text-2xl font-bold text-green-900">{analytics.responses_this_month || 0}</div>
                            <div className="text-green-700">Este Mês</div>
                          </div>
                          <div className="bg-purple-50 rounded-lg p-4">
                            <div className="text-2xl font-bold text-purple-900">{analytics.responses_this_week || 0}</div>
                            <div className="text-purple-700">Esta Semana</div>
                          </div>
                        </div>

                        {/* Estatísticas por pergunta */}
                        <div>
                          <h4 className="font-medium text-gray-900 mb-4">Respostas por Pergunta</h4>
                          {analytics.responses_per_question && analytics.responses_per_question.length > 0 ? (
                            <div className="space-y-4">
                              {analytics.responses_per_question.map((questionStats) => (
                                <div key={questionStats.question_id} className="border border-gray-200 rounded-lg p-4">
                                  <div className="flex items-center justify-between mb-2">
                                    <h5 className="font-medium text-gray-900">{questionStats.title || 'Título não disponível'}</h5>
                                    <span className="text-sm text-gray-500">{questionStats.total || 0} respostas</span>
                                  </div>
                                  <div className="text-sm text-gray-600 mb-3">
                                    Tipo: {questionStats.type || 'N/A'} • {questionStats.total || 0} resposta{(questionStats.total || 0) !== 1 ? 's' : ''}
                                  </div>
                                  
                                  {questionStats.distribution && Object.keys(questionStats.distribution).length > 0 ? (
                                    <div className="space-y-2">
                                      <div className="text-sm font-medium text-gray-700">
                                        {questionStats.type === 'checkbox' ? 'Opções Selecionadas:' : 
                                         ['multiple-choice', 'dropdown'].includes(questionStats.type) ? 'Distribuição das Escolhas:' :
                                         'Respostas Únicas:'}
                                      </div>
                                      <div className="max-h-48 overflow-y-auto space-y-1">
                                        {Object.entries(questionStats.distribution)
                                          .sort(([,a], [,b]) => (b as number) - (a as number)) // Ordena por quantidade
                                          .map(([value, count]) => {
                                            const percentage = questionStats.total > 0 ? (count / questionStats.total) * 100 : 0;
                                            return (
                                              <div key={value} className="flex items-center justify-between p-2 bg-gray-50 rounded">
                                                <div className="flex-1 min-w-0">
                                                  <span className="text-sm text-gray-700 break-words" title={value}>
                                                    {value || 'Resposta vazia'}
                                                  </span>
                                                </div>
                                                <div className="flex items-center gap-2 ml-2">
                                                  <div className="bg-gray-200 rounded-full h-2 w-16">
                                                    <div 
                                                      className="bg-blue-500 h-2 rounded-full transition-all duration-300"
                                                      style={{ 
                                                        width: `${Math.max(percentage, 2)}%` // Mínimo 2% para visibilidade
                                                      }}
                                                    />
                                                  </div>
                                                  <span className="text-sm text-gray-600 font-medium min-w-max">
                                                    {count} ({percentage.toFixed(1)}%)
                                                  </span>
                                                </div>
                                              </div>
                                            );
                                          })}
                                      </div>
                                      {Object.keys(questionStats.distribution).length > 5 && (
                                        <div className="text-xs text-gray-500 text-center pt-2">
                                          {Object.keys(questionStats.distribution).length} respostas únicas encontradas
                                        </div>
                                      )}
                                    </div>
                                  ) : (
                                    <div className="text-center py-4 text-gray-500 bg-gray-50 rounded-lg">
                                      <div className="text-sm">
                                        {questionStats.total > 0 ? 'Aguardando dados do servidor...' : 'Nenhuma resposta recebida ainda'}
                                      </div>
                                      {questionStats.total > 0 && (
                                        <div className="text-xs mt-1">
                                          Se os dados não aparecerem, verifique se o backend está atualizado
                                        </div>
                                      )}
                                    </div>
                                  )}
                                </div>
                              ))}
                            </div>
                          ) : (
                            <div className="text-center py-8 text-gray-500">
                              <p>Nenhuma estatística de pergunta disponível</p>
                            </div>
                          )}
                        </div>
                      </div>
                    )}
                  </div>
                )}

                {/* Tab Content: Respostas Específicas */}
                {activeTab === 'responses' && (
                  <div>
                    <h3 className="text-lg font-semibold text-gray-900 mb-6">Respostas Específicas</h3>
                    
                    {responseSessions.length === 0 ? (
                      <div className="text-center py-12 text-gray-500">
                        <p>Nenhuma resposta encontrada</p>
                        <p className="text-xs mt-2">Certifique-se de que o formulário está público e já recebeu respostas</p>
                      </div>
                    ) : (
                      <div className="space-y-4">
                        {responseSessions.map((session) => (
                          <div key={session.id} className="border border-gray-200 rounded-lg p-4 hover:shadow-md transition-shadow">
                            <div className="flex items-center justify-between">
                              <div className="flex-1">
                                <div className="font-medium text-gray-900">
                                  Resposta #{session.id.slice(-8)} - {new Date(session.submitted_at).toLocaleDateString('pt-BR')}
                                </div>
                                <div className="text-sm text-gray-500 mt-1">
                                  {session.respondent_email && (
                                    <span>Email: {session.respondent_email} • </span>
                                  )}
                                  {session.respondent_ip && (
                                    <span>IP: {session.respondent_ip} • </span>
                                  )}
                                  {new Date(session.submitted_at).toLocaleString('pt-BR')}
                                </div>
                              </div>
                              <button
                                onClick={() => handleViewResponseDetail(session.id)}
                                className="px-3 py-1 text-sm bg-blue-50 text-blue-700 rounded hover:bg-blue-100 transition-colors"
                              >
                                Ver Detalhes
                              </button>
                            </div>
                          </div>
                        ))}
                      </div>
                    )}

                    {/* Modal de detalhes da resposta */}
                    {selectedResponseDetail && (
                      <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50">
                        <div className="bg-white rounded-lg max-w-4xl w-full max-h-[80vh] overflow-hidden">
                          <div className="px-6 py-4 border-b border-gray-200 flex items-center justify-between">
                            <h3 className="text-lg font-semibold">Detalhes da Resposta #{selectedResponseDetail.id.slice(-8)}</h3>
                            <button
                              onClick={() => setSelectedResponseDetail(null)}
                              className="text-gray-400 hover:text-gray-600 transition-colors"
                            >
                              <XMarkIcon className="w-6 h-6" />
                            </button>
                          </div>
                          <div className="px-6 py-4 max-h-[60vh] overflow-y-auto">
                            <div className="space-y-4">
                              <div className="bg-gray-50 p-4 rounded-lg">
                                <h4 className="font-medium text-gray-900 mb-2">Informações da Sessão</h4>
                                <div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-sm">
                                  <div>
                                    <span className="text-gray-600">Submetido em:</span>
                                    <div className="font-medium">{new Date(selectedResponseDetail.submitted_at).toLocaleString('pt-BR')}</div>
                                  </div>
                                  {selectedResponseDetail.respondent_email && (
                                    <div>
                                      <span className="text-gray-600">Email:</span>
                                      <div className="font-medium">{selectedResponseDetail.respondent_email}</div>
                                    </div>
                                  )}
                                  {selectedResponseDetail.respondent_ip && (
                                    <div>
                                      <span className="text-gray-600">IP:</span>
                                      <div className="font-medium">{selectedResponseDetail.respondent_ip}</div>
                                    </div>
                                  )}
                                  {selectedResponseDetail.user_agent && (
                                    <div className="md:col-span-2">
                                      <span className="text-gray-600">User Agent:</span>
                                      <div className="font-medium text-xs break-all">{selectedResponseDetail.user_agent}</div>
                                    </div>
                                  )}
                                </div>
                              </div>
                              
                              <div>
                                <h4 className="font-medium text-gray-900 mb-3">Respostas ({selectedResponseDetail.answers?.length || 0})</h4>
                                {selectedResponseDetail.answers && selectedResponseDetail.answers.length > 0 ? (
                                  <div className="space-y-3">
                                    {selectedResponseDetail.answers.map((answer, index) => (
                                      <div key={answer.question_id || index} className="border border-gray-200 rounded-lg p-4">
                                        <div className="flex items-start justify-between mb-2">
                                          <div className="font-medium text-gray-900 flex-1">
                                            {answer.question_title || 'Pergunta sem título'}
                                          </div>
                                          <span className="text-xs px-2 py-1 bg-gray-100 text-gray-600 rounded ml-2">
                                            {answer.question_type || 'N/A'}
                                          </span>
                                        </div>
                                        <div className="text-gray-700 mt-2 p-3 bg-gray-50 rounded border-l-4 border-blue-500">
                                          {answer.value || 'Sem resposta'}
                                        </div>
                                      </div>
                                    ))}
                                  </div>
                                ) : (
                                  <div className="text-center py-8 text-gray-500">
                                    <p>Nenhuma resposta encontrada</p>
                                  </div>
                                )}
                              </div>
                            </div>
                          </div>
                        </div>
                      </div>
                    )}
                  </div>
                )}
              </div>
            </div>
          </div>

          {/* Sidebar */}
          <div className="space-y-6">
            {/* Statistics */}
            <div className="bg-white rounded-lg shadow-sm border p-6">
              <h3 className="font-semibold text-gray-900 mb-4">Estatísticas</h3>
              <div className="space-y-4">
                <div className="flex justify-between">
                  <span className="text-gray-600">Total de Seções</span>
                  <span className="font-semibold">{sections.length}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-gray-600">Total de Perguntas</span>
                  <span className="font-semibold">{getTotalQuestions()}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-gray-600">Perguntas Obrigatórias</span>
                  <span className="font-semibold">{getRequiredQuestions()}</span>
                </div>
                {analytics && (
                  <>
                    <hr className="my-3" />
                    <div className="flex justify-between">
                      <span className="text-gray-600">Total Respostas</span>
                      <span className="font-semibold text-blue-600">{analytics.total_responses}</span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-gray-600">Este Mês</span>
                      <span className="font-semibold text-green-600">{analytics.responses_this_month}</span>
                    </div>
                  </>
                )}
              </div>
            </div>

            {/* Actions */}
            <div className="bg-white rounded-lg shadow-sm border p-6">
              <h3 className="font-semibold text-gray-900 mb-4">Ações</h3>
              <div className="space-y-3">
                <button
                  onClick={() => navigator.clipboard.writeText(`${window.location.origin}/public/forms/${formId}`)}
                  className="w-full px-4 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 transition-colors"
                >
                  Copiar Link
                </button>
                
                <button
                  onClick={() => window.open(`/public/forms/${formId}`, '_blank')}
                  className="w-full px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
                >
                  Visualizar Formulário
                </button>
              </div>
            </div>

            {/* Link público */}
            {formData.status === 'public' && (
              <div className="bg-blue-50 rounded-lg border border-blue-200 p-4">
                <h4 className="font-medium text-blue-900 mb-2">Link Público</h4>
                <p className="text-blue-700 text-sm break-all">
                  {window.location.origin}/public/forms/{formId}
                </p>
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
