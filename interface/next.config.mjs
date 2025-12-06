import createNextIntlPlugin from 'next-intl/plugin';

const withIntl = createNextIntlPlugin({
  locales: ['en', 'zh', 'ko'],
  defaultLocale: 'en'
});

/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,

  async rewrites() {
    const hostname = process.env.HOSTNAME || '';

    let SCAN_API_BASE = 'https://scan-api.zerobase.pro';
    let STAKE_API_BASE = 'https://stake-api.zerobase.pro';

    if (hostname.includes('website') || hostname.includes('localhost')) {
      SCAN_API_BASE = 'https://scan-api.zerobase.pro';
      STAKE_API_BASE = 'https://stake-api.zerobase.website';
    }

    return [
      {
        source: '/api/:path*',
        destination: `${SCAN_API_BASE}/api/v1/data/:path*`
      },
      {
        source: '/stake-api/:path*',
        destination: `${STAKE_API_BASE}/:path*`
      }
    ];
  }
};

export default withIntl(nextConfig);
