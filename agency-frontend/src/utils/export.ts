import Papa from 'papaparse'
import jsPDF from 'jspdf'
import autoTable from 'jspdf-autotable'

export function exportCsv(data: object[], filename: string) {
  const csv = Papa.unparse(data)
  const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' })
  const url = URL.createObjectURL(blob)
  const link = document.createElement('a')
  link.href = url
  link.download = `${filename}.csv`
  link.click()
  URL.revokeObjectURL(url)
}

export function exportPdf(
  title: string,
  columns: string[],
  rows: (string | number)[][],
  filename: string
) {
  const doc = new jsPDF()
  doc.setFontSize(14)
  doc.text(title, 14, 16)
  doc.setFontSize(9)
  doc.text(`Generated: ${new Date().toLocaleString()}`, 14, 22)
  autoTable(doc, {
    head: [columns],
    body: rows,
    startY: 28,
    theme: 'grid',
    headStyles: { fillColor: [46, 94, 153] },
    styles: { fontSize: 8 },
  })
  doc.save(`${filename}.pdf`)
}
