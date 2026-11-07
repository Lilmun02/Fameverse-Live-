const PATHS = {
  home: 'm3 10 9-7 9 7v10a1 1 0 0 1-1 1h-5v-7H9v7H4a1 1 0 0 1-1-1Z',
  people: 'M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2M16 3a4 4 0 0 1 0 8M22 21v-2a4 4 0 0 0-3-3.87M9 11a4 4 0 1 0 0-8 4 4 0 0 0 0 8',
  search: 'm21 21-4.35-4.35M19 11a8 8 0 1 0-16 0 8 8 0 0 0 16 0',
  coins: 'M20 8c0 3-16 3-16 0s16-3 16 0ZM4 8v8c0 3 16 3 16 0V8M4 12c0 3 16 3 16 0',
  arrow: 'M7 17 17 7M7 7h10v10',
  chevron: 'm6 9 6 6 6-6',
  close: 'm6 6 12 12M6 18 18 6',
  logout: 'M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4M16 17l5-5-5-5M21 12H9',
  refresh: 'M20 7v5h-5M4 17v-5h5M6.09 6.09a8 8 0 0 1 13.64 4.32M17.91 17.91a8 8 0 0 1-13.64-4.32',
}

export default function WebIcon({ name, size = 20 }) {
  return <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.7" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><path d={PATHS[name] || PATHS.people} /></svg>
}
