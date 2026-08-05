import { useState, useRef } from 'react'
import { useForm, useFieldArray } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { useMutation } from '@tanstack/react-query'
import {
  Building2, CheckCircle2, XCircle, Plus, Trash2,
  MapPin, Clock, Image as ImageIcon, Pencil, Upload,
} from 'lucide-react'
import Header from '../components/layout/Header'
import { Card, CardHeader, CardTitle } from '../components/ui/Card'
import Button from '../components/ui/Button'
import EmptyState from '../components/ui/EmptyState'
import { FormField, Input, Textarea } from '../components/ui/FormField'
import { useAuth } from '../contexts/AuthContext'
import { useToast } from '../contexts/ToastContext'
import { agencyApi } from '../api/agencies'
import { WEEKDAY_KEYS } from '../types'
import type { AgencyCreate, AgencyOpeningHours, WeekdayKey } from '../types'

const WEEKDAY_LABELS: Record<WeekdayKey, string> = {
  monday: 'Monday',
  tuesday: 'Tuesday',
  wednesday: 'Wednesday',
  thursday: 'Thursday',
  friday: 'Friday',
  saturday: 'Saturday',
  sunday: 'Sunday',
}

const dayHoursSchema = z.object({
  open: z.string().optional(),
  close: z.string().optional(),
  closed: z.boolean().default(false),
})

const profileSchema = z.object({
  name: z.string().min(1, 'Agency name is required'),
  description: z.string().optional(),
  logo_url: z.string().optional(),
  contact_phone: z.string().optional(),
  contact_email: z.string().optional(),
  address: z.string().optional(),
  gallery: z.array(z.object({ value: z.string().min(1, 'Required') })).optional(),
  locations: z.array(z.object({
    label: z.string().min(1, 'Required'),
    address: z.string().min(1, 'Required'),
    phone: z.string().optional(),
  })).optional(),
  opening_hours: z.object({
    monday: dayHoursSchema,
    tuesday: dayHoursSchema,
    wednesday: dayHoursSchema,
    thursday: dayHoursSchema,
    friday: dayHoursSchema,
    saturday: dayHoursSchema,
    sunday: dayHoursSchema,
  }),
})

type ProfileForm = z.infer<typeof profileSchema>

function defaultOpeningHours(existing?: AgencyOpeningHours | null): ProfileForm['opening_hours'] {
  const result = {} as ProfileForm['opening_hours']
  for (const day of WEEKDAY_KEYS) {
    const e = existing?.[day]
    result[day] = { open: e?.open ?? '08:00', close: e?.close ?? '18:00', closed: e?.closed ?? false }
  }
  return result
}

function formatHours(h?: { open?: string | null; close?: string | null; closed: boolean }): string {
  if (!h || h.closed) return 'Closed'
  if (!h.open || !h.close) return '—'
  return `${h.open} – ${h.close}`
}

// No file-storage backend exists yet, so the logo is downscaled client-side and
// stored as a data URI in logo_url — the same string field a pasted URL would use.
function resizeImageToDataUrl(file: File, maxDim = 512): Promise<string> {
  return new Promise((resolve, reject) => {
    const reader = new FileReader()
    reader.onerror = () => reject(reader.error ?? new Error('Could not read file'))
    reader.onload = () => {
      const img = new Image()
      img.onerror = () => reject(new Error('Could not load image'))
      img.onload = () => {
        let { width, height } = img
        if (width > maxDim || height > maxDim) {
          if (width > height) {
            height = Math.round((height * maxDim) / width)
            width = maxDim
          } else {
            width = Math.round((width * maxDim) / height)
            height = maxDim
          }
        }
        const canvas = document.createElement('canvas')
        canvas.width = width
        canvas.height = height
        const ctx = canvas.getContext('2d')
        if (!ctx) { reject(new Error('Canvas not supported')); return }
        ctx.drawImage(img, 0, 0, width, height)
        resolve(canvas.toDataURL('image/jpeg', 0.85))
      }
      img.src = reader.result as string
    }
    reader.readAsDataURL(file)
  })
}

