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

      if (error || !data) {
        setNotFound(true)
      } else {
        setProfile(data)
      }
    } catch (err) {
      console.error('fetchProfile error:', err)
      setNotFound(true)
    } finally {
      setLoading(false)
    }
  }

  async function recordView() {
    try {
      await supabase.from('profile_views').insert({
        profile_id: profileId,
        source:     'qr',
        country:    '',
        viewed_at:  new Date().toISOString(),
      })
    } catch (_) {}
  }

  function downloadVCard() {
    if (!profile) return
    const vcard = [
      'BEGIN:VCARD',
      'VERSION:3.0',
      `FN:${profile.display_name  || ''}`,
      `TITLE:${profile.job_title  || ''}`,
      `ORG:${profile.company      || ''}`,
      `EMAIL:${profile.email      || ''}`,
      `TEL:${profile.phone        || ''}`,
      `URL:${profile.website      || ''}`,
      `NOTE:${profile.bio         || ''}`,
      'END:VCARD',
    ].join('\n')

    const blob = new Blob([vcard], { type: 'text/vcard' })
    const url  = URL.createObjectURL(blob)
    const a    = document.createElement('a')
    a.href     = url
    a.download = `${(profile.display_name || 'contact').replace(/\s+/g, '_')}.vcf`
    a.click()
    URL.revokeObjectURL(url)
  }

  // ── Render ────────────────────────────────────────────────────────────────

  if (loading) {
    return (
      <div style={s.center}>
        <div style={s.spinner} />
      </div>
    )
  }

  if (notFound) {
    return (
      <div style={s.center}>
        <div style={{ textAlign: 'center', padding: '40px 24px' }}>
          <span style={{ fontSize: 48 }}>👤</span>
          <h2 style={{ fontSize: 20, fontWeight: 700, color: '#F0F0FF', marginTop: 16 }}>
            Profile Not Found
          </h2>
          <p style={{ fontSize: 13, color: '#AAAAAF', marginTop: 8 }}>
            This profile link may be invalid or removed.
          </p>
        </div>
      </div>
    )
  }

  const cardColor = hexToRgb(profile.profile_color || '#6C63FF')
  const socialLinks = Array.isArray(profile.social_links) ? profile.social_links : []

  return (
    <div style={s.page}>
      <div style={s.container}>

        {/* Profile Card */}
        <div style={{
          ...s.card,
          background: `linear-gradient(135deg, rgba(${cardColor},0.18) 0%, rgba(13,13,26,0.95) 100%)`,
          borderColor: `rgba(${cardColor},0.35)`,
          boxShadow:  `0 24px 60px rgba(${cardColor},0.15)`,
        }}>
          {/* Glow orb */}
          <div style={{
            ...s.glowOrb,
            background: `radial-gradient(circle, rgba(${cardColor},0.15) 0%, transparent 70%)`,
          }} />

          {/* Header */}
          <div style={s.header}>
            <Avatar profile={profile} cardColor={cardColor} />
            <div style={s.headerInfo}>
              <h1 style={s.name}>{profile.display_name || 'No Name'}</h1>
              {(profile.job_title || profile.company) && (
                <p style={s.subtitle}>
                  {[profile.job_title, profile.company].filter(Boolean).join(' · ')}
                </p>
              )}
            </div>
          </div>

          {/* Bio */}
          {profile.bio && <p style={s.bio}>{profile.bio}</p>}

          {/* Contact info */}
          <div style={s.contactRow}>
            {profile.email && (
              <a href={`mailto:${profile.email}`} style={s.contactChip}>
                <span>✉️</span>
                <span style={s.contactChipText}>{profile.email}</span>
              </a>
            )}
            {profile.phone && (
              <a href={`tel:${profile.phone}`} style={s.contactChip}>
                <span>📞</span>
                <span style={s.contactChipText}>{profile.phone}</span>
              </a>
            )}
            {profile.website && (
              <a
                href={profile.website.startsWith('http') ? profile.website : `https://${profile.website}`}
                target="_blank"
                rel="noopener noreferrer"
                style={s.contactChip}
              >
                <span>🌐</span>
                <span style={s.contactChipText}>{profile.website}</span>
              </a>
            )}
          </div>

          {/* Social links */}
          {socialLinks.length > 0 && (
            <>
              <div style={s.divider} />
              <SocialLinks links={socialLinks} cardColor={cardColor} />
            </>
          )}
        </div>

        {/* Action buttons */}
        <div style={s.actions}>
          <button onClick={downloadVCard} style={s.saveBtn}>
            <span>📥</span>
            <span>Save Contact</span>
          </button>
          <button
            onClick={() => setShowLeadForm(v => !v)}
            style={s.connectBtn}
          >
            <span>🤝</span>
            <span>Share My Info</span>
          </button>
        </div>

        {/* Lead form */}
        {showLeadForm && !leadSent && (
          <LeadCaptureForm
            profileId={profileId}
            onSuccess={() => setLeadSent(true)}
            onClose={() => setShowLeadForm(false)}
          />
        )}

        {leadSent && (
          <div style={s.successCard}>
            <span style={{ fontSize: 32 }}>🎉</span>
            <p style={s.successText}>Your info has been sent!</p>
            <p style={s.successSub}>
              {profile.display_name || 'They'} will reach out to you soon.
            </p>
          </div>
        )}

        {/* Branding */}
        <p style={s.brand}>
          Powered by{' '}
          <span style={{
            background: 'linear-gradient(90deg, #6C63FF, #00D4FF)',
            WebkitBackgroundClip: 'text',
            WebkitTextFillColor: 'transparent',
            fontWeight: 700,
          }}>
            CardDrop
          </span>
        </p>
      </div>
    </div>
  )
}

