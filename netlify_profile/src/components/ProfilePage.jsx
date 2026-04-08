import { useEffect, useState } from 'react'
import { supabase } from '../supabase/client'
import LeadCaptureForm from './LeadCaptureForm'
import SocialLinks     from './SocialLinks'

export default function ProfilePage({ profileId }) {
  const [profile,      setProfile]      = useState(null)
  const [loading,      setLoading]      = useState(true)
  const [notFound,     setNotFound]     = useState(false)
  const [showLeadForm, setShowLeadForm] = useState(false)
  const [leadSent,     setLeadSent]     = useState(false)
  const [viewId,       setViewId]       = useState(null)

  useEffect(() => {
    if (!profileId) return
    fetchProfile()
    recordView()
  }, [profileId])

  async function fetchProfile() {
    try {
      const { data, error } = await supabase
        .from('profiles')
        .select('*')
        .eq('id', profileId)
        .maybeSingle()
      if (error || !data) setNotFound(true)
      else setProfile(data)
    } catch (_) { setNotFound(true) }
    finally { setLoading(false) }
  }

  async function recordView() {
    try {
      const ua         = navigator.userAgent
      const deviceName = getDeviceName(ua)
      let ip = ''
      try {
        const res = await fetch('https://api.ipify.org?format=json')
        const d   = await res.json()
        ip = d.ip || ''
      } catch (_) {}
      const { data } = await supabase.from('profile_views').insert({
        profile_id:    profileId,
        source:        'qr',
        country:       '',
        viewed_at:     new Date().toISOString(),
        ip_address:    ip,
        device_name:   deviceName,
        user_agent:    ua.slice(0, 250),
        contact_saved: false,
      }).select('id').single()
      if (data?.id) setViewId(data.id)
    } catch (_) {}
  }

  function getDeviceName(ua) {
    if (/iPhone/.test(ua))    return 'iPhone'
    if (/iPad/.test(ua))      return 'iPad'
    if (/Android/.test(ua)) {
      const m = ua.match(/Android[^;]*;\s*([^)]+)/)
      return m ? m[1].trim().slice(0, 40) : 'Android'
    }
    if (/Macintosh/.test(ua)) return 'Mac'
    if (/Windows/.test(ua))   return 'Windows PC'
    if (/Linux/.test(ua))     return 'Linux'
    return 'Unknown Device'
  }

  async function downloadVCard() {
    if (!profile) return
    if (viewId) {
      try {
        await supabase.from('profile_views')
          .update({ contact_saved: true })
          .eq('id', viewId)
      } catch (_) {}
    }
    const nameParts = (profile.display_name || '').trim().split(/\s+/)
    const firstName = nameParts.slice(0, -1).join(' ') || nameParts[0] || ''
    const lastName  = nameParts.length > 1 ? nameParts[nameParts.length - 1] : ''
    const lines = [
      'BEGIN:VCARD', 'VERSION:3.0',
      `FN:${profile.display_name || ''}`,
      `N:${lastName};${firstName};;;`,
    ]
    if (profile.job_title) lines.push(`TITLE:${profile.job_title}`)
    if (profile.company)   lines.push(`ORG:${profile.company}`)
    if (profile.email)     lines.push(`EMAIL;TYPE=INTERNET:${profile.email}`)
    if (profile.phone)     lines.push(`TEL;TYPE=CELL:${profile.phone}`)
    if (profile.website)   lines.push(`URL:${profile.website}`)
    if (profile.bio)       lines.push(`NOTE:${profile.bio}`)
    lines.push('END:VCARD')
    const blob = new Blob([lines.join('\r\n')], { type: 'text/vcard' })
    const url  = URL.createObjectURL(blob)
    const a    = document.createElement('a')
    a.href = url
    a.download = `${(profile.display_name || 'contact').replace(/\s+/g, '_')}.vcf`
    a.click()
    URL.revokeObjectURL(url)
  }

  // ── Loading ────────────────────────────────────────────────────────────────
  if (loading) return (
    <div style={s.page}>
      <div style={s.loader}>
        <div style={s.spinner} />
      </div>
    </div>
  )

  if (notFound) return (
    <div style={s.page}>
      <div style={s.notFound}>
        <div style={s.notFoundIcon}>?</div>
        <h2 style={s.notFoundTitle}>Profile Not Found</h2>
        <p style={s.notFoundSub}>This profile link may be invalid or removed.</p>
      </div>
    </div>
  )

  const socialLinks = Array.isArray(profile.social_links) ? profile.social_links : []

  return (
    <div style={s.page}>
      <div style={s.container}>

        {/* ── Avatar + Name ── */}
        <div style={s.hero}>
          <Avatar profile={profile} />
          <div style={s.heroInfo}>
            <h1 style={s.name}>{profile.display_name || 'No Name'}</h1>
            {(profile.job_title || profile.company) && (
              <p style={s.subtitle}>
                {[profile.job_title, profile.company].filter(Boolean).join(' · ')}
              </p>
            )}
          </div>
        </div>

        {/* ── Bio ── */}
        {profile.bio && <p style={s.bio}>{profile.bio}</p>}

        {/* ── Contact rows ── */}
        <div style={s.contactList}>
          {profile.email && (
            <a href={`mailto:${profile.email}`} style={s.contactRow}>
              <span style={s.contactIcon}>
                <EmailIcon />
              </span>
              <span style={s.contactText}>{profile.email}</span>
              <ChevronIcon />
            </a>
          )}
          {profile.phone && (
            <a href={`tel:${profile.phone}`} style={s.contactRow}>
              <span style={s.contactIcon}>
                <PhoneIcon />
              </span>
              <span style={s.contactText}>{profile.phone}</span>
              <ChevronIcon />
            </a>
          )}
          {profile.website && (
            <a
              href={profile.website.startsWith('http') ? profile.website : `https://${profile.website}`}
              target="_blank" rel="noopener noreferrer"
              style={s.contactRow}
            >
              <span style={s.contactIcon}>
                <GlobeIcon />
              </span>
              <span style={s.contactText}>{profile.website}</span>
              <ChevronIcon />
            </a>
          )}
        </div>

        {/* ── Social links ── */}
        {socialLinks.length > 0 && (
          <div style={s.socialSection}>
            <SocialLinks links={socialLinks} cardColor="255,255,255" />
          </div>
        )}

        {/* ── Action buttons ── */}
        <div style={s.actions}>
          <button onClick={downloadVCard} style={s.saveBtn}>
            Save Contact
          </button>
          <button onClick={() => setShowLeadForm(v => !v)} style={s.shareBtn}>
            Share My Info
          </button>
        </div>

        {/* ── Lead form ── */}
        {showLeadForm && !leadSent && (
          <LeadCaptureForm
            profileId={profileId}
            onSuccess={() => setLeadSent(true)}
            onClose={() => setShowLeadForm(false)}
          />
        )}

        {leadSent && (
          <div style={s.successCard}>
            <p style={s.successTitle}>Info sent!</p>
            <p style={s.successSub}>
              {profile.display_name || 'They'} will be in touch soon.
            </p>
          </div>
        )}

        {/* ── Branding ── */}
        <p style={s.brand}>
          Powered by <span style={s.brandName}>CardDrop</span>
        </p>
      </div>
    </div>
  )
}

