'use client';

import { useState, useEffect, useRef, useCallback } from 'react';
import { useParams, useRouter } from 'next/navigation';
import { DndContext, closestCenter, DragEndEvent } from '@dnd-kit/core';
import { SortableContext, verticalListSortingStrategy, arrayMove } from '@dnd-kit/sortable';
import { useSortable } from '@dnd-kit/sortable';
import { CSS } from '@dnd-kit/utilities';
import { QUESTION_TEMPLATES, QUESTION_COMPONENTS, QuestionData } from '@/components/form-builder/questions';
import QuestionEditModal from '@/components/form-builder/QuestionEditModal';
import { formsService } from '@/services/api';

interface SectionSummary {
  id: string;
  title: string;
  description: string;
  order: number;
  questionCount: number;
}

interface Section {
  id: string;
  title: string;
  description: string;
  order: number;
  questions: QuestionData[];
}

interface FormData {
  id: string;
  title: string;
  description: string;
  color?: string;
  icon?: string;
}

// Componente draggable para pergunta
function SortableQuestion({ question, onEdit }: { question: QuestionData; onEdit: () => void }) {

  
  const {
    attributes,
    listeners,
    setNodeRef,
    transform,
    transition,
    isDragging,
  } = useSortable({ id: question.id });

  const style = {
    transform: CSS.Transform.toString(transform),
    transition,
    opacity: isDragging ? 0.5 : 1,
  };

  const QuestionComponent = QUESTION_COMPONENTS[question.type as keyof typeof QUESTION_COMPONENTS];

  return (
    <div ref={setNodeRef} style={style} className="relative group">
      <div
        {...attributes}
        {...listeners}
        className="absolute left-0 top-1/2 -translate-y-1/2 -ml-8 opacity-0 group-hover:opacity-100 transition-opacity cursor-grab active:cursor-grabbing"
      >
        <svg className="w-5 h-5 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 6h16M4 12h16M4 18h16" />
        </svg>
      </div>
      {QuestionComponent && (
        <QuestionComponent
          data={question}
          mode="edit"
          onEdit={onEdit}
        />
      )}
    </div>
  );
}

