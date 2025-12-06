import "./globals.css";

import '@rainbow-me/rainbowkit/styles.css';


export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
    
      <body
        className="font-main"
      >

        {children}
       
      </body>
    </html>
  );
}