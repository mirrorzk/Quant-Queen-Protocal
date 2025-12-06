'use client'
import { cn } from "@/lib/utils";
import Image from "next/image";
import Link from "next/link";
import { useState, useEffect } from "react";
import BlockchainDropdown from "./dropdown/block-chain-dropdown";
import { ConnectButton } from "@rainbow-me/rainbowkit";
export default function AppHeader() {
    const [fixedHeader, setFixedHeader] = useState(false);
    useEffect(() => {
        const handleScroll = () => {
            setFixedHeader(window.pageYOffset > 20);
        };
        handleScroll();

        window.addEventListener('scroll', handleScroll);
        return () => window.removeEventListener('scroll', handleScroll);
    }, []);

    return (
        <header
            className={cn(
                'w-full fixed top-0 left-0 z-50 transition-all pt-[8vw] pb-[1vw] px-[3vw] sm:px-[2vw] sm:py-[3vw] lg:px-6 lg:py-[1vw]',
                fixedHeader && 'bg-black rounded-b-2xl'
            )}
        >
                <div className="hidden  items-center justify-between sm:flex">
                    <div className="w-[30vw] sm:w-[20vw] md:w-[22vw] lg:w-[12vw] pr-[2vw] z-10 opacity-0">
                        <Link href="">
                            <Image src="/images/logo.svg" alt="logo" width={260} height={55} className="w-full h-auto" />
                        </Link>
                    </div>
                    <div className="hidden sm:flex text-white items-center  justify-end gap-4 lg:gap-[1.2vw] w-[62vw] sm:w-[75vw] lg:w-[60vw] md:w-[70vw] z-10">
                        <BlockchainDropdown />

                        <ConnectButton 
                            showBalance={false}
                            label="Connect Wallet "
                            chainStatus="none" 
                        
                        
                            />


                    </div>
                </div>
                
                <div className="flex flex-col  gap-[5vw] sm:hidden items-center justify-end">
                    <div className="flex gap-[6vw] items-center">
                        <div className="w-[35vw] sm:w-[20vw] md:w-[22vw] lg:w-[12vw] z-10">
                            <Link href="https://zerobase.pro">
                                <Image src="/images/logo.svg" alt="logo" width={260} height={55} className="w-full h-auto" />
                            </Link>
                        </div>
                        <ConnectButton
                            showBalance={false}
                            chainStatus="none"
                            label="Connect Wallet "
                        />
                    </div>
                     
                    <div className="flex items-center justify-center gap-4 px-6 pb-4">
                        <BlockchainDropdown />
                        
                    </div>
            </div>
        </header>
    );
}