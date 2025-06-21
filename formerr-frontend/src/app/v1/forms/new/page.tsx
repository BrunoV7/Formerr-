'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { formsService } from '@/services/api';

const EMOJI_OPTIONS = ['📝', '📋', '📊', '💬', '🎯', '📞', '🎓', '💼', '🏠', '❤️', '🔧', '⭐'];
const COLOR_OPTIONS = [
  { value: '#3B82F6', name: 'Azul' },
  { value: '#10B981', name: 'Verde' },
  { value: '#F59E0B', name: 'Amarelo' },
  { value: '#EF4444', name: 'Vermelho' },
  { value: '#8B5CF6', name: 'Roxo' },
  { value: '#06B6D4', name: 'Ciano' },
  { value: '#F97316', name: 'Laranja' },
  { value: '#EC4899', name: 'Rosa' },
];

export default function NewFormPage() {
  const router = useRouter();
  const [isLoading, setIsLoading] = useState(false);
  const [formData, setFormData] = useState({
    title: '',
    description: '',
    icon: '📝',
    folder_color: '#3B82F6'
  });

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!formData.title.trim()) {
      alert('Por favor, insira um título para o formulário');
      return;
    }

    setIsLoading(true);

    try {
      const response = await formsService.create({
        title: formData.title.trim(),
        description: formData.description.trim() || undefined,
        icon: formData.icon,
        folder_color: formData.folder_color
      });

      // Redireciona para a página de edição do formulário criado
      router.push(`/v1/forms/${response.formId}/edit`);
    } catch (error) {
      console.error('Erro ao criar formulário:', error);
      alert('Erro ao criar formulário. Tente novamente.');
    } finally {
      setIsLoading(false);
    }
  };

  const handleCancel = () => {
    router.push('/v1/forms');
  };

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-white shadow-sm border-b">
        <div className="max-w-4xl mx-auto px-6 py-4">
          <div className="flex items-center justify-between">
            <div>
              <h1 className="text-2xl font-bold text-gray-900">Criar Novo Formulário</h1>
              <p className="text-gray-600 mt-1">Configure as informações básicas do seu formulário</p>
            </div>
            <button
              onClick={handleCancel}
              className="text-gray-500 hover:text-gray-700 transition-colors"
            >
              <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>
          </div>
        </div>
      </div>

      {/* Form */}
      <div className="max-w-2xl mx-auto px-6 py-8">
        <form onSubmit={handleSubmit} className="bg-white rounded-lg shadow-sm border p-8 space-y-6">
          {/* Título */}
          <div>
            <label htmlFor="title" className="block text-sm font-medium text-gray-700 mb-2">
              Título do Formulário *
            </label>
            <input
              type="text"
              id="title"
              value={formData.title}
              onChange={(e) => setFormData({ ...formData, title: e.target.value })}
              placeholder="Ex: Pesquisa de Satisfação, Formulário de Contato..."
              className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors"
              maxLength={255}
              required
            />
            <p className="text-sm text-gray-500 mt-1">
              {formData.title.length}/255 caracteres
            </p>
          </div>

          {/* Descrição */}
          <div>
            <label htmlFor="description" className="block text-sm font-medium text-gray-700 mb-2">
              Descrição (opcional)
            </label>
            <textarea
              id="description"
              value={formData.description}
              onChange={(e) => setFormData({ ...formData, description: e.target.value })}
              placeholder="Descreva brevemente o propósito deste formulário..."
              rows={3}
              className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors resize-none"
              maxLength={500}
            />
            <p className="text-sm text-gray-500 mt-1">
              {formData.description.length}/500 caracteres
            </p>
          </div>

          {/* Ícone */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-3">
              Ícone do Formulário
            </label>
            <div className="grid grid-cols-6 gap-3">
              {EMOJI_OPTIONS.map((emoji) => (
                <button
                  key={emoji}
                  type="button"
                  onClick={() => setFormData({ ...formData, icon: emoji })}
                  className={`
                    w-12 h-12 rounded-lg border-2 flex items-center justify-center text-xl transition-all
                    ${formData.icon === emoji
                      ? 'border-blue-500 bg-blue-50'
                      : 'border-gray-200 hover:border-gray-300 hover:bg-gray-50'
                    }
                  `}
                >
                  {emoji}
                </button>
              ))}
            </div>
          </div>

          {/* Cor da Pasta */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-3">
              Cor da Pasta
            </label>
            <div className="grid grid-cols-4 gap-3">
              {COLOR_OPTIONS.map((color) => (
                <button
                  key={color.value}
                  type="button"
                  onClick={() => setFormData({ ...formData, folder_color: color.value })}
                  className={`
                    p-3 rounded-lg border-2 flex items-center gap-3 transition-all
                    ${formData.folder_color === color.value
                      ? 'border-gray-400 bg-gray-50'
                      : 'border-gray-200 hover:border-gray-300'
                    }
                  `}
                >
                  <div
                    className="w-4 h-4 rounded-full"
                    style={{ backgroundColor: color.value }}
                  />
                  <span className="text-sm text-gray-700">{color.name}</span>
                </button>
              ))}
            </div>
          </div>

          {/* Preview */}
          <div className="bg-gray-50 rounded-lg p-4">
            <p className="text-sm font-medium text-gray-700 mb-3">Preview:</p>
            <div className="bg-white rounded-lg shadow-sm border p-4">
              <div className="flex items-start gap-4">
                <div
                  className="w-3 h-3 rounded-full flex-shrink-0 mt-1"
                  style={{ backgroundColor: formData.folder_color }}
                />
                <div className="flex-1">
                  <div className="flex items-center gap-2">
                    <span className="text-lg">{formData.icon}</span>
                    <h3 className="font-medium text-gray-900">
                      {formData.title || 'Título do Formulário'}
                    </h3>
                  </div>
                  {formData.description && (
                    <p className="text-sm text-gray-600 mt-1">
                      {formData.description}
                    </p>
                  )}
                </div>
              </div>
            </div>
          </div>

          {/* Botões */}
          <div className="flex gap-4 pt-4">
            <button
              type="button"
              onClick={handleCancel}
              className="flex-1 px-6 py-3 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 transition-colors"
              disabled={isLoading}
            >
              Cancelar
            </button>
            <button
              type="submit"
              disabled={isLoading || !formData.title.trim()}
              className="flex-1 px-6 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors flex items-center justify-center gap-2"
            >
              {isLoading ? (
                <>
                  <svg className="w-4 h-4 animate-spin" fill="none" viewBox="0 0 24 24">
                    <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                    <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z" />
                  </svg>
                  Criando...
                </>
              ) : (
                'Criar Formulário'
              )}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
