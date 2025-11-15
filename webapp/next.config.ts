import type { NextConfig } from "next";

const nextConfig: NextConfig = {
<<<<<<< HEAD
  // Production optimizations
  reactStrictMode: true,
=======
  // Disable the built-in dev overlay in production
  devIndicators: {
    appIsrStatus: false,
  },
  
  // Production optimizations
  reactStrictMode: true,
  
  // Disable telemetry collection
  telemetry: false,
>>>>>>> origin/main

  // Image optimization
  images: {
    unoptimized: true,
  },
};

export default nextConfig;
