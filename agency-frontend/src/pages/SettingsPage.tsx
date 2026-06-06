import { useState } from 'react'
import { Bell, Shield, Building2, Save } from 'lucide-react'
import Header from '../components/layout/Header'
import { Card, CardHeader, CardTitle } from '../components/ui/Card'
import Button from '../components/ui/Button'
import { FormField, Input, Select, Textarea } from '../components/ui/FormField'
import { useAuth } from '../contexts/AuthContext'

export default function SettingsPage() {
  const { agency, user } = useAuth()
  const [saved, setSaved] = useState(false)

  function handleSave() {
    setSaved(true)
    setTimeout(() => setSaved(false), 2000)
  }

  return (
    <div>
      <Header title="Settings" subtitle="Manage your agency preferences and account settings" />

      <div className="grid grid-cols-3 gap-6">
        <div className="col-span-2 space-y-6">
          {/* Agency info */}
          <Card>
            <CardHeader>
              <div className="flex items-center gap-2">
                <Building2 className="w-4 h-4 text-primary" />
                <CardTitle>Agency Information</CardTitle>
              </div>
            </CardHeader>
            <div className="grid grid-cols-2 gap-4">
              <FormField label="Agency name" required>
                <Input defaultValue={agency?.name} />
              </FormField>
              <FormField label="Contact phone">
                <Input defaultValue={agency?.contact_phone ?? ''} />
              </FormField>
              <FormField label="Contact email">
                <Input type="email" defaultValue={agency?.contact_email ?? ''} />
              </FormField>
              <FormField label="Address">
                <Input defaultValue={agency?.address ?? ''} />
              </FormField>
              <FormField label="Description" className="col-span-2">
                <Textarea defaultValue={agency?.description ?? ''} rows={3} />
              </FormField>
            </div>
            <div className="mt-4">
              <Button leftIcon={<Save className="w-4 h-4" />} onClick={handleSave} loading={false}>
                {saved ? 'Saved ✓' : 'Save changes'}
              </Button>
            </div>
          </Card>

          {/* Notifications */}
          <Card>
            <CardHeader>
              <div className="flex items-center gap-2">
                <Bell className="w-4 h-4 text-primary" />
                <CardTitle>Notification Preferences</CardTitle>
              </div>
            </CardHeader>
            <div className="space-y-3">
              {[
                { label: 'New booking alerts', desc: 'Get notified when a customer books a trip' },
                { label: 'Cancellation requests', desc: 'Receive alerts when a customer requests cancellation' },
                { label: 'Payment received', desc: 'Confirmation when a payment is completed' },
                { label: 'Trip reminders', desc: 'Alerts 24h before each scheduled departure' },
                { label: 'Review notifications', desc: 'When a customer leaves a review' },
              ].map((item, i) => (
                <div key={item.label} className="flex items-center justify-between py-3 border-b border-gray-50 last:border-0">
                  <div>
                    <p className="text-sm font-medium text-dark">{item.label}</p>
                    <p className="text-xs text-gray-400">{item.desc}</p>
                  </div>
                  <label className="relative inline-flex items-center cursor-pointer">
                    <input type="checkbox" defaultChecked={i < 3} className="sr-only peer" />
                    <div className="w-10 h-5 bg-gray-200 peer-focus:outline-none rounded-full peer peer-checked:bg-primary transition-all peer-checked:after:translate-x-5 after:content-[''] after:absolute after:top-0.5 after:left-0.5 after:bg-white after:rounded-full after:h-4 after:w-4 after:transition-all" />
                  </label>
                </div>
              ))}
            </div>
          </Card>

          {/* Refund policy */}
          <Card>
            <CardHeader>
              <CardTitle>Refund & Cancellation Policy</CardTitle>
            </CardHeader>
            <div className="grid grid-cols-2 gap-4">
              <FormField label="Free cancellation window" hint="Hours before departure">
                <Select defaultValue="24">
                  <option value="6">6 hours</option>
                  <option value="12">12 hours</option>
                  <option value="24">24 hours</option>
                  <option value="48">48 hours</option>
                </Select>
              </FormField>
              <FormField label="Refund percentage after window">
                <Select defaultValue="0">
                  <option value="0">0% (no refund)</option>
                  <option value="50">50%</option>
                  <option value="75">75%</option>
                </Select>
              </FormField>
            </div>
            <Button className="mt-4" variant="outline" onClick={handleSave}>Save policy</Button>
          </Card>
        </div>

        {/* Sidebar */}
        <div className="space-y-4">
          {/* Account */}
          <Card>
            <div className="flex items-center gap-2 mb-4">
              <Shield className="w-4 h-4 text-primary" />
              <h3 className="section-title">Account</h3>
            </div>
            <div className="space-y-3 text-sm">
              <div>
                <p className="text-xs text-gray-400 mb-0.5">Name</p>
                <p className="font-medium text-dark">{user?.full_name ?? '—'}</p>
              </div>
              <div>
                <p className="text-xs text-gray-400 mb-0.5">Email</p>
                <p className="font-medium text-dark">{user?.email ?? '—'}</p>
              </div>
              <div>
                <p className="text-xs text-gray-400 mb-0.5">Phone</p>
                <p className="font-medium text-dark">{user?.phone_number ?? '—'}</p>
              </div>
            </div>
            <Button variant="outline" size="sm" className="mt-4 w-full justify-center">
              Change password
            </Button>
          </Card>

          {/* Plan */}
          <Card className="bg-gradient-to-br from-dark to-primary text-white">
            <p className="text-xs text-primary-200 uppercase tracking-wider mb-2">Current Plan</p>
            <p className="text-xl font-extrabold mb-1">Standard</p>
            <p className="text-xs text-primary-200 mb-4">3% platform fee per transaction</p>
            <div className="space-y-1.5 text-xs text-primary-200 mb-5">
              {['Up to 50 routes', 'Basic analytics', '2 promotional campaigns / month', 'Email support'].map(f => (
                <div key={f} className="flex items-center gap-1.5">
                  <span className="text-secondary">✓</span> {f}
                </div>
              ))}
            </div>
            <Button className="w-full justify-center bg-white text-primary hover:bg-primary-50" size="sm">
              Upgrade to Premium
            </Button>
          </Card>
        </div>
      </div>
    </div>
  )
}
