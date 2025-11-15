import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // Production optimizations
  reactStrictMode: true,

  // Image optimization
  images: {
    unoptimized: true,
  },
};

export default nextConfig;
