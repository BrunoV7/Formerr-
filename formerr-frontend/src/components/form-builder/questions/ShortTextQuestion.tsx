import { BaseQuestion, QuestionProps } from './BaseQuestion';

export function ShortTextQuestion({ data, mode, onUpdate, onEdit }: QuestionProps) {
  return (
    <BaseQuestion data={data} mode={mode} onUpdate={onUpdate} onEdit={onEdit}>
      <input
        type="text"
        placeholder="Sua resposta aqui..."
        className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
        disabled={mode === 'edit'}
      />
    </BaseQuestion>
  );
}

export const ShortTextTemplate = {
  title: "Texto Curto",
  description: "Resposta em uma linha para nome, email, etc.",
  icon: (
    <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 6h16M4 12h16M4 18h7" />
    </svg>
  ),
  preview: (
    <div className="text-xs text-gray-500 space-y-1">
      <div className="font-medium">Nome completo *</div>
      <div className="border border-gray-200 rounded px-2 py-1 bg-gray-50">
        Digite seu nome...
      </div>
    </div>
  ),
  type: "short-text",
  defaultData: {
    type: "short-text",
    title: "Nova pergunta de texto curto",
    description: "",
    required: false,
    options: {},
    validation: { maxLength: 255 }
  }
};
