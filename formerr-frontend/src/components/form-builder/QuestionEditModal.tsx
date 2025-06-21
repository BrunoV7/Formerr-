'use client';

import { useState, useEffect } from 'react';
import { QuestionData } from './questions';

interface QuestionEditModalProps {
  question: QuestionData | null;
  isOpen: boolean;
  onClose: () => void;
  onSave: (questionData: QuestionData) => void;
  onDelete?: () => void;
}

export default function QuestionEditModal({
  question,
  isOpen,
  onClose,
  onSave,
  onDelete
}: QuestionEditModalProps) {
  const [formData, setFormData] = useState<QuestionData | null>(null);

  useEffect(() => {
    if (question) {
      setFormData({ ...question });
    }
  }, [question]);

  if (!isOpen || !formData) return null;

  const handleSave = () => {
    if (formData) {
      onSave(formData);
      onClose();
    }
  };

  const handleDelete = () => {
    if (onDelete && confirm('Tem certeza que deseja excluir esta pergunta?')) {
      onDelete();
      onClose();
    }
  };

  const renderOptionsEditor = () => {
    if (!['multiple-choice', 'checkbox', 'dropdown'].includes(formData.type)) {
      return null;
    }

    const options = formData.options?.choices || [];

    const addOption = () => {
      const newOptions = [...options, `Opção ${options.length + 1}`];
      setFormData({
        ...formData,
        options: { ...formData.options, choices: newOptions }
      });
    };

    const updateOption = (index: number, value: string) => {
      const newOptions = [...options];
      newOptions[index] = value;
      setFormData({
        ...formData,
        options: { ...formData.options, choices: newOptions }
      });
    };

    const removeOption = (index: number) => {
      const newOptions = options.filter((_: any, i: number) => i !== index);
      setFormData({
        ...formData,
        options: { ...formData.options, choices: newOptions }
      });
    };

    return (
      <div className="space-y-3">
        <label className="block text-sm font-medium text-gray-700">
          Opções de Resposta
        </label>
        
        {options.map((option: string, index: number) => (
          <div key={index} className="flex gap-2">
            <input
              type="text"
              value={option}
              onChange={(e) => updateOption(index, e.target.value)}
              className="flex-1 px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              placeholder={`Opção ${index + 1}`}
            />
            {options.length > 1 && (
              <button
                onClick={() => removeOption(index)}
                className="px-3 py-2 text-red-600 hover:bg-red-50 rounded-md transition-colors"
              >
                <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                </svg>
              </button>
            )}
          </div>
        ))}
        
        <button
          onClick={addOption}
          className="w-full px-3 py-2 border border-dashed border-gray-300 rounded-md hover:border-blue-300 hover:bg-blue-50 transition-colors text-gray-600 hover:text-blue-600 text-sm flex items-center justify-center gap-2"
        >
          <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 6v6m0 0v6m0-6h6m-6 0H6" />
          </svg>
          Adicionar Opção
        </button>
      </div>
    );
  };

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
      <div className="bg-white rounded-lg shadow-xl max-w-2xl w-full max-h-[90vh] overflow-y-auto">
        <div className="p-6 border-b">
          <div className="flex items-center justify-between">
            <h2 className="text-xl font-semibold text-gray-900">
              Editar Pergunta
            </h2>
            <button
              onClick={onClose}
              className="text-gray-400 hover:text-gray-600 transition-colors"
            >
              <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>
          </div>
        </div>

        <div className="p-6 space-y-6">
          {/* Título da Pergunta */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Título da Pergunta *
            </label>
            <input
              type="text"
              value={formData.title}
              onChange={(e) => setFormData({ ...formData, title: e.target.value })}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              placeholder="Digite o título da pergunta"
            />
          </div>

          {/* Descrição */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Descrição (opcional)
            </label>
            <textarea
              value={formData.description || ''}
              onChange={(e) => setFormData({ ...formData, description: e.target.value })}
              rows={3}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              placeholder="Adicione uma descrição ou instruções para a pergunta"
            />
          </div>

          {/* Obrigatória */}
          <div className="flex items-center">
            <input
              type="checkbox"
              id="required"
              checked={formData.required}
              onChange={(e) => setFormData({ ...formData, required: e.target.checked })}
              className="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded"
            />
            <label htmlFor="required" className="ml-2 block text-sm text-gray-700">
              Pergunta obrigatória
            </label>
          </div>

          {/* Editor de Opções */}
          {renderOptionsEditor()}

          {/* Validações para tipos específicos */}
          {formData.type === 'number' && (
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Valor Mínimo
                </label>
                <input
                  type="number"
                  value={formData.validation?.min || ''}
                  onChange={(e) => setFormData({
                    ...formData,
                    validation: { ...formData.validation, min: e.target.value ? parseFloat(e.target.value) : undefined }
                  })}
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                  placeholder="Min"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Valor Máximo
                </label>
                <input
                  type="number"
                  value={formData.validation?.max || ''}
                  onChange={(e) => setFormData({
                    ...formData,
                    validation: { ...formData.validation, max: e.target.value ? parseFloat(e.target.value) : undefined }
                  })}
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                  placeholder="Max"
                />
              </div>
            </div>
          )}

          {['short-text', 'long-text'].includes(formData.type) && (
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Comprimento Mínimo
                </label>
                <input
                  type="number"
                  value={formData.validation?.minLength || ''}
                  onChange={(e) => setFormData({
                    ...formData,
                    validation: { ...formData.validation, minLength: e.target.value ? parseInt(e.target.value) : undefined }
                  })}
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                  placeholder="Min"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Comprimento Máximo
                </label>
                <input
                  type="number"
                  value={formData.validation?.maxLength || ''}
                  onChange={(e) => setFormData({
                    ...formData,
                    validation: { ...formData.validation, maxLength: e.target.value ? parseInt(e.target.value) : undefined }
                  })}
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                  placeholder="Max"
                />
              </div>
            </div>
          )}
        </div>

        <div className="p-6 border-t bg-gray-50 flex justify-between">
          <div>
            {onDelete && (
              <button
                onClick={handleDelete}
                className="px-4 py-2 text-red-600 hover:bg-red-50 rounded-md transition-colors"
              >
                Excluir Pergunta
              </button>
            )}
          </div>
          
          <div className="flex gap-3">
            <button
              onClick={onClose}
              className="px-4 py-2 border border-gray-300 text-gray-700 rounded-md hover:bg-gray-50 transition-colors"
            >
              Cancelar
            </button>
            <button
              onClick={handleSave}
              disabled={!formData.title.trim()}
              className="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
            >
              Salvar Alterações
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
