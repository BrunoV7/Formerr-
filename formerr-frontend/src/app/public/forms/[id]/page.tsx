'use client';

import { useState, useEffect } from 'react';
import { useParams, useRouter } from 'next/navigation';
import { formsService } from '@/services/api';
import { FormPublic, Section, Question } from '@/types';
import { CheckIcon, ExclamationTriangleIcon } from '@heroicons/react/24/outline';

interface FormAnswer {
  question_id: string;
  value: string[];
}

interface FormSubmission {
  answers: FormAnswer[];
  respondent_email?: string;
}

export default function PublicFormPage() {
  const params = useParams();
  const router = useRouter();
  const formId = params.id as string;

  const [form, setForm] = useState<FormPublic | null>(null);
  const [answers, setAnswers] = useState<Record<string, string[]>>({});
  const [email, setEmail] = useState('');
  const [errors, setErrors] = useState<Record<string, string>>({});
  const [isLoading, setIsLoading] = useState(true);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [isSubmitted, setIsSubmitted] = useState(false);
  const [submitError, setSubmitError] = useState('');

  useEffect(() => {
    const loadForm = async () => {
      try {
        setIsLoading(true);
        const formData = await formsService.getPublic(formId);
        setForm(formData);
      } catch (error) {
        console.error('Erro ao carregar formulário:', error);
        setSubmitError('Formulário não encontrado ou não está público.');
      } finally {
        setIsLoading(false);
      }
    };

    loadForm();
  }, [formId]);

  const handleAnswerChange = (questionId: string, value: string | string[], questionType: string) => {
    const newAnswers = { ...answers };
    
    if (questionType === 'checkbox') {
      // Para checkbox, value é array
      newAnswers[questionId] = Array.isArray(value) ? value : [value];
    } else {
      // Para outros tipos, converter para array se necessário
      newAnswers[questionId] = Array.isArray(value) ? value : [value];
    }
    
    setAnswers(newAnswers);
    
    // Limpar erro se houver
    if (errors[questionId]) {
      const newErrors = { ...errors };
      delete newErrors[questionId];
      setErrors(newErrors);
    }
  };

  const validateForm = (): boolean => {
    const newErrors: Record<string, string> = {};
    
    if (!form) return false;

    // Verificar perguntas obrigatórias
    form.sections.forEach((section) => {
      section.questions.forEach((question) => {
        if (question.required) {
          const answer = answers[question.id];
          if (!answer || answer.length === 0 || (answer.length === 1 && !answer[0].trim())) {
            newErrors[question.id] = 'Esta pergunta é obrigatória';
          }
        }
      });
    });

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!validateForm()) {
      return;
    }

    try {
      setIsSubmitting(true);
      setSubmitError('');

      const submission: FormSubmission = {
        answers: Object.entries(answers).map(([question_id, value]) => ({
          question_id,
          value
        })),
        respondent_email: email || undefined
      };

      await formsService.submitResponse(formId, submission);
      setIsSubmitted(true);
    } catch (error) {
      console.error('Erro ao enviar formulário:', error);
      setSubmitError('Erro ao enviar formulário. Tente novamente.');
    } finally {
      setIsSubmitting(false);
    }
  };

  const renderQuestion = (question: Question) => {
    const value = answers[question.id] || [];
    const error = errors[question.id];

    switch (question.type) {
      case 'text':
      case 'short-text':
      case 'email':
      case 'number':
        return (
          <div key={question.id} className="space-y-2">
            <label className="block text-sm font-medium text-gray-700">
              {question.title}
              {question.required && <span className="text-red-500 ml-1">*</span>}
            </label>
            {question.description && (
              <p className="text-sm text-gray-600">{question.description}</p>
            )}
            <input
              type={question.type === 'email' ? 'email' : question.type === 'number' ? 'number' : 'text'}
              value={value[0] || ''}
              onChange={(e) => handleAnswerChange(question.id, e.target.value, question.type)}
              className={`w-full px-3 py-2 border rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 ${
                error ? 'border-red-500' : 'border-gray-300'
              }`}
              placeholder={question.description || ''}
            />
            {error && (
              <p className="text-sm text-red-600 flex items-center gap-1">
                <ExclamationTriangleIcon className="w-4 h-4" />
                {error}
              </p>
            )}
          </div>
        );

      case 'textarea':
      case 'long-text':
        return (
          <div key={question.id} className="space-y-2">
            <label className="block text-sm font-medium text-gray-700">
              {question.title}
              {question.required && <span className="text-red-500 ml-1">*</span>}
            </label>
            {question.description && (
              <p className="text-sm text-gray-600">{question.description}</p>
            )}
            <textarea
              value={value[0] || ''}
              onChange={(e) => handleAnswerChange(question.id, e.target.value, question.type)}
              rows={4}
              className={`w-full px-3 py-2 border rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 ${
                error ? 'border-red-500' : 'border-gray-300'
              }`}
              placeholder={question.description || ''}
            />
            {error && (
              <p className="text-sm text-red-600 flex items-center gap-1">
                <ExclamationTriangleIcon className="w-4 h-4" />
                {error}
              </p>
            )}
          </div>
        );

      case 'select':
      case 'dropdown':
        return (
          <div key={question.id} className="space-y-2">
            <label className="block text-sm font-medium text-gray-700">
              {question.title}
              {question.required && <span className="text-red-500 ml-1">*</span>}
            </label>
            {question.description && (
              <p className="text-sm text-gray-600">{question.description}</p>
            )}
            <select
              value={value[0] || ''}
              onChange={(e) => handleAnswerChange(question.id, e.target.value, question.type)}
              className={`w-full px-3 py-2 border rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 ${
                error ? 'border-red-500' : 'border-gray-300'
              }`}
            >
              <option value="">Selecione uma opção</option>
              {question.options?.choices && question.options.choices.length > 0 ? (
                question.options.choices.map((choice, index) => (
                  <option key={index} value={choice}>
                    {choice}
                  </option>
                ))
              ) : (
                <option disabled>Nenhuma opção configurada</option>
              )}
            </select>
            {error && (
              <p className="text-sm text-red-600 flex items-center gap-1">
                <ExclamationTriangleIcon className="w-4 h-4" />
                {error}
              </p>
            )}
          </div>
        );

      case 'radio':
      case 'multiple-choice':
        return (
          <div key={question.id} className="space-y-2">
            <label className="block text-sm font-medium text-gray-700">
              {question.title}
              {question.required && <span className="text-red-500 ml-1">*</span>}
            </label>
            {question.description && (
              <p className="text-sm text-gray-600">{question.description}</p>
            )}
            <div className="space-y-2">
              {question.options?.choices && question.options.choices.length > 0 ? (
                question.options.choices.map((choice, index) => (
                  <label key={index} className="flex items-center gap-2">
                    <input
                      type="radio"
                      name={question.id}
                      value={choice}
                      checked={value[0] === choice}
                      onChange={(e) => handleAnswerChange(question.id, e.target.value, question.type)}
                      className="text-blue-600 focus:ring-blue-500"
                    />
                    <span className="text-gray-700">{choice}</span>
                  </label>
                ))
              ) : (
                <div className="text-gray-500 italic">
                  Nenhuma opção configurada para esta pergunta
                </div>
              )}
            </div>
            {error && (
              <p className="text-sm text-red-600 flex items-center gap-1">
                <ExclamationTriangleIcon className="w-4 h-4" />
                {error}
              </p>
            )}
          </div>
        );

      case 'checkbox':
      case 'multiple-selection':
        return (
          <div key={question.id} className="space-y-2">
            <label className="block text-sm font-medium text-gray-700">
              {question.title}
              {question.required && <span className="text-red-500 ml-1">*</span>}
            </label>
            {question.description && (
              <p className="text-sm text-gray-600">{question.description}</p>
            )}
            <div className="space-y-2">
              {question.options?.choices && question.options.choices.length > 0 ? (
                question.options.choices.map((choice, index) => (
                  <label key={index} className="flex items-center gap-2">
                    <input
                      type="checkbox"
                      value={choice}
                      checked={value.includes(choice)}
                      onChange={(e) => {
                        const newValue = e.target.checked
                          ? [...value, choice]
                          : value.filter(v => v !== choice);
                        handleAnswerChange(question.id, newValue, question.type);
                      }}
                      className="text-blue-600 focus:ring-blue-500"
                    />
                    <span className="text-gray-700">{choice}</span>
                  </label>
                ))
              ) : (
                <div className="text-gray-500 italic">
                  Nenhuma opção configurada para esta pergunta
                </div>
              )}
            </div>
            {error && (
              <p className="text-sm text-red-600 flex items-center gap-1">
                <ExclamationTriangleIcon className="w-4 h-4" />
                {error}
              </p>
            )}
          </div>
        );

      default:
        return (
          <div key={question.id} className="space-y-2">
            <label className="block text-sm font-medium text-gray-700">
              {question.title}
              {question.required && <span className="text-red-500 ml-1">*</span>}
            </label>
            {question.description && (
              <p className="text-sm text-gray-600">{question.description}</p>
            )}
            <input
              type="text"
              value={value[0] || ''}
              onChange={(e) => handleAnswerChange(question.id, e.target.value, question.type)}
              className={`w-full px-3 py-2 border rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 ${
                error ? 'border-red-500' : 'border-gray-300'
              }`}
              placeholder={question.description || ''}
            />
            {error && (
              <p className="text-sm text-red-600 flex items-center gap-1">
                <ExclamationTriangleIcon className="w-4 h-4" />
                {error}
              </p>
            )}
            <p className="text-xs text-gray-500">Tipo de pergunta: {question.type}</p>
          </div>
        );
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

  if (submitError && !form) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-center">
          <ExclamationTriangleIcon className="w-12 h-12 text-red-500 mx-auto mb-4" />
          <h1 className="text-xl font-semibold text-gray-900 mb-2">Formulário não encontrado</h1>
          <p className="text-gray-600">{submitError}</p>
        </div>
      </div>
    );
  }

  if (isSubmitted) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-center">
          <CheckIcon className="w-16 h-16 text-green-500 mx-auto mb-4" />
          <h1 className="text-2xl font-bold text-gray-900 mb-2">Obrigado!</h1>
          <p className="text-gray-600 mb-6">Sua resposta foi enviada com sucesso.</p>
          <button
            onClick={() => router.push('/')}
            className="px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
          >
            Ir para página inicial
          </button>
        </div>
      </div>
    );
  }

  if (!form) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-center">
          <p className="text-red-600">Erro ao carregar formulário</p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50 py-8">
      <div className="max-w-2xl mx-auto px-4">
        {/* Header do formulário */}
        <div className="bg-white rounded-lg shadow-sm border p-8 mb-6">
          <h1 className="text-3xl font-bold text-gray-900 mb-4">{form.title}</h1>
          {form.description && (
            <p className="text-lg text-gray-600">{form.description}</p>
          )}
        </div>

        {/* Formulário */}
        <form onSubmit={handleSubmit} className="space-y-6">
          {/* Seções e perguntas */}
          {form.sections
            .sort((a, b) => a.order - b.order)
            .map((section) => (
              <div key={section.id} className="bg-white rounded-lg shadow-sm border p-6">
                <h2 className="text-xl font-semibold text-gray-900 mb-2">{section.title}</h2>
                {section.description && (
                  <p className="text-gray-600 mb-6">{section.description}</p>
                )}
                
                <div className="space-y-6">
                  {section.questions
                    .sort((a, b) => a.order - b.order)
                    .map((question) => renderQuestion(question))}
                </div>
              </div>
            ))}

          {/* Campo de email opcional */}
          <div className="bg-white rounded-lg shadow-sm border p-6">
            <h3 className="text-lg font-medium text-gray-900 mb-4">Informações de contato (opcional)</h3>
            <div className="space-y-2">
              <label className="block text-sm font-medium text-gray-700">
                Email para contato
              </label>
              <input
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                placeholder="seu@email.com"
              />
              <p className="text-sm text-gray-500">
                Seu email será usado apenas para comunicações relacionadas a este formulário.
              </p>
            </div>
          </div>

          {/* Erro de envio */}
          {submitError && (
            <div className="bg-red-50 border border-red-200 rounded-lg p-4">
              <div className="flex items-center gap-2">
                <ExclamationTriangleIcon className="w-5 h-5 text-red-500" />
                <p className="text-red-800">{submitError}</p>
              </div>
            </div>
          )}

          {/* Botão de envio */}
          <div className="bg-white rounded-lg shadow-sm border p-6">
            <button
              type="submit"
              disabled={isSubmitting}
              className="w-full bg-blue-600 text-white py-3 px-6 rounded-lg font-medium hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
            >
              {isSubmitting ? 'Enviando...' : 'Enviar Respostas'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