// ── Avatar ─────────────────────────────────────────────────────────────────────

function Avatar({ profile }) {
  const [imgError, setImgError] = useState(false)
  const initial = (profile.display_name || '?')[0].toUpperCase()

  if (profile.photo_url && !imgError) {
    return (
      <img
        src={profile.photo_url}
        alt={profile.display_name}
        onError={() => setImgError(true)}
        style={av.img}
      />
    )
  }
  return (
    <div style={av.placeholder}>
      <span style={av.initial}>{initial}</span>
    </div>
  )
}

const av = {
  img: {
    width: 72, height: 72, borderRadius: '50%',
    objectFit: 'cover', flexShrink: 0,
    border: '2px solid rgba(255,255,255,0.08)',
  },
  placeholder: {
    width: 72, height: 72, borderRadius: '50%',
    background: '#2C2C2E',
    display: 'flex', alignItems: 'center', justifyContent: 'center',
    flexShrink: 0,
  },
  initial: {
    fontSize: 28, fontWeight: 700, color: '#FFFFFF',
    fontFamily: '-apple-system, BlinkMacSystemFont, "SF Pro Display", sans-serif',
  },
}

// ── SVG Icons ──────────────────────────────────────────────────────────────────

const EmailIcon = () => (
  <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
    <rect x="2" y="4" width="20" height="16" rx="2"/>
    <path d="M2 7l10 7 10-7"/>
  </svg>
)
const PhoneIcon = () => (
  <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
    <path d="M22 16.92v3a2 2 0 01-2.18 2 19.79 19.79 0 01-8.63-3.07A19.5 19.5 0 013.07 10.8a19.79 19.79 0 01-3.07-8.67A2 2 0 012 0h3a2 2 0 012 1.72c.127.96.361 1.903.7 2.81a2 2 0 01-.45 2.11L6.09 7.91a16 16 0 006 6l1.27-1.27a2 2 0 012.11-.45c.907.339 1.85.573 2.81.7A2 2 0 0122 14.92v2z"/>
  </svg>
)
const GlobeIcon = () => (
  <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
    <circle cx="12" cy="12" r="10"/>
    <line x1="2" y1="12" x2="22" y2="12"/>
    <path d="M12 2a15.3 15.3 0 014 10 15.3 15.3 0 01-4 10 15.3 15.3 0 01-4-10 15.3 15.3 0 014-10z"/>
  </svg>
)
const ChevronIcon = () => (
  <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#555" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
    <polyline points="9 18 15 12 9 6"/>
  </svg>
)

