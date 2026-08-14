import { apiClient } from './client'

export type UploadFolder = 'logos' | 'gallery' | 'receipts' | 'invoices' | 'documents'

export const uploadApi = {
  upload: async (file: File, folder: UploadFolder): Promise<{ url: string }> => {
    const formData = new FormData()
    formData.append('file', file)
    formData.append('folder', folder)
    // apiClient defaults to Content-Type: application/json, which would make axios
    // JSON-stringify the FormData instead of sending it as multipart. Overriding it
    // here (to anything other than application/json) keeps the FormData intact —
    // axios then clears this header itself so the browser can set the real
    // multipart/form-data boundary.
    const { data } = await apiClient.post<{ url: string }>('/uploads', formData, {
      headers: { 'Content-Type': 'multipart/form-data' },
    })
    return data
  },
}
