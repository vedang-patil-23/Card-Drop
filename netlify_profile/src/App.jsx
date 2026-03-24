import { useEffect, useState } from 'react'
import ProfilePage from './components/ProfilePage'
import NotFound    from './components/NotFound'

export default function App() {
  const [profileId, setProfileId] = useState(null)

  useEffect(() => {
    // Parse /profile/:id from the URL
    const path = window.location.pathname
    const match = path.match(/^\/profile\/([a-zA-Z0-9-]+)/)
    if (match) {
      setProfileId(match[1])
    } else {
      setProfileId(null)
    }
  }, [])

  if (profileId === null && window.location.pathname !== '/') {
    return <NotFound />
  }

  if (!profileId) {
    return (
      <div style={styles.landing}>
        <div style={styles.landingInner}>
          <GradientText style={{ fontSize: 42, fontWeight: 800 }}>CardDrop</GradientText>
          <p style={{ color: '#AAAAAF', marginTop: 12, fontSize: 16 }}>
            Digital Business Cards — Fast, Free, Beautiful
          </p>
          <p style={{ color: '#606070', marginTop: 24, fontSize: 13 }}>
            Scan a QR code to view a profile
          </p>
        </div>
      </div>
    )
  }

  return <ProfilePage profileId={profileId} />
}

function GradientText({ children, style }) {
  return (
    <span style={{
      background: 'linear-gradient(135deg, #6C63FF, #00D4FF)',
      WebkitBackgroundClip: 'text',
      WebkitTextFillColor: 'transparent',
      backgroundClip: 'text',
      ...style,
    }}>
      {children}
    </span>
  )
}

const styles = {
  landing: {
    minHeight: '100vh',
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    background: '#0A0A0F',
  },
  landingInner: {
    textAlign: 'center',
    padding: '40px 24px',
  },
}
