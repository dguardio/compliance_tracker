const defaultTheme = require('tailwindcss/defaultTheme')

module.exports = {
  content: [
    './public/*.html',
    './app/helpers/**/*.rb',
    './app/javascript/**/*.js',
    './app/views/**/*.{erb,haml,html,slim}'
  ],
  theme: {
    extend: {
      fontFamily: {
        sans: ['Inter', ...defaultTheme.fontFamily.sans],
      },
      colors: {
        // "Trust & Wisdom" (Violet/Indigo)
        primary: {
          50: '#EEF2FF',
          100: '#E0E7FF',
          200: '#C7D2FE',
          300: '#A5B4FC',
          400: '#818CF8',
          500: '#6366F1',
          600: '#4F46E5', // Main Action
          700: '#4338CA',
          800: '#3730A3',
          900: '#312E81',
        },
        // "All Clear" (Mint/Teal)
        success: {
          50: '#ECFDF5',
          600: '#059669',
        },
        // "Needs Attention" (Tangerine/Amber)
        warning: {
          50: '#FFFBEB',
          500: '#F59E0B',
        },
        // "Critical" (Coral/Rose)
        danger: {
          50: '#FEF2F2',
          500: '#EF4444',
        }
      },
      borderRadius: {
        'card': '16px',
        'pill': '999px',
      },
      boxShadow: {
        'primary-glow': '0 4px 14px 0 rgba(79, 70, 229, 0.3)',
      }
    },
  },
  plugins: [
    require('@tailwindcss/forms'),
    require('@tailwindcss/typography'),
    require('@tailwindcss/container-queries'),
  ]
}
