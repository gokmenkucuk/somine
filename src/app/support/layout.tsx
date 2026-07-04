import type { Metadata } from 'next'

export const metadata: Metadata = {
  title: 'Destek | Somine',
  description: 'Somine uygulaması hakkında sık sorulan sorular ve destek talebi için bizimle iletişime geçin.',
}

export default function SupportLayout({ children }: { children: React.ReactNode }) {
  return children
}
