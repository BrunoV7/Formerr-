import { BaseQuestion, QuestionProps } from './BaseQuestion';

export function DropdownQuestion({ data, mode, onUpdate, onEdit }: QuestionProps) {
  const options = data.options?.choices || ['Selecione uma opção', 'Opção 1', 'Opção 2', 'Opção 3'];
  
  return (
    <BaseQuestion data={data} mode={mode} onUpdate={onUpdate} onEdit={onEdit}>
      <select
        className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-blue-500 bg-white"
        disabled={mode === 'edit'}
      >
        {options.map((option: string, index: number) => (
          <option key={index} value={index === 0 ? '' : option}>
            {option}
          </option>
        ))}
      </select>
    </BaseQuestion>
  );
}

export const DropdownTemplate = {
  title: "Lista Suspensa",
  description: "Menu dropdown com opções para seleção única",
  icon: (
    <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 9l4-4 4 4m0 6l-4 4-4-4" />
    </svg>
  ),
  preview: (
    <div className="text-xs text-gray-500 space-y-1">
      <div className="font-medium">Selecione seu país</div>
      <div className="border border-gray-200 rounded px-2 py-1 bg-white flex items-center justify-between">
        <span>Brasil</span>
        <svg className="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
        </svg>
      </div>
    </div>
  ),
  type: "dropdown",
  defaultData: {
    type: "dropdown",
    title: "Nova pergunta de lista suspensa",
    description: "",
    required: false,
    options: {
      choices: ["Selecione uma opção", "Opção 1", "Opção 2", "Opção 3"]
    }
  }
};
