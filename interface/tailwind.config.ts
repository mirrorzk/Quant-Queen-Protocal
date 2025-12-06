import type { Config } from "tailwindcss";
import tailwindcssAnimate from "tailwindcss-animate";

const config: Config = {
    darkMode: ["class"],
    content: [
    "./src/pages/**/*.{js,ts,jsx,tsx,mdx}",
    "./src/components/**/*.{js,ts,jsx,tsx,mdx}",
    "./src/app/**/*.{js,ts,jsx,tsx,mdx}",
  ],
  theme: {
    extend: {
      fontFamily: {
        main: ['Space Grotesk', 'sans-serif'],
      },
      colors: {
        primary: '#17260D',
        white: '#ffffff',
        black: '#000000',
        body: '#FCFCFC',
        blue: '#00D0EC',
        darkblue: '#10B7CD',
        blueVariant: '#00DAF7',
        lightblue: '#D9F5FB',
        navy: '#2200FF',
        darkOne: '#0F0F0F',
        darkTwo: '#3D0E0D',
        darkThree: '#72231C',
        bgLight: 'hsl(83, 60%, 94%)',
        gray: '#F5F5F5',
        disabledGray: '#ccc',
        darkgray: '#ccc',
        placeholder: '#ccc',
        grayText:'#64717B',
        gray2:"#f1f1f1",
        gray3: '#ACACAC',
        gray4: '#9D9C9C',
        gray5: '#E7E7E7',
        gray6: '#D5D5D5',
        gray7: '#87949E',
      },
      borderRadius: {
        'rounded-10': '10px',
        'rounded-40': '40px',
        xxs:'0.8vw',
        xs: '2vw',
        sm: '4vw',
        md: '5vw',
        lg: '6vw',
      },
     
      fontSize: {
        'xs-btn': '1.25vw',
        'btn': '1vw',
        'btn-md': '1.8vw',
        'btn-sm': '3.8vw',
        'black-btn': '0.6vw',
      },
      spacing: {
        'xs-btn-x': '0.8vw',
        'xs-btn-y': '0.4vw',
        'btn-x': '1.2vw',
        'btn-y': '0.4vw',
        'btn-x-md': '1.35vw',
        'btn-y-md': '0.5vw',
        'btn-x-sm': '3.5vw',
        'btn-y-sm': '1vw',
      },
    },
  },
  variants: {
    extend: {
      before: ['responsive'], 
    },
  },
  plugins: [tailwindcssAnimate],
};
export default config;