export default function ProfilePage() {
  const { agency, selectAgency } = useAuth()
  const toast = useToast()
  const [editing, setEditing] = useState(false)
  const [logoUploading, setLogoUploading] = useState(false)
  const logoFileInputRef = useRef<HTMLInputElement>(null)

  const profileForm = useForm<ProfileForm>({ resolver: zodResolver(profileSchema) })
  const galleryArray = useFieldArray({ control: profileForm.control, name: 'gallery' })
  const locationsArray = useFieldArray({ control: profileForm.control, name: 'locations' })
  const logoUrlValue = profileForm.watch('logo_url')

  async function handleLogoFileChange(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0]
    e.target.value = ''
    if (!file) return
    if (!file.type.startsWith('image/')) {
      toast.error('Please choose an image file.')
      return
    }
    setLogoUploading(true)
    try {
      const dataUrl = await resizeImageToDataUrl(file)
      profileForm.setValue('logo_url', dataUrl, { shouldDirty: true })
    } catch {
      toast.error('Could not process that image. Please try another file.')
    } finally {
      setLogoUploading(false)
    }
  }

  const updateAgency = useMutation({
    mutationFn: (payload: Partial<AgencyCreate>) => agencyApi.update(agency!.id, payload),
    onSuccess: (updated) => {
      selectAgency(updated)
      setEditing(false)
      toast.success('Profile updated.')
    },
    onError: () => toast.error('Could not update the profile. Please try again.'),
  })

  function startEditing() {
    if (!agency) return
    profileForm.reset({
      name: agency.name,
      description: agency.description ?? '',
      logo_url: agency.logo_url ?? '',
      contact_phone: agency.contact_phone ?? '',
      contact_email: agency.contact_email ?? '',
      address: agency.address ?? '',
      gallery: (agency.gallery ?? []).map(value => ({ value })),
      locations: (agency.locations ?? []).map(l => ({ label: l.label, address: l.address, phone: l.phone ?? '' })),
      opening_hours: defaultOpeningHours(agency.opening_hours),
    })
    setEditing(true)
  }

  function onSubmit(d: ProfileForm) {
    updateAgency.mutate({
      name: d.name,
      description: d.description || undefined,
      logo_url: d.logo_url || undefined,
      contact_phone: d.contact_phone || undefined,
      contact_email: d.contact_email || undefined,
      address: d.address || undefined,
      gallery: (d.gallery ?? []).map(g => g.value),
      locations: d.locations ?? [],
      opening_hours: d.opening_hours,
    })
  }

  const hasHours = !!agency?.opening_hours && WEEKDAY_KEYS.some(d => {
    const h = agency.opening_hours?.[d]
    return h && !h.closed && h.open && h.close
  })

  const completenessItems = [
    { label: 'Agency name', done: !!agency?.name },
    { label: 'Contact phone', done: !!agency?.contact_phone },
    { label: 'Contact email', done: !!agency?.contact_email },
    { label: 'Address', done: !!agency?.address },
    { label: 'Description', done: !!agency?.description },
    { label: 'Profile image', done: !!agency?.logo_url },
    { label: 'Photo gallery', done: !!agency?.gallery?.length },
    { label: 'Locations', done: !!agency?.locations?.length },
    { label: 'Opening hours', done: hasHours },
    { label: 'Verified status', done: !!agency?.is_verified },
  ]
  const completenessPct = Math.round(
    (completenessItems.filter(i => i.done).length / completenessItems.length) * 100
  )

  return (
    <div>
      <Header
        title="Agency Profile"
        subtitle="Public profile, photo gallery, locations, and opening hours"
        actions={
          editing ? (
            <div className="flex gap-2">
              <Button variant="outline" size="sm" onClick={() => setEditing(false)}>Cancel</Button>
              <Button size="sm" form="profile-edit-form" type="submit" loading={updateAgency.isPending}>
                Save Changes
              </Button>
            </div>
          ) : (
            <Button size="sm" leftIcon={<Pencil className="w-4 h-4" />} onClick={startEditing}>
              Edit Profile
            </Button>
          )
        }
      />

      <form id="profile-edit-form" onSubmit={profileForm.handleSubmit(onSubmit)}>
        <div className="grid grid-cols-3 gap-4">
          <div className="col-span-2 space-y-4">

            {/* Basic info */}
            <Card>
              <CardHeader>
                <CardTitle>Public Agency Profile</CardTitle>
              </CardHeader>

              {editing ? (
                <div className="space-y-4">
                  <FormField label="Agency logo">
                    <div className="flex items-center gap-4">
                      {logoUrlValue ? (
                        <img
                          src={logoUrlValue}
                          alt="Logo preview"
                          className="w-16 h-16 rounded-2xl object-cover bg-gray-100 border border-gray-200 shrink-0"
                        />
                      ) : (
                        <div className="w-16 h-16 rounded-2xl bg-primary/10 flex items-center justify-center shrink-0">
                          <Building2 className="w-7 h-7 text-primary" />
                        </div>
                      )}
                      <div>
                        <div className="flex gap-2">
                          <Button
                            type="button"
                            variant="outline"
                            size="sm"
                            leftIcon={<Upload className="w-3.5 h-3.5" />}
                            loading={logoUploading}
                            onClick={() => logoFileInputRef.current?.click()}
                          >
                            {logoUrlValue ? 'Change logo' : 'Upload logo'}
                          </Button>
                          {logoUrlValue && (
                            <Button
                              type="button"
                              variant="ghost"
                              size="sm"
                              onClick={() => profileForm.setValue('logo_url', '', { shouldDirty: true })}
                            >
                              Remove
                            </Button>
                          )}
                        </div>
                        <p className="text-xs text-gray-400 mt-1.5">PNG or JPG, resized automatically.</p>
                      </div>
                      <input
                        ref={logoFileInputRef}
                        type="file"
                        accept="image/*"
                        className="hidden"
                        onChange={handleLogoFileChange}
                      />
                    </div>
                  </FormField>
                  <FormField label="Or paste an image URL instead">
                    <Input {...profileForm.register('logo_url')} placeholder="https://…" />
                  </FormField>
                  <div className="grid grid-cols-2 gap-4">
                    <FormField label="Agency name" required error={profileForm.formState.errors.name?.message}>
                      <Input {...profileForm.register('name')} error={!!profileForm.formState.errors.name} />
                    </FormField>
                    <FormField label="Contact phone">
                      <Input {...profileForm.register('contact_phone')} placeholder="+228 …" />
                    </FormField>
                    <FormField label="Contact email">
                      <Input {...profileForm.register('contact_email')} type="email" placeholder="agency@example.com" />
                    </FormField>
                    <FormField label="Primary address" className="col-span-2">
                      <Input {...profileForm.register('address')} />
                    </FormField>
                  </div>
                  <FormField label="Description" hint="Tell customers about your services, safety standards, and what makes you unique.">
                    <Textarea {...profileForm.register('description')} rows={3} />
                  </FormField>
                </div>
              ) : (
                <>
                  <div className="flex items-center gap-4 mb-5">
                    {agency?.logo_url ? (
                      <img
                        src={agency.logo_url}
                        alt={agency.name}
                        className="w-16 h-16 rounded-2xl object-cover bg-gray-100"
                      />
                    ) : (
                      <div className="w-16 h-16 rounded-2xl bg-primary/10 flex items-center justify-center">
                        <Building2 className="w-8 h-8 text-primary" />
                      </div>
                    )}
                    <div>
                      <h2 className="text-lg font-bold text-dark">{agency?.name ?? 'Your Agency'}</h2>
                      {agency?.is_verified && (
                        <div className="flex items-center gap-1 text-success text-xs font-medium mt-0.5">
                          <CheckCircle2 className="w-3.5 h-3.5" /> Verified Agency
                        </div>
                      )}
                    </div>
                  </div>
                  <div className="grid grid-cols-2 gap-4 text-sm mb-5">
                    {[
                      { label: 'Contact phone', value: agency?.contact_phone },
                      { label: 'Contact email', value: agency?.contact_email },
                      { label: 'Address', value: agency?.address },
                    ].map(item => (
                      <div key={item.label}>
                        <p className="text-xs text-gray-400 mb-0.5">{item.label}</p>
                        <p className="font-medium text-dark">{item.value ?? '—'}</p>
                      </div>
                    ))}
                  </div>
                  <div>
                    <p className="text-xs text-gray-400 mb-1">Description</p>
                    <p className="text-sm text-gray-600">
                      {agency?.description || 'No description added yet. Click "Edit Profile" to add one.'}
                    </p>
                  </div>
                </>
              )}
            </Card>

            {/* Photo gallery */}
            <Card>
              <CardHeader>
                <CardTitle>Photo Gallery</CardTitle>
              </CardHeader>

              {editing ? (
                <div className="space-y-3">
                  {galleryArray.fields.map((field, i) => (
                    <div key={field.id} className="flex items-start gap-2">
                      <div className="flex-1">
                        <Input
                          {...profileForm.register(`gallery.${i}.value` as const)}
                          placeholder="https://… (image URL)"
                          error={!!profileForm.formState.errors.gallery?.[i]?.value}
                        />
                      </div>
                      <button
                        type="button"
                        onClick={() => galleryArray.remove(i)}
                        className="p-2.5 rounded-lg text-gray-400 hover:text-error hover:bg-red-50 transition shrink-0"
                        title="Remove photo"
                      >
                        <Trash2 className="w-4 h-4" />
                      </button>
                    </div>
                  ))}
                  <Button
                    type="button"
                    variant="outline"
                    size="sm"
                    leftIcon={<Plus className="w-3.5 h-3.5" />}
                    onClick={() => galleryArray.append({ value: '' })}
                  >
                    Add photo
                  </Button>
                </div>
              ) : agency?.gallery?.length ? (
                <div className="grid grid-cols-4 gap-3">
                  {agency.gallery.map((url, i) => (
                    <img
                      key={url + i}
                      src={url}
                      alt={`${agency.name} photo ${i + 1}`}
                      className="w-full aspect-square object-cover rounded-xl bg-gray-100"
                    />
                  ))}
                </div>
              ) : (
                <EmptyState
                  icon={ImageIcon}
                  title="No photos yet"
                  description="Add photos of your buses, terminals, and staff to build customer trust."
                  action={{ label: 'Edit Profile', onClick: startEditing }}
                />
              )}
            </Card>

            {/* Locations */}
            <Card>
              <CardHeader>
                <CardTitle>Locations</CardTitle>
              </CardHeader>

              {editing ? (
                <div className="space-y-3">
                  {locationsArray.fields.map((field, i) => (
                    <div key={field.id} className="grid grid-cols-[1fr_1fr_1fr_auto] gap-2 items-start">
                      <Input
                        {...profileForm.register(`locations.${i}.label` as const)}
                        placeholder="Label, e.g. Main Terminal"
                        error={!!profileForm.formState.errors.locations?.[i]?.label}
                      />
                      <Input
                        {...profileForm.register(`locations.${i}.address` as const)}
                        placeholder="Address"
                        error={!!profileForm.formState.errors.locations?.[i]?.address}
                      />
                      <Input
                        {...profileForm.register(`locations.${i}.phone` as const)}
                        placeholder="Phone (optional)"
                      />
                      <button
                        type="button"
                        onClick={() => locationsArray.remove(i)}
                        className="p-2.5 rounded-lg text-gray-400 hover:text-error hover:bg-red-50 transition shrink-0"
                        title="Remove location"
                      >
                        <Trash2 className="w-4 h-4" />
                      </button>
                    </div>
                  ))}
                  <Button
                    type="button"
                    variant="outline"
                    size="sm"
                    leftIcon={<Plus className="w-3.5 h-3.5" />}
                    onClick={() => locationsArray.append({ label: '', address: '', phone: '' })}
                  >
                    Add location
                  </Button>
                </div>
              ) : agency?.locations?.length ? (
                <div className="space-y-3">
                  {agency.locations.map((loc, i) => (
                    <div key={loc.label + i} className="flex items-start gap-3 p-3 rounded-xl bg-background">
                      <div className="w-9 h-9 rounded-lg bg-primary/10 flex items-center justify-center shrink-0">
                        <MapPin className="w-4 h-4 text-primary" />
                      </div>
                      <div>
                        <p className="font-medium text-dark text-sm">{loc.label}</p>
                        <p className="text-sm text-gray-500">{loc.address}</p>
                        {loc.phone && <p className="text-xs text-gray-400 mt-0.5">{loc.phone}</p>}
                      </div>
                    </div>
                  ))}
                </div>
              ) : (
                <EmptyState
                  icon={MapPin}
                  title="No locations added"
                  description="List every terminal, branch, or pickup point your agency operates."
                  action={{ label: 'Edit Profile', onClick: startEditing }}
                />
              )}
            </Card>

            {/* Opening hours */}
            <Card>
              <CardHeader>
                <CardTitle>Opening Hours</CardTitle>
              </CardHeader>

              {editing ? (
                <div className="space-y-2">
                  {WEEKDAY_KEYS.map(day => (
                    <div key={day} className="flex items-center gap-3 text-sm">
                      <span className="w-24 shrink-0 text-gray-500">{WEEKDAY_LABELS[day]}</span>
                      <label className="flex items-center gap-1.5 text-xs text-gray-500 shrink-0">
                        <input
                          type="checkbox"
                          {...profileForm.register(`opening_hours.${day}.closed` as const)}
                          className="accent-primary"
                        />
                        Closed
                      </label>
                      <input
                        type="time"
                        {...profileForm.register(`opening_hours.${day}.open` as const)}
                        disabled={!!profileForm.watch(`opening_hours.${day}.closed`)}
                        className="px-2 py-1.5 border border-gray-200 rounded-lg text-xs disabled:opacity-40 disabled:bg-gray-50"
                      />
                      <span className="text-gray-400 text-xs">to</span>
                      <input
                        type="time"
                        {...profileForm.register(`opening_hours.${day}.close` as const)}
                        disabled={!!profileForm.watch(`opening_hours.${day}.closed`)}
                        className="px-2 py-1.5 border border-gray-200 rounded-lg text-xs disabled:opacity-40 disabled:bg-gray-50"
                      />
                    </div>
                  ))}
                </div>
              ) : hasHours ? (
                <div className="space-y-1.5">
                  {WEEKDAY_KEYS.map(day => (
                    <div key={day} className="flex items-center justify-between text-sm py-1">
                      <span className="text-gray-500">{WEEKDAY_LABELS[day]}</span>
                      <span className={agency?.opening_hours?.[day]?.closed ? 'text-gray-400' : 'font-medium text-dark'}>
                        {formatHours(agency?.opening_hours?.[day])}
                      </span>
                    </div>
                  ))}
                </div>
              ) : (
                <EmptyState
                  icon={Clock}
                  title="No hours set"
                  description="Let customers know when your terminals and support lines are open."
                  action={{ label: 'Edit Profile', onClick: startEditing }}
                />
              )}
            </Card>
          </div>

          {/* Profile completeness */}
          <Card className="h-fit">
            <CardTitle>Profile Completeness</CardTitle>
            <div className="mt-4 space-y-3">
              {completenessItems.map(item => (
                <div key={item.label} className="flex items-center gap-2 text-sm">
                  {item.done
                    ? <CheckCircle2 className="w-4 h-4 text-success" />
                    : <XCircle className="w-4 h-4 text-gray-300" />
                  }
                  <span className={item.done ? 'text-dark' : 'text-gray-400'}>{item.label}</span>
                </div>
              ))}
            </div>
            <div className="mt-4 bg-background rounded-xl p-3 text-center">
              <p className="text-2xl font-extrabold text-primary">{completenessPct}%</p>
              <p className="text-xs text-gray-500">profile complete</p>
            </div>
          </Card>
        </div>
      </form>
    </div>
  )
}
