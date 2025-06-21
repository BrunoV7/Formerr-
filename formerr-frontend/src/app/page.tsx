import Link from 'next/link';

export default function LandingPage() {
  return (
    <div className="min-h-screen flex flex-col items-center justify-center bg-gray-50">
      <div className="max-w-md w-full bg-white p-8 rounded-lg shadow-md">
        <h1 className="text-3xl font-bold text-center mb-6 text-gray-800">
          Formerr
        </h1>
        <p className="text-gray-600 text-center mb-8">
          Crie formulários incríveis e colete respostas facilmente
        </p>
        
        <Link 
          href="/login"
          className="w-full bg-blue-600 text-white py-3 px-4 rounded-md text-center block hover:bg-blue-700 transition-colors"
        >
          Fazer Login
        </Link>
      </div>
    </div>
  );
}
