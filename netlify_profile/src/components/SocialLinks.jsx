const PLATFORM_META = {
  linkedin:  { label: 'LinkedIn',    emoji: '💼', color: '#0077B5' },
  instagram: { label: 'Instagram',   emoji: '📸', color: '#E1306C' },
  twitter:   { label: 'X / Twitter', emoji: '🐦', color: '#1DA1F2' },
  tiktok:    { label: 'TikTok',      emoji: '🎵', color: '#010101' },
  facebook:  { label: 'Facebook',    emoji: '👥', color: '#1877F2' },
  youtube:   { label: 'YouTube',     emoji: '▶️', color: '#FF0000' },
  github:    { label: 'GitHub',      emoji: '💻', color: '#333333' },
  snapchat:  { label: 'Snapchat',    emoji: '👻', color: '#FFFC00' },
  website:   { label: 'Website',     emoji: '🌐', color: '#6C63FF' },
  calendly:  { label: 'Calendly',    emoji: '📅', color: '#006BFF' },
  cashapp:   { label: 'Cash App',    emoji: '💵', color: '#00D632' },
  venmo:     { label: 'Venmo',       emoji: '💸', color: '#3D95CE' },
}

export default function SocialLinks({ links, cardColor }) {
  const active = links.filter(l => l.isActive && l.url)

  if (!active.length) return null

  return (
    <div style={s.grid}>
      {active.map((link, i) => {
        const meta  = PLATFORM_META[link.platform] || { label: link.platform, emoji: '🔗', color: '#6C63FF' }
        const href  = link.url.startsWith('http') ? link.url : `https://${link.url}`

        return (
          <a
            key={i}
            href={href}
            target="_blank"
            rel="noopener noreferrer"
            style={{
              ...s.chip,
              borderColor: `${meta.color}40`,
              background:  `${meta.color}12`,
            }}
          >
            <span style={s.emoji}>{meta.emoji}</span>
            <span style={{ ...s.label, color: meta.color }}>
              {meta.label}
            </span>
          </a>
        )
      })}
    </div>
  )
}

const s = {
  grid: {
    display: 'flex',
    flexWrap: 'wrap',
    gap: 8,
  },
  chip: {
    display: 'flex',
    alignItems: 'center',
    gap: 6,
    padding: '7px 12px',
    borderRadius: 10,
    border: '1px solid',
    textDecoration: 'none',
    transition: 'opacity 0.2s',
  },
  emoji: {
    fontSize: 14,
    lineHeight: 1,
  },
  label: {
    fontSize: 12,
    fontWeight: 600,
  },
}
