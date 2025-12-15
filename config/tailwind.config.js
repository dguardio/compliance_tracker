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
        // Dynamic Branding Colors (mapped to CSS variables injected by ApplicationHelper)
        primary: {
          50: 'var(--primary-50)',
          100: 'var(--primary-100)',
          200: 'var(--primary-200)',
          300: 'var(--primary-300)',
          400: 'var(--primary-400)',
          500: 'var(--primary-500)',
          600: 'var(--primary-600)', // Main Brand Color
          700: 'var(--primary-700)',
          800: 'var(--primary-800)',
          900: 'var(--primary-900)',
          DEFAULT: 'var(--primary-600)',
        },
        secondary: {
          DEFAULT: 'var(--secondary-color)',
          50: 'var(--secondary-50)',
          600: 'var(--secondary-color)',
        },
        accent: {
          DEFAULT: 'var(--accent-color)',
          50: 'var(--accent-50)',
          600: 'var(--accent-color)',
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
