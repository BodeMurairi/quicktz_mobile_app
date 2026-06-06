/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{js,ts,jsx,tsx}'],
  theme: {
    extend: {
      colors: {
        primary: {
          DEFAULT: '#2E5E99',
          50: '#EBF0F8',
          100: '#C8D8EE',
          200: '#A4BEDE',
          300: '#7BA4D0',
          400: '#578AC0',
          500: '#2E5E99',
          600: '#244C7D',
          700: '#1A3A61',
          800: '#0D2440',
          900: '#071526',
        },
        secondary: '#7BA4D0',
        background: '#E7F0FA',
        dark: '#0D2440',
        success: '#27AE60',
        warning: '#F39C12',
        error: '#E74C3C',
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', 'sans-serif'],
      },
      boxShadow: {
        card: '0 2px 12px rgba(46, 94, 153, 0.08)',
        modal: '0 8px 40px rgba(13, 36, 64, 0.18)',
      },
    },
  },
  plugins: [],
}
