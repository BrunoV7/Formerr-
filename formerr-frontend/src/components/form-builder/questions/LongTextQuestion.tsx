import { BaseQuestion, QuestionProps } from './BaseQuestion';

export function LongTextQuestion({ data, mode, onUpdate, onEdit }: QuestionProps) {
  return (
    <BaseQuestion data={data} mode={mode} onUpdate={onUpdate} onEdit={onEdit}>
      <textarea
        rows={3}
        placeholder="Sua resposta aqui..."
        className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-blue-500 resize-none"
        disabled={mode === 'edit'}
      />
    </BaseQuestion>
  );
}

export const LongTextTemplate = {
  title: "Texto Longo",
  description: "Resposta em múltiplas linhas para comentários, feedback, etc.",
  icon: (
    <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 6h16M4 10h16M4 14h16M4 18h16" />
    </svg>
  ),
  preview: (
    <div className="text-xs text-gray-500 space-y-1">
      <div className="font-medium">Deixe seu comentário</div>
      <div className="border border-gray-200 rounded px-2 py-2 bg-gray-50 h-8">
        <div className="text-gray-400">Digite sua mensagem...</div>
      </div>
    </div>
  ),
  type: "long-text",
  defaultData: {
    type: "long-text",
    title: "Nova pergunta de texto longo",
    description: "",
    required: false,
    options: {},
    validation: { maxLength: 1000 }
  }
};