// ── Styles ─────────────────────────────────────────────────────────────────────

const font = '-apple-system, BlinkMacSystemFont, "SF Pro Text", "Helvetica Neue", Arial, sans-serif'

const s = {
  page: {
    minHeight: '100vh',
    background: '#000000',
    display: 'flex',
    alignItems: 'flex-start',
    justifyContent: 'center',
    padding: '48px 20px 80px',
    fontFamily: font,
  },
  container: {
    width: '100%',
    maxWidth: 390,
  },
  loader: {
    minHeight: '100vh',
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
  },
  spinner: {
    width: 32, height: 32,
    borderRadius: '50%',
    border: '2px solid #2C2C2E',
    borderTopColor: '#FFFFFF',
    animation: 'spin 0.7s linear infinite',
  },
  notFound: {
    minHeight: '100vh',
    display: 'flex',
    flexDirection: 'column',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 12,
    padding: '0 24px',
  },
  notFoundIcon: {
    width: 64, height: 64,
    borderRadius: '50%',
    background: '#1C1C1E',
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    fontSize: 28, color: '#555',
    fontWeight: 700,
  },
  notFoundTitle: { fontSize: 20, fontWeight: 700, color: '#FFFFFF', margin: 0 },
  notFoundSub:   { fontSize: 14, color: '#636366', margin: 0, textAlign: 'center' },

  // ── Hero (avatar + name)
  hero: {
    display: 'flex',
    alignItems: 'center',
    gap: 16,
    marginBottom: 20,
  },
  heroInfo: { flex: 1, minWidth: 0 },
  name: {
    fontSize: 24,
    fontWeight: 700,
    color: '#FFFFFF',
    margin: '0 0 4px',
    letterSpacing: '-0.3px',
    lineHeight: 1.2,
  },
  subtitle: {
    fontSize: 14,
    color: '#8E8E93',
    margin: 0,
    fontWeight: 400,
  },
  bio: {
    fontSize: 14,
    color: '#8E8E93',
    lineHeight: 1.6,
    margin: '0 0 20px',
  },

  // ── Contact rows
  contactList: {
    display: 'flex',
    flexDirection: 'column',
    gap: 1,
    background: '#1C1C1E',
    borderRadius: 12,
    overflow: 'hidden',
    marginBottom: 16,
  },
  contactRow: {
    display: 'flex',
    alignItems: 'center',
    gap: 12,
    padding: '14px 16px',
    background: '#1C1C1E',
    textDecoration: 'none',
    borderBottom: '0.5px solid rgba(255,255,255,0.06)',
    transition: 'background 0.15s',
    cursor: 'pointer',
  },
  contactIcon: {
    color: '#8E8E93',
    display: 'flex',
    alignItems: 'center',
    flexShrink: 0,
  },
  contactText: {
    flex: 1,
    fontSize: 15,
    color: '#FFFFFF',
    overflow: 'hidden',
    textOverflow: 'ellipsis',
    whiteSpace: 'nowrap',
    minWidth: 0,
  },

  // ── Social section
  socialSection: {
    marginBottom: 16,
  },

  // ── Actions
  actions: {
    display: 'flex',
    gap: 10,
    marginTop: 4,
    marginBottom: 32,
  },
  saveBtn: {
    flex: 1,
    height: 50,
    background: '#FFFFFF',
    border: 'none',
    borderRadius: 12,
    color: '#000000',
    fontSize: 15,
    fontWeight: 600,
    cursor: 'pointer',
    fontFamily: font,
    letterSpacing: '-0.1px',
    transition: 'opacity 0.15s',
  },
  shareBtn: {
    flex: 1,
    height: 50,
    background: 'transparent',
    border: '1px solid rgba(255,255,255,0.18)',
    borderRadius: 12,
    color: '#FFFFFF',
    fontSize: 15,
    fontWeight: 600,
    cursor: 'pointer',
    fontFamily: font,
    letterSpacing: '-0.1px',
  },

  // ── Success
  successCard: {
    padding: '20px 24px',
    background: '#1C1C1E',
    borderRadius: 12,
    textAlign: 'center',
    marginBottom: 16,
  },
  successTitle: { fontSize: 16, fontWeight: 700, color: '#FFFFFF', margin: '0 0 4px' },
  successSub:   { fontSize: 13, color: '#8E8E93', margin: 0 },

  // ── Brand
  brand: {
    textAlign: 'center',
    fontSize: 12,
    color: '#3A3A3C',
    margin: 0,
  },
  brandName: {
    color: '#636366',
    fontWeight: 600,
  },
}
