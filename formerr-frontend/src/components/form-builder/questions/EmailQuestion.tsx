import { BaseQuestion, QuestionProps } from './BaseQuestion';

export function EmailQuestion({ data, mode, onUpdate, onEdit }: QuestionProps) {
  return (
    <BaseQuestion data={data} mode={mode} onUpdate={onUpdate} onEdit={onEdit}>
      <input
        type="email"
        placeholder="exemplo@email.com"
        className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
        disabled={mode === 'edit'}
      />
    </BaseQuestion>
  );
}

export const EmailTemplate = {
  title: "Email",
  description: "Campo específico para endereços de email com validação",
  icon: (
    <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M16 12a4 4 0 10-8 0 4 4 0 008 0zm0 0v1.5a2.5 2.5 0 005 0V12a9 9 0 10-9 9m4.5-1.206a8.959 8.959 0 01-4.5 1.207" />
    </svg>
  ),
  preview: (
    <div className="text-xs text-gray-500 space-y-1">
      <div className="font-medium">Seu email *</div>
      <div className="border border-gray-200 rounded px-2 py-1 bg-gray-50">
        exemplo@email.com
      </div>
    </div>
  ),
  type: "email",
  defaultData: {
    type: "email",
    title: "Endereço de email",
    description: "",
    required: true,
    options: {},
    validation: { format: "email" }
  }
};
