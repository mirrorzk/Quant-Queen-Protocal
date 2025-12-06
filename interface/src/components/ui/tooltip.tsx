import { useState, useRef, useEffect } from 'react';

export default function Tooltip({
  content,
  children,
}: {
  content: React.ReactNode;
  children: React.ReactNode;
}) {
  const [visible, setVisible] = useState(false);
  const ref = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const handleClickOutside = (e: MouseEvent) => {
      if (ref.current && !ref.current.contains(e.target as Node)) {
        setVisible(false);
      }
    };
    document.addEventListener('click', handleClickOutside);
    return () => document.removeEventListener('click', handleClickOutside);
  }, []);

  return (
    <div
      ref={ref}
      className="relative inline-block"
      onMouseEnter={() => setVisible(true)}
      onMouseLeave={() => setVisible(false)}
      onClick={() => setVisible((v) => !v)}
    >
      {children}
      {visible && (
        <div className="leading-[1.2] sm:leading-[1.4] w-[35vw] sm:w-[20vw] lg:w-[10.4vw] overflow-visible bottom-[100%] -left-[800%] sm:bottom-auto sm:top-full absolute text-left z-[9999] sm:left-[0.4vw] p-[1vw] sm:p-[0.6vw] text-[2.5vw] sm:text-[1.2vw] lg:text-[0.68vw] text-[#676767] bg-white rounded-[1vw] sm:rounded-[0.5vw] shadow">
          {content}
        </div>
      )}
    </div>
  );
}
