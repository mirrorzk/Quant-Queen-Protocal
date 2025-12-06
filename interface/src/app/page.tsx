'use client';

import { useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { redirect } from 'next/navigation';

export default function Page() {
  const router = useRouter();
  
  useEffect(() => {
   
      router.replace('/en');
    
  }, []);
    return redirect(`/en`);
  
}
