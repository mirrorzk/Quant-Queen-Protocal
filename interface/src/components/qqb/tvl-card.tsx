"use client";

import Image from "next/image";

export default function TVLCard() {
  return (
    <div className="w-full overflow-hidden rounded-3xl bg-white shadow-[0_18px_45px_rgba(15,23,42,0.12)]">
      <div className="flex items-center justify-between bg-gradient-to-r from-[#166AA0] to-[#0D4264] px-6 py-4 sm:px-8 sm:py-[1.6vw]">
        <div className="flex items-center">
          <Image
            src="/images/icons/qqb/quant.svg"
            alt="Quant Queen Protocol"
            width={260}
            height={60}
            className="h-10 w-auto sm:h-[2.5vw]"
          />
        </div>

        <div className="rounded-full border-[#31A7F5] border-[1.89px] bg-gradient-to-r from-[#14151A] to-[#050A12] px-4 py-1.5 sm:px-8 sm:py-1 shadow-[0_0_20px_rgba(0,0,0,0.35)]">
          <div className="flex items-center gap-2 text-xs font-medium text-slate-100 sm:text-sm">
            <span className="uppercase tracking-[0.18em] text-[10px] sm:text-xs">
              APR: 
            </span>
            <span className="text-base font-semibold text-[#43B4FF] sm:text-lg">
              122%
            </span>
          </div>
        </div>
      </div>

      <div className="flex items-center gap-[1.2vw] bg-white px-6 py-4 sm:px-12 sm:py-5">
        <span className="text-[1.2vw] text-[#223451] sm:text-[1vw]">
          TVL:
        </span>
        <span className="text-[1.2vw] font-medium tracking-wide text-slate-900 sm:text-[1.4vw]">
          500,000,000
        </span>
      </div>
    </div>
  );
}
