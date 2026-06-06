import { useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { Building2, ChevronRight, Plus } from 'lucide-react'
import { useAuth } from '../../contexts/AuthContext'
import { agencyApi } from '../../api/agencies'
import type { Agency } from '../../types'

export default function AgencySelectPage() {
  const { selectAgency } = useAuth()
  const navigate = useNavigate()
  const [agencies, setAgencies] = useState<Agency[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    agencyApi.list().then(setAgencies).finally(() => setLoading(false))
  }, [])

  function choose(a: Agency) {
    selectAgency(a)
    navigate('/dashboard')
  }

  return (
    <div className="min-h-screen bg-background flex items-center justify-center p-4">
      <div className="w-full max-w-lg">
        <div className="text-center mb-8">
          <div className="inline-flex items-center justify-center w-14 h-14 rounded-2xl bg-primary/10 mb-4">
            <Building2 className="w-7 h-7 text-primary" />
          </div>
          <h1 className="text-2xl font-bold text-dark">Select Your Agency</h1>
          <p className="text-sm text-gray-500 mt-1">Choose the agency you want to manage</p>
        </div>

        {loading ? (
          <div className="text-center py-10 text-gray-400">Loading agencies…</div>
        ) : agencies.length === 0 ? (
          <div className="bg-white rounded-2xl shadow-card p-8 text-center">
            <p className="text-gray-500 mb-4">No agencies found for your account.</p>
            <button
              onClick={() => navigate('/agencies/new')}
              className="inline-flex items-center gap-2 px-5 py-2.5 bg-primary text-white text-sm font-medium rounded-xl hover:bg-primary-700 transition"
            >
              <Plus className="w-4 h-4" /> Create Agency
            </button>
          </div>
        ) : (
          <div className="space-y-3">
            {agencies.map(a => (
              <button
                key={a.id}
                onClick={() => choose(a)}
                className="w-full flex items-center gap-4 bg-white rounded-2xl shadow-card p-5 hover:shadow-lg hover:-translate-y-0.5 transition-all text-left group"
              >
                <div className="w-10 h-10 rounded-xl bg-primary/10 flex items-center justify-center shrink-0">
                  <Building2 className="w-5 h-5 text-primary" />
                </div>
                <div className="flex-1 min-w-0">
                  <p className="font-semibold text-dark text-sm truncate">{a.name}</p>
                  <p className="text-xs text-gray-400 mt-0.5">
                    {a.is_verified ? '✓ Verified' : 'Pending verification'} · {a.routes?.length ?? 0} routes
                  </p>
                </div>
                <ChevronRight className="w-4 h-4 text-gray-300 group-hover:text-primary transition" />
              </button>
            ))}
          </div>
        )}
      </div>
    </div>
  )
}
