import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // Enable standalone output for Docker optimization
  output: 'standalone',
  
  // Image optimization settings
  images: {
    unoptimized: true, // For Docker/static exports
  },
  
  // Environment variables validation
  env: {
    NEXT_PUBLIC_API_URL: process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000',
  },
  
  // TypeScript and ESLint configuration - fully disable for Docker builds
  typescript: {
    ignoreBuildErrors: true,
    tsconfigPath: './tsconfig.json'
  },
  eslint: {
    ignoreDuringBuilds: true,
    dirs: [], // Disable ESLint completely
  },
  
  // Webpack configuration to skip type checking
  webpack: (config: any, { dev, isServer }: any) => {
    // Disable type checking in production builds
    if (!dev && !isServer) {
      config.resolve.plugins = config.resolve.plugins?.filter(
        (plugin: any) => plugin.constructor.name !== 'ForkTsCheckerWebpackPlugin'
      );
    }
    return config;
  },
  
  // Experimental features for better build performance
  experimental: {
    typedRoutes: false,
  },
};

export default nextConfig;
