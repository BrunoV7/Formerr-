import { BaseQuestion, QuestionProps } from './BaseQuestion';

export function MultipleChoiceQuestion({ data, mode, onUpdate, onEdit }: QuestionProps) {
  const options = data.options?.choices || ['Opção 1', 'Opção 2', 'Opção 3'];
  
  return (
    <BaseQuestion data={data} mode={mode} onUpdate={onUpdate} onEdit={onEdit}>
      <div className="space-y-2">
        {options.map((option: string, index: number) => (
          <label key={index} className="flex items-center space-x-3 cursor-pointer">
            <input
              type="radio"
              name={`question-${data.id}`}
              className="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300"
              disabled={mode === 'edit'}
            />
            <span className="text-sm text-gray-700">{option}</span>
          </label>
        ))}
      </div>
    </BaseQuestion>
  );
}

export const MultipleChoiceTemplate = {
  title: "Múltipla Escolha",
  description: "Permite selecionar apenas uma opção de uma lista",
  icon: (
    <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
    </svg>
  ),
  preview: (
    <div className="text-xs text-gray-500 space-y-1">
      <div className="font-medium">Qual sua cor favorita?</div>
      <div className="space-y-1">
        <div className="flex items-center gap-2">
          <div className="w-3 h-3 border border-gray-300 rounded-full"></div>
          <span>Azul</span>
        </div>
        <div className="flex items-center gap-2">
          <div className="w-3 h-3 border border-gray-300 rounded-full bg-blue-500"></div>
          <span>Verde</span>
        </div>
      </div>
    </div>
  ),
  type: "multiple-choice",
  defaultData: {
    type: "multiple-choice",
    title: "Nova pergunta de múltipla escolha",
    description: "",
    required: false,
    options: {
      choices: ["Opção 1", "Opção 2", "Opção 3"]
    }
  }
};
