/** @type {import('next').NextConfig} */
const nextConfig = {
  // Habilita standalone output para Docker
  output: 'standalone',
  
  // Configurações de imagem otimizadas
  images: {
    remotePatterns: [
      {
        protocol: 'https',
        hostname: '**',
      },
    ],
    unoptimized: true, // Para Docker/static exports
  },
  
  // Configurações de ambiente
  env: {
    // Variáveis de ambiente customizadas
    NEXT_PUBLIC_API_URL: process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000',
    API_URL: process.env.API_URL || 'http://localhost:8000',
  },
  
  // TypeScript e ESLint - desabilitados para builds Docker
  typescript: {
    ignoreBuildErrors: true,
    tsconfigPath: './tsconfig.json'
  },
  eslint: {
    ignoreDuringBuilds: true,
    dirs: [], // Desabilita ESLint completamente
  },
  
  // Headers de segurança
  async headers() {
    return [
      {
        source: '/(.*)',
        headers: [
          {
            key: 'X-Frame-Options',
            value: 'DENY',
          },
          {
            key: 'X-Content-Type-Options',
            value: 'nosniff',
          },
          {
            key: 'Referrer-Policy',
            value: 'strict-origin-when-cross-origin',
          },
        ],
      },
    ]
  },
  
  // Configuração Webpack para pular verificação de tipos
  webpack: (config, { dev, isServer }) => {
    // Desabilita verificação de tipos em builds de produção
    if (!dev && !isServer) {
      config.resolve.plugins = config.resolve.plugins?.filter(
        (plugin) => plugin.constructor.name !== 'ForkTsCheckerWebpackPlugin'
      );
    }
    return config;
  },
  
  // Recursos experimentais para melhor performance de build
  experimental: {
    typedRoutes: false,
  },
}

module.exports = nextConfig
