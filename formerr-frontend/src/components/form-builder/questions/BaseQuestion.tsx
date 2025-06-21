import { ReactNode } from 'react';

export interface QuestionData {
  id: string;
  type: string;
  title: string;
  description?: string;
  required: boolean;
  options?: Record<string, any>;
  validation?: Record<string, any>;
  order: number;
}

export interface QuestionProps {
  data: QuestionData;
  mode: 'edit' | 'response';
  onUpdate?: (data: Partial<QuestionData>) => void;
  onEdit?: () => void;
}

export interface QuestionTemplateProps {
  title: string;
  description: string;
  icon: ReactNode;
  preview: ReactNode;
  type: string;
  defaultData: Partial<QuestionData>;
}

export interface BaseQuestionProps {
  data: QuestionData;
  mode: 'edit' | 'response';
  onUpdate?: (data: Partial<QuestionData>) => void;
  onEdit?: () => void;
  children: ReactNode;
}

export function BaseQuestion({ data, mode, onUpdate, onEdit, children }: BaseQuestionProps) {
  return (
    <div className={`
      border rounded-lg p-4 transition-all
      ${mode === 'edit' 
        ? 'border-gray-200 hover:border-gray-300 bg-white hover:shadow-sm cursor-pointer' 
        : 'border-gray-200 bg-white'
      }
    `}>
      {mode === 'edit' && (
        <div className="flex items-center justify-between mb-3">
          <div className="flex items-center gap-2">
            <div className="w-2 h-2 rounded-full bg-gray-400" />
            <span className="text-xs text-gray-500 uppercase tracking-wide">
              {data.type.replace('-', ' ')}
            </span>
            {data.required && (
              <span className="text-xs text-red-500">*</span>
            )}
          </div>
          <button
            onClick={onEdit}
            className="text-gray-400 hover:text-gray-600 transition-colors"
          >
            <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
            </svg>
          </button>
        </div>
      )}
      
      <div className="space-y-3">
        <div>
          <h3 className="font-medium text-gray-900">
            {data.title}
            {mode === 'response' && data.required && (
              <span className="text-red-500 ml-1">*</span>
            )}
          </h3>
          {data.description && (
            <p className="text-sm text-gray-600 mt-1">{data.description}</p>
          )}
        </div>
        
        {children}
      </div>
      
      {mode === 'edit' && (
        <div className="mt-3 pt-3 border-t border-gray-100">
          <div className="flex items-center justify-between text-xs text-gray-500">
            <span>Clique para editar</span>
            <span>Ordem: {data.order}</span>
          </div>
        </div>
      )}
    </div>
  );
}