// ── Avatar ─────────────────────────────────────────────────────────────────────

function Avatar({ profile, cardColor }) {
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
    <div style={{
      ...av.placeholder,
      background: `linear-gradient(135deg, rgb(${cardColor}), rgba(${cardColor},0.5))`,
    }}>
      {initial}
    </div>
  )
}

const av = {
  img: {
    width: 80, height: 80, borderRadius: '50%',
    objectFit: 'cover', border: '2px solid rgba(255,255,255,0.1)', flexShrink: 0,
  },
  placeholder: {
    width: 80, height: 80, borderRadius: '50%',
    display: 'flex', alignItems: 'center', justifyContent: 'center',
    fontSize: 30, fontWeight: 700, color: '#fff', flexShrink: 0,
  },
}

// ── Helpers ────────────────────────────────────────────────────────────────────

function hexToRgb(hex) {
  try {
    const c = hex.replace('#', '')
    return `${parseInt(c.slice(0,2),16)},${parseInt(c.slice(2,4),16)},${parseInt(c.slice(4,6),16)}`
  } catch (_) { return '108,99,255' }
}

// ── Styles ─────────────────────────────────────────────────────────────────────

const s = {
  page:     { minHeight: '100vh', background: '#0A0A0F', display: 'flex', alignItems: 'flex-start', justifyContent: 'center', padding: '24px 16px 60px' },
  container:{ width: '100%', maxWidth: 420 },
  center:   { minHeight: '100vh', display: 'flex', alignItems: 'center', justifyContent: 'center' },
  spinner:  { width: 40, height: 40, borderRadius: '50%', border: '3px solid #1C1C27', borderTopColor: '#6C63FF', animation: 'spin 0.8s linear infinite' },
  card:     { borderRadius: 24, border: '1.5px solid', padding: 24, position: 'relative', overflow: 'hidden' },
  glowOrb:  { position: 'absolute', top: -60, right: -60, width: 200, height: 200, borderRadius: '50%', pointerEvents: 'none' },
  header:   { display: 'flex', alignItems: 'center', gap: 16, marginBottom: 16, position: 'relative' },
  headerInfo: { flex: 1, minWidth: 0 },
  name:     { fontSize: 22, fontWeight: 800, color: '#F0F0FF', lineHeight: 1.2, marginBottom: 4 },
  subtitle: { fontSize: 13, color: '#AAAAAF', fontWeight: 500 },
  bio:      { fontSize: 13, color: '#AAAAAF', lineHeight: 1.6, marginBottom: 16, position: 'relative' },
  contactRow: { display: 'flex', flexDirection: 'column', gap: 8, marginBottom: 4 },
  contactChip: { display: 'flex', alignItems: 'center', gap: 8, padding: '8px 12px', background: 'rgba(255,255,255,0.04)', borderRadius: 10, border: '1px solid rgba(255,255,255,0.06)', textDecoration: 'none', transition: 'background 0.2s' },
  contactChipText: { fontSize: 13, color: '#AAAAAF', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap', flex: 1 },
  divider:  { height: 1, background: 'rgba(255,255,255,0.06)', margin: '16px 0' },
  actions:  { display: 'flex', gap: 12, marginTop: 16 },
  saveBtn:  { flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8, padding: '14px 20px', background: 'linear-gradient(135deg, #6C63FF, #00D4FF)', border: 'none', borderRadius: 14, color: '#fff', fontSize: 14, fontWeight: 700, cursor: 'pointer', fontFamily: 'Inter, sans-serif', boxShadow: '0 8px 24px rgba(108,99,255,0.35)' },
  connectBtn: { flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8, padding: '14px 20px', background: 'transparent', border: '1.5px solid rgba(108,99,255,0.5)', borderRadius: 14, color: '#9D97FF', fontSize: 14, fontWeight: 700, cursor: 'pointer', fontFamily: 'Inter, sans-serif' },
  successCard: { marginTop: 16, padding: 24, background: 'rgba(0,230,118,0.06)', border: '1px solid rgba(0,230,118,0.2)', borderRadius: 16, textAlign: 'center' },
  successText: { fontSize: 16, fontWeight: 700, color: '#00E676', marginTop: 8 },
  successSub:  { fontSize: 13, color: '#AAAAAF', marginTop: 4 },
  brand:       { textAlign: 'center', marginTop: 24, fontSize: 12, color: '#606070' },
}
