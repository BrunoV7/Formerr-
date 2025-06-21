import { BaseQuestion, QuestionProps } from './BaseQuestion';

export function CheckboxQuestion({ data, mode, onUpdate, onEdit }: QuestionProps) {
  const options = data.options?.choices || ['Opção 1', 'Opção 2', 'Opção 3'];
  
  return (
    <BaseQuestion data={data} mode={mode} onUpdate={onUpdate} onEdit={onEdit}>
      <div className="space-y-2">
        {options.map((option: string, index: number) => (
          <label key={index} className="flex items-center space-x-3 cursor-pointer">
            <input
              type="checkbox"
              className="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded"
              disabled={mode === 'edit'}
            />
            <span className="text-sm text-gray-700">{option}</span>
          </label>
        ))}
      </div>
    </BaseQuestion>
  );
}

export const CheckboxTemplate = {
  title: "Caixas de Seleção",
  description: "Permite selecionar múltiplas opções de uma lista",
  icon: (
    <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4M7.835 4.697a3.42 3.42 0 001.946-.806 3.42 3.42 0 014.438 0 3.42 3.42 0 001.946.806 3.42 3.42 0 013.138 3.138 3.42 3.42 0 00.806 1.946 3.42 3.42 0 010 4.438 3.42 3.42 0 00-.806 1.946 3.42 3.42 0 01-3.138 3.138 3.42 3.42 0 00-1.946.806 3.42 3.42 0 01-4.438 0 3.42 3.42 0 00-1.946-.806 3.42 3.42 0 01-3.138-3.138 3.42 3.42 0 00-.806-1.946 3.42 3.42 0 010-4.438 3.42 3.42 0 00.806-1.946 3.42 3.42 0 013.138-3.138z" />
    </svg>
  ),
  preview: (
    <div className="text-xs text-gray-500 space-y-1">
      <div className="font-medium">Quais linguagens você conhece?</div>
      <div className="space-y-1">
        <div className="flex items-center gap-2">
          <div className="w-3 h-3 border border-gray-300 rounded"></div>
          <span>JavaScript</span>
        </div>
        <div className="flex items-center gap-2">
          <div className="w-3 h-3 border border-gray-300 rounded bg-blue-500"></div>
          <span>Python</span>
        </div>
      </div>
    </div>
  ),
  type: "checkbox",
  defaultData: {
    type: "checkbox",
    title: "Nova pergunta de múltipla seleção",
    description: "",
    required: false,
    options: {
      choices: ["Opção 1", "Opção 2", "Opção 3"]
    }
  }
};
