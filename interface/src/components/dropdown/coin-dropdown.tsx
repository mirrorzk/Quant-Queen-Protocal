import { useState, useRef, useEffect } from 'react';
import Image from 'next/image';
import { ChevronDown } from 'lucide-react';
import { useMemo } from 'react';

export interface Coin {
  name: string;
  icon: string;
}

const defaultCoins: Coin[] = [
  {
    name: 'USDT',
    icon: '/images/icons/chains/usdt-icon.svg'
  }
];

export default function CoinDropdown() {
  const [isOpen, setIsOpen] = useState(false);

  const [selectedCoin, setSelectedCoin] = useState<Coin>(defaultCoins[0]);
  const dropdownRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (dropdownRef.current && !dropdownRef.current.contains(event.target as Node)) {
        setIsOpen(false);
      }
    };

    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  const filteredCoins = useMemo(() => {
   

    
    
   
    return defaultCoins;
  }, []);
  useEffect(() => {

      const fallbackCoin = defaultCoins.find(c => c.name === 'USDT')!;
      setSelectedCoin(fallbackCoin);
  }, []);
  const handleCoinSelect = (coin: Coin) => {
    setSelectedCoin(coin);
  
    setIsOpen(false);
  };

  return (
    <div className="relative text-[1.05vw] z-1" ref={dropdownRef}>
      <div className="dropdown">
        <button
          onClick={() => setIsOpen(!isOpen)}
          className={`flex items-center bg-white text-black text-[3.4vw] sm:text-[2vw] lg:text-[0.87vw] border border-darkgray rounded-[1.5vw] sm:rounded-[0.6vw] p-[2vw_2vw_1.5vw_1.5vw] sm:p-[0.7vw_0.5vw_0.6vw_0.7vw] min-w-[8.2vw] focus:outline-none focus:shadow-none active:bg-white`}
        >
          <Image
            src={selectedCoin.icon}
            alt={selectedCoin.name}
            width={24}
            height={24}
            className="w-[4.4vw] sm:w-[2.2vw] lg:w-[1.68vw] mr-[1.4vw] sm:mr-[0.5vw]"
          />
          <span className="truncate">{selectedCoin.name}</span>
          <span className={`ml-[1.8vw] sm:ml-[0.7vw] rounded-full bg-lightblue flex items-center justify-center w-[3.6vw] h-[3.6vw] sm:w-[2.2vw] sm:h-[2.2vw] lg:w-[1.46vw] lg:h-[1.46vw] text-blue transition-colors duration-200 ${isOpen ? 'bg-blueVariant text-white' : ''
            }`}>
            <ChevronDown className={` w-[3.2vw] h-[3.2vw] sm:w-[1.2vw] sm:h-[1.2vw] transition-transform duration-200 ${isOpen ? 'rotate-180' : ''
              }`} />
          </span>
        </button>

        {isOpen && (
          <ul className="absolute top-full left-0 right-0 z-[9999] mt-[0.05vw] p-0 list-none border border-darkgray rounded-[1.5vw] sm:rounded-[0.5vw] text-black bg-white overflow-auto text-[3.4vw] sm:text-[2.2vw] lg:text-[0.87vw]">
            {filteredCoins.map((coin) => (
              <li
                key={coin.name}
                onClick={() => handleCoinSelect(coin)}
                className="cursor-pointer   p-[1.5vw_2vw_1.2vw_1.5vw] sm:p-[0.51vw_0.5vw_0.5vw_0.9vw] hover:bg-lightblue flex items-center"
              >
                <Image
                  src={coin.icon}
                  alt={coin.name}
                  width={24}
                  height={24}
                  className="w-[4.4vw] sm:w-[2.2vw] lg:w-[1.68vw] h-[4.4vw] sm:h-[2.2vw] lg:h-[1.68vw] mr-[1.4vw] sm:mr-[0.5vw] rounded-full"
                />
                <span className="truncate">{coin.name}</span>
              </li>
            ))}
          </ul>
        )}
      </div>
    </div>
  );
}