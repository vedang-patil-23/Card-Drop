import { useState } from 'react'
import { supabase } from '../supabase/client'

export default function LeadCaptureForm({ profileId, onSuccess, onClose }) {
  const [form,   setForm]   = useState({ name: '', email: '', phone: '', organization: '', note: '' })
  const [saving, setSaving] = useState(false)
  const [errors, setErrors] = useState({})

  function onChange(field, value) {
    setForm(f => ({ ...f, [field]: value }))
    if (errors[field]) setErrors(e => ({ ...e, [field]: null }))
  }

  async function submit(e) {
    e.preventDefault()
    if (!form.name.trim()) { setErrors({ name: 'Name is required' }); return }

    setSaving(true)
    try {
      const { error } = await supabase.from('leads').insert({
        owner_profile_id: profileId,
        name:             form.name.trim(),
        email:            form.email.trim(),
        phone:            form.phone.trim(),
        organization:     form.organization.trim(),
        note:             form.note.trim(),
        source:           'web',
        captured_at:      new Date().toISOString(),
        is_new:           true,
      })

      if (error) throw error
      onSuccess()
    } catch (err) {
      console.error('Lead submit error:', err)
      setErrors({ submit: 'Failed to send. Please try again.' })
    } finally {
      setSaving(false)
    }
  }

  return (
    <div style={s.card}>
      <div style={s.header}>
        <h3 style={s.title}>Share Your Info</h3>
        <button onClick={onClose} style={s.closeBtn}>✕</button>
      </div>
      <p style={s.subtitle}>Fill in your details — they'll receive them directly.</p>

      <form onSubmit={submit} style={{ display: 'flex', flexDirection: 'column' }}>
        <Field label="Full Name *" value={form.name}         onChange={v => onChange('name', v)}         placeholder="John Smith"        type="text"  error={errors.name} />
        <Field label="Email"       value={form.email}        onChange={v => onChange('email', v)}        placeholder="john@example.com"  type="email" />
        <Field label="Phone"       value={form.phone}        onChange={v => onChange('phone', v)}        placeholder="+1 555 000 0000"   type="tel"   />
        <Field label="Organization" value={form.organization} onChange={v => onChange('organization', v)} placeholder="Your company"      type="text"  />
        <Field label="Note"        value={form.note}         onChange={v => onChange('note', v)}         placeholder="Where we met…"     type="text"  multiline />

        {errors.submit && <p style={{ fontSize: 11, color: '#FF5252', marginBottom: 8 }}>{errors.submit}</p>}

        <button type="submit" disabled={saving} style={s.submitBtn}>
          {saving ? 'Sending…' : 'Send My Info →'}
        </button>
      </form>
    </div>
  )
}

function Field({ label, value, onChange, placeholder, type, error, multiline }) {
  const inputStyle = { ...s.input, borderColor: error ? '#FF5252' : 'rgba(255,255,255,0.08)' }
  return (
    <div style={{ marginBottom: 14 }}>
      <label style={s.label}>{label}</label>
      {multiline
        ? <textarea value={value} onChange={e => onChange(e.target.value)} placeholder={placeholder} rows={3}
            style={{ ...inputStyle, resize: 'vertical', minHeight: 80 }} />
        : <input type={type} value={value} onChange={e => onChange(e.target.value)}
            placeholder={placeholder} style={inputStyle} />
      }
      {error && <p style={{ fontSize: 11, color: '#FF5252', marginTop: 4 }}>{error}</p>}
    </div>
  )
}

const s = {
  card:      { marginTop: 16, background: '#13131A', border: '1px solid rgba(108,99,255,0.25)', borderRadius: 16, padding: 20 },
  header:    { display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 6 },
  title:     { fontSize: 16, fontWeight: 700, color: '#F0F0FF' },
  closeBtn:  { background: 'none', border: 'none', color: '#606070', fontSize: 16, cursor: 'pointer', padding: '4px 8px', fontFamily: 'Inter, sans-serif' },
  subtitle:  { fontSize: 12, color: '#AAAAAF', marginBottom: 18, lineHeight: 1.5 },
  label:     { display: 'block', fontSize: 12, fontWeight: 500, color: '#AAAAAF', marginBottom: 6, fontFamily: 'Inter, sans-serif' },
  input:     { width: '100%', padding: '10px 12px', background: '#1C1C27', border: '1px solid', borderRadius: 10, color: '#F0F0FF', fontSize: 13, fontFamily: 'Inter, sans-serif', outline: 'none', boxSizing: 'border-box' },
  submitBtn: { marginTop: 8, padding: '13px 20px', background: 'linear-gradient(135deg, #6C63FF, #00D4FF)', border: 'none', borderRadius: 12, color: '#fff', fontSize: 14, fontWeight: 700, cursor: 'pointer', fontFamily: 'Inter, sans-serif' },
}