export default function EditFormPage() {
  const params = useParams();
  const router = useRouter();
  const formId = params.id as string;
  
  const [formData, setFormData] = useState<FormData | null>(null);
  const [sectionsList, setSectionsList] = useState<SectionSummary[]>([]);
  const [currentSection, setCurrentSection] = useState<Section | null>(null);
  const [currentSectionIndex, setCurrentSectionIndex] = useState(0);
  const [isLoading, setIsLoading] = useState(true);
  const [isSectionLoading, setIsSectionLoading] = useState(false);
  const [editingQuestion, setEditingQuestion] = useState<QuestionData | null>(null);
  const [isEditModalOpen, setIsEditModalOpen] = useState(false);
  const [isSaving, setIsSaving] = useState(false);
  const [hasUnsavedChanges, setHasUnsavedChanges] = useState(false);
  const [nextTempId, setNextTempId] = useState(1);
  
  // Auto-save timer
  const autoSaveTimer = useRef<NodeJS.Timeout | null>(null);

  // Função para salvar mudanças no backend (chamada apenas quando necessário)
  const saveCurrentSection = useCallback(async () => {
    if (!currentSection || !hasUnsavedChanges) return;

    try {
      setIsSaving(true);

      
      await formsService.updateSection(currentSection.id, {
        title: currentSection.title,
        description: currentSection.description,
        order: currentSection.order,
        questions: currentSection.questions.map(q => ({
          id: q.id.startsWith('temp-') ? undefined : q.id,
          type: q.type,
          title: q.title,
          description: q.description,
          required: q.required,
          options: q.options,
          validation: q.validation,
          order: q.order
        }))
      });

      // ⚠️ NÃO recarregar a seção aqui - manter o estado local
      // Apenas marcar como salvo e atualizar contagem na sidebar
      setHasUnsavedChanges(false);
      
      // Atualizar contagem na sidebar APÓS salvar
      const updatedSectionsList = [...sectionsList];
      updatedSectionsList[currentSectionIndex].questionCount = currentSection.questions.length;
      setSectionsList(updatedSectionsList);
      

      
    } catch (error) {
      console.error('❌ Erro ao salvar seção:', error);
      alert('Erro ao salvar alterações. Tente novamente.');
    } finally {
      setIsSaving(false);
    }
  }, [currentSection, hasUnsavedChanges]);

  // Auto-save functionality
  /*
  useEffect(() => {
    if (hasUnsavedChanges && currentSection && !isSaving) {

      
      if (autoSaveTimer.current) {
        clearTimeout(autoSaveTimer.current);

      }
      
      autoSaveTimer.current = setTimeout(() => {

        saveCurrentSection();
      }, 5000);
    }
    
    return () => {
      if (autoSaveTimer.current) {
        clearTimeout(autoSaveTimer.current);
      }
    };
  }, [hasUnsavedChanges, currentSection, isSaving, saveCurrentSection]);
  */

  // Salvar antes de sair da página
  useEffect(() => {
    const handleBeforeUnload = (e: BeforeUnloadEvent) => {
      if (hasUnsavedChanges) {
        e.preventDefault();
        e.returnValue = '';
        saveCurrentSection();
      }
    };

    window.addEventListener('beforeunload', handleBeforeUnload);
    return () => window.removeEventListener('beforeunload', handleBeforeUnload);
  }, [hasUnsavedChanges]);

  // Carregar dados do formulário
  useEffect(() => {
    const loadFormData = async () => {
      try {
        setIsLoading(true);
        
        // Buscar dados básicos do formulário
        const form = await formsService.getForm(formId);
        setFormData({
          id: form.id,
          title: form.title,
          description: form.description || '',
          color: form.folder_color,
          icon: form.icon
        });
        
        // Buscar seções do formulário
        const sectionsData = await formsService.getSections(formId);
        
        // Se não há seções, criar uma seção inicial
        if (sectionsData.sections.length === 0) {
          await formsService.createSection(formId, {
            title: 'Seção 1: Informações Básicas',
            description: 'Colete informações básicas do usuário',
            order: 1,
            questions: []
          });
          
          // Recarregar dados após criar seção inicial
          const updatedSectionsData = await formsService.getSections(formId);
          setSectionsList(updatedSectionsData.sections.map((section: any) => ({
            id: section.id,
            title: section.title,
            description: section.description,
            order: section.order,
            questionCount: section.questions.length
          })));
        } else {
          setSectionsList(sectionsData.sections.map((section: any) => ({
            id: section.id,
            title: section.title,
            description: section.description,
            order: section.order,
            questionCount: section.questions.length
          })));
        }
        
      } catch (error) {
        console.error('Erro ao carregar formulário:', error);
      } finally {
        setIsLoading(false);
      }
    };

    loadFormData();
  }, [formId]);

  // Carregar seção atual quando index muda (mas NÃO quando sectionsList muda)
  useEffect(() => {
    const loadCurrentSection = async () => {
      if (sectionsList.length === 0) return;
      
      try {
        setIsSectionLoading(true);
        const sectionSummary = sectionsList[currentSectionIndex];
        const sectionData = await formsService.getSection(sectionSummary.id);
        setCurrentSection(sectionData);

      } catch (error) {
        console.error('Erro ao carregar seção:', error);
      } finally {
        setIsSectionLoading(false);
      }
    };

    loadCurrentSection();
  }, [currentSectionIndex]); // ⚠️ REMOVIDO sectionsList da dependência!

  // Carregar seção inicial quando sectionsList for carregado pela primeira vez
  useEffect(() => {
    if (sectionsList.length > 0 && !currentSection) {
      const loadInitialSection = async () => {
        try {
          setIsSectionLoading(true);
          const sectionSummary = sectionsList[0];
          const sectionData = await formsService.getSection(sectionSummary.id);
          setCurrentSection(sectionData);

        } catch (error) {
          console.error('Erro ao carregar seção inicial:', error);
        } finally {
          setIsSectionLoading(false);
        }
      };

      loadInitialSection();
    }
  }, [sectionsList.length, currentSection]);

  const handleAddQuestion = async (template: any) => {
    if (!currentSection) return;

    // ✨ OTIMISTA: Atualizar UI imediatamente
    const newQuestion: QuestionData = {
      id: `temp-${nextTempId}`,
      ...template.defaultData,
      order: currentSection.questions.length + 1
    };

    const updatedQuestions = [...currentSection.questions, newQuestion];
    
    // Atualizar estado local instantaneamente
    setCurrentSection({
      ...currentSection,
      questions: updatedQuestions
    });
    
    // Marcar como não salvo
    setHasUnsavedChanges(true);
    setNextTempId(prev => prev + 1);
  };

  const handleDragEnd = async (event: DragEndEvent) => {
    const { active, over } = event;

    if (active.id !== over?.id && currentSection) {
      // ✨ OTIMISTA: Atualizar UI imediatamente
      const questions = currentSection.questions;
      const oldIndex = questions.findIndex(q => q.id === active.id);
      const newIndex = questions.findIndex(q => q.id === over?.id);

      const reorderedQuestions = arrayMove(questions, oldIndex, newIndex).map((q, index) => ({
        ...q,
        order: index + 1
      }));

      // Atualizar estado local instantaneamente
      setCurrentSection({
        ...currentSection,
        questions: reorderedQuestions
      });
      
      // Marcar como não salvo
      setHasUnsavedChanges(true);
    }
  };

  const handleEditQuestion = (questionId: string) => {
    if (currentSection) {
      const question = currentSection.questions.find(q => q.id === questionId);
      if (question) {
        setEditingQuestion(question);
        setIsEditModalOpen(true);
      }
    }
  };

  const handleSaveQuestion = async (questionData: QuestionData) => {
    if (!currentSection) return;

    // ✨ OTIMISTA: Atualizar UI imediatamente
    const updatedQuestions = currentSection.questions.map(q => 
      q.id === questionData.id ? questionData : q
    );

    setCurrentSection({
      ...currentSection,
      questions: updatedQuestions
    });
    
    // Marcar como não salvo
    setHasUnsavedChanges(true);
  };

  const handleDeleteQuestion = async () => {
    if (!currentSection || !editingQuestion) return;

    // ✨ OTIMISTA: Atualizar UI imediatamente
    const updatedQuestions = currentSection.questions
      .filter(q => q.id !== editingQuestion.id)
      .map((q, index) => ({ ...q, order: index + 1 })); // Reordenar

    setCurrentSection({
      ...currentSection,
      questions: updatedQuestions
    });

    // Atualizar contagem na sidebar
    const updatedSectionsList = [...sectionsList];
    updatedSectionsList[currentSectionIndex].questionCount = updatedQuestions.length;
    setSectionsList(updatedSectionsList);
    
    // Marcar como não salvo
    setHasUnsavedChanges(true);
  };

  const handleAddSection = async () => {
    try {
      const newSectionNumber = sectionsList.length + 1;
      await formsService.createSection(formId, {
        title: `Seção ${newSectionNumber}`,
        description: `Descrição da seção ${newSectionNumber}`,
        order: newSectionNumber,
        questions: []
      });

      // Recarregar lista de seções
      const sectionsData = await formsService.getSections(formId);
      setSectionsList(sectionsData.sections.map((section: any) => ({
        id: section.id,
        title: section.title,
        description: section.description,
        order: section.order,
        questionCount: section.questions.length
      })));

      // Navegar para a nova seção
      setCurrentSectionIndex(sectionsList.length);
    } catch (error) {
      console.error('Erro ao adicionar seção:', error);
      alert('Erro ao adicionar seção. Tente novamente.');
    }
  };

  const handleNextSection = async () => {
    if (currentSectionIndex < sectionsList.length - 1) {
      // Salvar mudanças antes de navegar
      await saveCurrentSection();
      // Sincronizar IDs reais
      await syncRealIds();
      setCurrentSectionIndex(currentSectionIndex + 1);
    }
  };

  const handlePrevSection = async () => {
    if (currentSectionIndex > 0) {
      // Salvar mudanças antes de navegar
      await saveCurrentSection();
      // Sincronizar IDs reais
      await syncRealIds();
      setCurrentSectionIndex(currentSectionIndex - 1);
    }
  };

  const handleGoToSummary = async () => {
    // Salvar mudanças antes de ir para o resumo
    await saveCurrentSection();
    // Sincronizar IDs reais
    await syncRealIds();
    router.push(`/v1/forms/${formId}/summary`);
  };

  const handleSectionClick = async (newIndex: number) => {
    if (newIndex !== currentSectionIndex) {
      // Salvar mudanças antes de navegar
      await saveCurrentSection();
      // Sincronizar IDs reais
      await syncRealIds();
      setCurrentSectionIndex(newIndex);
    }
  };

  // Função para recarregar e sincronizar IDs reais do backend
  const syncRealIds = async () => {
    if (!currentSection) return;
    
    try {
      const updatedSection = await formsService.getSection(currentSection.id);
      setCurrentSection(updatedSection);
      
      // Atualizar contagem na lista de seções
      const updatedSectionsList = [...sectionsList];
      updatedSectionsList[currentSectionIndex].questionCount = updatedSection.questions.length;
      setSectionsList(updatedSectionsList);
      

    } catch (error) {
      console.error('❌ Erro ao sincronizar IDs:', error);
    }
  };

  if (isLoading) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600 mx-auto mb-4"></div>
          <p className="text-gray-600">Carregando formulário...</p>
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
              <h1 className="text-2xl font-bold text-gray-900">{formData.title}</h1>
              <p className="text-gray-600 mt-1">{formData.description}</p>
            </div>
            <div className="flex items-center justify-between">
              <button
                onClick={handleGoToSummary}
                disabled={isSaving}
                className="px-6 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 disabled:opacity-50 transition-colors"
              >
                Ir para Resumo
              </button>
              
              {hasUnsavedChanges && (
                <div className="flex items-center gap-2">
                  <div className="flex items-center gap-2 text-orange-600 bg-orange-50 px-3 py-1 rounded-lg">
                    <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L4.082 16.5c-.77.833.192 2.5 1.732 2.5z" />
                    </svg>
                    <span className="text-sm">Alterações não salvas</span>
                  </div>
                  
                  <button
                    onClick={saveCurrentSection}
                    disabled={isSaving}
                    className="px-3 py-1 bg-blue-600 text-white text-sm rounded hover:bg-blue-700 disabled:opacity-50"
                  >
                    💾 Salvar Agora
                  </button>
                </div>
              )}
              
              {isSaving && (
                <div className="flex items-center gap-2 text-blue-600 bg-blue-50 px-3 py-1 rounded-lg">
                  <div className="animate-spin rounded-full h-4 w-4 border-2 border-blue-600 border-t-transparent"></div>
                  <span className="text-sm">Salvando...</span>
                </div>
              )}
            </div>
          </div>
        </div>
      </div>

      <div className="max-w-7xl mx-auto px-6 py-6 flex gap-6">
        {/* Sidebar with Sections List */}
        {sectionsList.length > 1 && (
          <div className="w-64 bg-white rounded-lg shadow-sm border h-fit">
            <div className="p-4 border-b">
              <h3 className="font-semibold text-gray-900">Seções do Formulário</h3>
              <p className="text-sm text-gray-600 mt-1">{sectionsList.length} seções</p>
            </div>
            <div className="p-2">
              {sectionsList.map((section, index) => (
                <button
                  key={section.id}
                  onClick={() => handleSectionClick(index)}
                  disabled={isSaving}
                  className={`w-full text-left p-3 rounded-lg mb-2 transition-colors disabled:opacity-50 ${
                    index === currentSectionIndex
                      ? 'bg-blue-50 border border-blue-200 text-blue-900'
                      : 'hover:bg-gray-50 text-gray-700'
                  }`}
                >
                  <div className="font-medium text-sm truncate">{section.title}</div>
                  <div className="text-xs text-gray-500 mt-1">
                    {section.questionCount} pergunta{section.questionCount !== 1 ? 's' : ''}
                  </div>
                </button>
              ))}
              
              <button
                onClick={() => handleAddSection()}
                className="w-full p-3 border border-dashed border-gray-300 rounded-lg hover:border-blue-300 hover:bg-blue-50 transition-colors text-gray-600 hover:text-blue-600 text-sm flex items-center justify-center gap-2"
              >
                <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 6v6m0 0v6m0-6h6m-6 0H6" />
                </svg>
                Adicionar Seção
              </button>
            </div>
          </div>
        )}

        {/* Main Content */}
        <div className="flex-1">
          {/* Section Header */}
          {currentSection && (
            <div className="bg-white rounded-lg shadow-sm border p-6 mb-6">
              <div className="flex items-center justify-between mb-4">
                <div>
                  <h2 className="text-xl font-semibold text-gray-900">{currentSection.title}</h2>
                  <p className="text-gray-600 mt-1">{currentSection.description}</p>
                </div>
                <div className="text-sm text-gray-500">
                  Seção {currentSectionIndex + 1} de {sectionsList.length}
                </div>
              </div>
            </div>
          )}

          {/* Loading Section */}
          {isSectionLoading && (
            <div className="bg-white rounded-lg shadow-sm border p-6 mb-6">
              <div className="flex items-center justify-center py-8">
                <div className="animate-spin rounded-full h-6 w-6 border-b-2 border-blue-600 mr-3"></div>
                <p className="text-gray-600">Carregando seção...</p>
              </div>
            </div>
          )}

          {/* Questions */}
          {currentSection && !isSectionLoading && (
            <>
              <DndContext collisionDetection={closestCenter} onDragEnd={handleDragEnd}>
                <SortableContext
                  items={currentSection.questions.map(q => q.id)}
                  strategy={verticalListSortingStrategy}
                >
                  <div className="space-y-4 pl-8">
                    {currentSection.questions.map((question, index) => (
                      <SortableQuestion
                        key={question.id}
                        question={question}
                        onEdit={() => handleEditQuestion(question.id)}
                      />
                    ))}
                  </div>
                </SortableContext>
              </DndContext>
            </>
          )}

          {currentSection && currentSection.questions.length === 0 && !isSectionLoading && (
            <div className="bg-white rounded-lg border border-dashed border-gray-300 p-12 text-center">
              <svg className="w-12 h-12 text-gray-400 mx-auto mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 6v6m0 0v6m0-6h6m-6 0H6" />
              </svg>
              <h3 className="text-lg font-medium text-gray-900 mb-2">Nenhuma pergunta adicionada</h3>
              <p className="text-gray-500">Adicione perguntas usando o painel à direita.</p>
            </div>
          )}

          {/* Section Navigation */}
          {sectionsList.length > 1 && (
            <div className="mt-8 flex justify-between">
              <button
                onClick={handlePrevSection}
                disabled={currentSectionIndex === 0}
                className="px-4 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
              >
                ← Seção Anterior
              </button>
              <button
                onClick={handleNextSection}
                disabled={currentSectionIndex === sectionsList.length - 1}
                className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
              >
                Próxima Seção →
              </button>
            </div>
          )}
        </div>

        {/* Question Templates Sidebar */}
        <div className="w-80 bg-white rounded-lg shadow-sm border h-fit">
          <div className="p-4 border-b">
            <h3 className="font-semibold text-gray-900">Tipos de Pergunta</h3>
            <p className="text-sm text-gray-600 mt-1">Clique para adicionar à seção</p>
          </div>
          
          <div className="p-4 max-h-96 overflow-y-auto">
            <div className="space-y-4">
              {QUESTION_TEMPLATES.map((template) => (
                <button
                  key={template.type}
                  onClick={() => handleAddQuestion(template)}
                  disabled={!currentSection || isSectionLoading}
                  className="w-full text-left p-3 border border-gray-200 rounded-lg hover:border-blue-300 hover:bg-blue-50 transition-all group disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  <div className="flex items-center gap-3 mb-2">
                    <div className="text-blue-600 group-hover:text-blue-700">
                      {template.icon}
                    </div>
                    <div>
                      <h4 className="font-medium text-gray-900 text-sm">{template.title}</h4>
                    </div>
                  </div>
                  <p className="text-xs text-gray-600 mb-3">{template.description}</p>
                  <div className="bg-gray-50 rounded p-2">
                    {template.preview}
                  </div>
                </button>
              ))}
            </div>
          </div>
        </div>
      </div>

      {/* Question Edit Modal */}
      <QuestionEditModal
        question={editingQuestion}
        isOpen={isEditModalOpen}
        onClose={() => {
          setIsEditModalOpen(false);
          setEditingQuestion(null);
        }}
        onSave={handleSaveQuestion}
        onDelete={handleDeleteQuestion}
      />
    </div>
  );
}
