import { Button } from "@/components/ui/button"

interface FormBuilderProps {
  className?: string
}

export function FormBuilder({ className }: FormBuilderProps) {
  return (
    <div className={className}>
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">Criar Formulário</h1>
          <p className="text-muted-foreground">
            Construa formulários interativos para coletar dados
          </p>
        </div>
        <Button>Publicar</Button>
      </div>
      
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Sidebar - Form Settings */}
        <div className="lg:col-span-1">
          <div className="bg-card rounded-lg border p-6">
            <h3 className="font-semibold mb-4">Configurações</h3>
            <div className="space-y-4">
              <div>
                <label className="text-sm font-medium">Título do Formulário</label>
                <input 
                  type="text" 
                  className="w-full mt-1 px-3 py-2 border rounded-md"
                  placeholder="Digite o título..."
                />
              </div>
              <div>
                <label className="text-sm font-medium">Descrição</label>
                <textarea 
                  className="w-full mt-1 px-3 py-2 border rounded-md"
                  rows={3}
                  placeholder="Descrição opcional..."
                />
              </div>
            </div>
          </div>
        </div>

        {/* Main Area - Form Preview */}
        <div className="lg:col-span-2">
          <div className="bg-card rounded-lg border p-6 min-h-[500px]">
            <h3 className="font-semibold mb-4">Preview do Formulário</h3>
            <div className="text-center text-muted-foreground py-20">
              <p>Adicione seções e perguntas para ver o preview</p>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}
