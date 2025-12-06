import { useState, useRef, useEffect } from 'react';
import Image from 'next/image';
import { ChevronDown } from 'lucide-react';
import { useAccount, useChainId, useSwitchChain } from 'wagmi';
import { isTestDomain, log } from '@/lib/logger';
export interface Chain {
  name: string;
  icon: string;
  id?: number;
  chainId?: string;
}



const chains: Chain[] = [
  { 
    name: 'BNB Chain', 
    icon: '/images/icons/chains/bnb-icon.svg',
    id: 56,
    chainId: '0x38'
  }
];


export const defaultChains: Chain[] = isTestDomain()
  ? [...chains]  
  : chains;    
export default function BlockchainDropdown() {
  const [isOpen, setIsOpen] = useState(false);
  const [selectedChain, setSelectedChain] = useState<Chain>(defaultChains[0]);
  const dropdownRef = useRef<HTMLDivElement>(null);
  const {  isConnected,connector } = useAccount();
  const {  switchChain } = useSwitchChain(); 
  const chainId = useChainId(); 
  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (dropdownRef.current && !dropdownRef.current.contains(event.target as Node)) {
        setIsOpen(false);
      }
    };

    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);
  useEffect(() => {
   
    if(!isConnected || !connector){
      setSelectedChain(defaultChains[0]);
      if (switchChain) {
        switchChain({ chainId: 56 });
      }
    
      return;
    }
    
    const name = (connector.name ?? '').toLowerCase();
    if(name.includes('binance')){
      setSelectedChain(defaultChains[0]);
      if (switchChain) {
        switchChain({ chainId: 56 });
      }
      return;
    }
    const current = defaultChains.find(c => c.id === chainId);
    if (current) {
      setSelectedChain(current);
      if (switchChain) {
        switchChain({ chainId: current.id! });
      }
    }
  }, [isConnected,connector]);
  const handleChainSelect = (chain: Chain) => {
    log.debug("handleChainSelect: ",chain)
    setSelectedChain(chain);
    setIsOpen(false);
    if (switchChain) {
      switchChain({ chainId: chain.id! });
    }
  
    
  };

  return (
    <div className="relative text-[1.05vw] z-10" ref={dropdownRef}>
      <div className="dropdown">
        <button
          onClick={() => setIsOpen(!isOpen)}
          className={`flex items-center text-white bg-black border border-blue p-[10px_22px_10px_8px] 
            sm:p-[0.9vw_1vw_0.9vw_1vw] 
            md:p-[6px_8px_6px_8px]
            lg:p-[8px_10px_8px_10px]  
            2xl:p-[0.3vw_0.8vw_0.3vw_0.8vw]
            text-[3.5vw] sm:text-[2.5vw] 
            lg:text-[1.1vw] 
            md:text-[1.8vw]
            2xl:text-[0.8vw]
            rounded-[2vw] sm:rounded-[1vw] md:rounded-[1.2vw] lg:rounded-[0.8vw] 2xl:rounded-[0.6vw] focus:outline-none focus:shadow-none 
            active:bg-white active:text-black`}
        >
          <Image
            src={selectedChain.icon}
            alt={selectedChain.name}
            width={24}
            height={24}
            className="w-[4.6vw] sm:w-[3vw] lg:w-[1.8vw] 2xl:w-[1.4vw] mr-[1.4vw] sm:mr-[1vw] lg:mr-[0.5vw]"
          />
          <span className="whitespace-nowrap">{selectedChain.name}</span>
          <span className={`ml-[2vw] sm:ml-[0.7vw] rounded-full bg-lightblue flex items-center justify-center text-blue h-[3.6vw] sm:h-[2.2vw] lg:h-[1.6vw] 2xl:h-[1.2vw] w-[3.6vw] sm:w-[2.2vw] lg:w-[1.6vw] 2xl:w-[1.2vw] transition-colors duration-200 ${
            isOpen ? 'bg-blueVariant text-white' : ''
          }`}>
            <ChevronDown className={`w-[3.6vw] sm:w-[1.2vw] transition-transform duration-200 ${
              isOpen ? 'rotate-180' : ''
            }`} />
          </span>
        </button>

        {isOpen && (
          <ul className="absolute 
          
    top-full bottom-auto left-0 right-0 z-[9999] mt-[0.05vw] p-0 list-none border border-darkgray rounded-[1.5vw] sm:rounded-[0.5vw] text-white bg-black overflow-auto  text-[3.4vw] sm:text-[2.5vw] lg:text-[0.87vw]">
            {defaultChains.map((chain) => (
              <li
                key={chain.name}
                onClick={() => handleChainSelect(chain)}
                className="flex items-center cursor-pointer p-[1.2vw_2vw_1vw_1.5vw] sm:p-[0.7vw_1vw_0.6vw_1vw] lg:p-[0.51vw_0.5vw_0.5vw_1vw]   hover:bg-blue hover:text-black"
              >
                <Image
                  src={chain.icon}
                  alt={chain.name}
                  width={24}
                  height={24}
                  className="w-[4.4vw] sm:w-[2.4vw] lg:w-[1.68vw] h-[4.4vw] sm:h-[2.4vw] lg:h-[1.68vw] mr-[1.4vw] sm:mr-[1vw] lg:mr-[0.5vw] rounded-full"
                />
                <span className="truncate whitespace-nowrap">{chain.name}</span>
              </li>
            ))}
          </ul>
        )}
      </div>
    </div>
  );
}