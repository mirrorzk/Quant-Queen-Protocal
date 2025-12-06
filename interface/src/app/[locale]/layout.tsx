import { NextIntlClientProvider } from 'next-intl';
import { notFound } from 'next/navigation';
import React from 'react';
import '@/app/globals.css';
import { log } from '@/lib/logger';
import AppHeader from '@/components/app-header';
import AppFooter from '@/components/app-footer';
import { Toaster } from 'react-hot-toast';
import { Providers } from '../provider';

export default async function LocaleLayout({
    children,
    params
}: {
    children: React.ReactNode;
    params: Promise<{ locale: string }>;
}) {
  const { locale } = await params; 
  let messages;
  try {
    messages = (await import(`../../../messages/${locale}.json`)).default;
  } catch (error) {
    log.error('Error importing messages:', error);
    notFound();
  }
 
  return (
    <html lang={locale}>
      <body
         className="font-main"
         >
        <NextIntlClientProvider locale={locale} messages={messages}>
        <Providers>
          
              <AppHeader />
            
              {children}

              <AppFooter />
              <Toaster/>
          </Providers>
        </NextIntlClientProvider>
      </body>
    </html>
  );
}
