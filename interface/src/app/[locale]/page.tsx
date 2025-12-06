"use client"
import React, { Suspense} from 'react';


import QQBContent from '@/components/qqb/qqb-content';

function HomeContent() {
  
  
  return (
    <div className="flex justify-center min-h-screen">
      <div className="w-full max-w-[94vw]  sm:max-w-[67vw] bg-white rounded-xs mt-[40vw] sm:mt-[12vw] lg:mt-[6vw]">
        <div className=" sm:max-w-[58vw] sm:mx-auto pt-[5vw] sm:pt-[2.2vw]">
          < QQBContent />
        </div>
      </div>
    </div>
  );
}

export default function Home() {
  return (
    <Suspense fallback={<div>Loading...</div>}>
      <HomeContent />
    </Suspense>
  );
}
