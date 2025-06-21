import { BaseQuestion, QuestionProps } from './BaseQuestion';

export function NumberQuestion({ data, mode, onUpdate, onEdit }: QuestionProps) {
  return (
    <BaseQuestion data={data} mode={mode} onUpdate={onUpdate} onEdit={onEdit}>
      <input
        type="number"
        placeholder="Digite um número..."
        className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
        disabled={mode === 'edit'}
        min={data.validation?.min}
        max={data.validation?.max}
      />
    </BaseQuestion>
  );
}

export const NumberTemplate = {
  title: "Número",
  description: "Campo numérico com validação de min/max",
  icon: (
    <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M7 20l4-16m2 16l4-16M6 9h14M4 15h14" />
    </svg>
  ),
  preview: (
    <div className="text-xs text-gray-500 space-y-1">
      <div className="font-medium">Sua idade</div>
      <div className="border border-gray-200 rounded px-2 py-1 bg-gray-50 w-20">
        25
      </div>
    </div>
  ),
  type: "number",
  defaultData: {
    type: "number",
    title: "Nova pergunta numérica",
    description: "",
    required: false,
    options: {},
    validation: { min: 0, max: 999999 }
  }
};
