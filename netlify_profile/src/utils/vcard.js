/**
 * vCard (VCF) utilities for the Netlify profile page.
 * Generates a VERSION:3.0 vCard string and triggers a .vcf download.
 */

/**
 * Build a vCard 3.0 string from a Supabase profile row.
 * @param {Object} profile - Row from the `profiles` table (snake_case keys)
 * @returns {string} vCard text
 */
export function generateVCard(profile) {
  const lines = [
    'BEGIN:VCARD',
    'VERSION:3.0',
  ]

  if (profile.display_name) {
    lines.push(`FN:${escapeVCard(profile.display_name)}`)
    // Split into surname / given name (best-effort: last word = surname)
    const parts = profile.display_name.trim().split(/\s+/)
    const last  = parts.length > 1 ? parts.pop() : ''
    const first = parts.join(' ')
    lines.push(`N:${escapeVCard(last)};${escapeVCard(first)};;;`)
  }

  if (profile.job_title) {
    lines.push(`TITLE:${escapeVCard(profile.job_title)}`)
  }

  if (profile.company) {
    lines.push(`ORG:${escapeVCard(profile.company)}`)
  }

  if (profile.email) {
    lines.push(`EMAIL;TYPE=INTERNET:${profile.email}`)
  }

  if (profile.phone) {
    lines.push(`TEL;TYPE=CELL:${profile.phone}`)
  }

  if (profile.website) {
    const url = profile.website.startsWith('http')
      ? profile.website
      : `https://${profile.website}`
    lines.push(`URL:${url}`)
  }

  if (profile.bio) {
    lines.push(`NOTE:${escapeVCard(profile.bio)}`)
  }

  if (profile.photo_url) {
    // Reference the remote photo URL (not embedded binary)
    lines.push(`PHOTO;VALUE=URI:${profile.photo_url}`)
  }

  // Append social links as X- extended properties
  if (Array.isArray(profile.social_links)) {
    for (const link of profile.social_links) {
      if (link.isActive && link.url && link.platform) {
        const urlVal = link.url.startsWith('http') ? link.url : `https://${link.url}`
        lines.push(`X-SOCIALPROFILE;TYPE=${link.platform.toUpperCase()}:${urlVal}`)
      }
    }
  }

  lines.push(`REV:${new Date().toISOString().replace(/[-:.]/g, '').slice(0, 15)}Z`)
  lines.push('END:VCARD')

  return lines.join('\r\n')
}

/**
 * Generate a vCard and trigger a browser download of the .vcf file.
 * @param {Object} profile - Row from the `profiles` table
 */
export function downloadVCard(profile) {
  const content  = generateVCard(profile)
  const blob     = new Blob([content], { type: 'text/vcard;charset=utf-8' })
  const url      = URL.createObjectURL(blob)
  const filename = `${(profile.display_name || 'contact')
    .replace(/\s+/g, '_')
    .replace(/[^a-zA-Z0-9_-]/g, '')}.vcf`

  const anchor   = document.createElement('a')
  anchor.href    = url
  anchor.download = filename
  document.body.appendChild(anchor)
  anchor.click()
  document.body.removeChild(anchor)
  URL.revokeObjectURL(url)
}

// ── Helpers ────────────────────────────────────────────────────────────────────

/**
 * Escape special characters in vCard field values.
 * Per RFC 2426: commas, semicolons, backslashes, and newlines must be escaped.
 * @param {string} value
 * @returns {string}
 */
function escapeVCard(value) {
  if (!value) return ''
  return String(value)
    .replace(/\\/g, '\\\\')
    .replace(/,/g, '\\,')
    .replace(/;/g, '\\;')
    .replace(/\r\n|\r|\n/g, '\\n')
}
