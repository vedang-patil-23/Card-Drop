export default function NotFound() {
  return (
    <div style={{
      minHeight: '100vh',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      background: '#0A0A0F',
      padding: '40px 24px',
      textAlign: 'center',
    }}>
      <div>
        <span style={{ fontSize: 56 }}>🃏</span>
        <h1 style={{ fontSize: 24, fontWeight: 800, color: '#F0F0FF', marginTop: 20 }}>
          Page Not Found
        </h1>
        <p style={{ fontSize: 13, color: '#AAAAAF', marginTop: 10 }}>
          This profile link doesn't exist or has been removed.
        </p>
        <p style={{
          fontSize: 12, color: '#606070', marginTop: 32,
          background: 'linear-gradient(90deg, #6C63FF, #00D4FF)',
          WebkitBackgroundClip: 'text',
          WebkitTextFillColor: 'transparent',
          fontWeight: 700,
        }}>
          CardDrop
        </p>
      </div>
    </div>
  )
}
