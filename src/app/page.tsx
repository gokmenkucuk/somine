'use client'

import { useRef, useState, useEffect } from 'react'
import Image from 'next/image'
import Link from 'next/link'
import { Swiper, SwiperSlide } from 'swiper/react'
import { Autoplay } from 'swiper/modules'
import { motion, AnimatePresence, useInView } from 'framer-motion'
import {
  Play,
  FolderOpen,
  StickyNote,
  ShieldCheck,
  Share2,
  Palette,
  BookmarkPlus,
  LayoutGrid,
  Sparkles,
  ArrowRight,
  Zap,
  MousePointerClick,
  Globe,
  Check,
  X,
} from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import Navbar from '@/components/navbar'
import Footer from '@/components/footer'

/* ─── animation helpers ─── */
const fadeUp = {
  hidden: { opacity: 0, y: 30 },
  visible: { opacity: 1, y: 0, transition: { duration: 0.8, ease: [0.22, 1, 0.36, 1] } },
}
const stagger = {
  visible: { transition: { staggerChildren: 0.1 } },
}
const scaleIn = {
  hidden: { opacity: 0, scale: 0.9 },
  visible: { opacity: 1, scale: 1, transition: { duration: 0.7, ease: [0.22, 1, 0.36, 1] } },
}

/* ─── platform icon data ─── */
const platformIconsRow1 = [
  {
    name: 'Instagram',
    viewBox: '0 0 24 24',
    path: 'M7.8 2h8.4C19.4 2 22 4.6 22 7.8v8.4a5.8 5.8 0 0 1-5.8 5.8H7.8C4.6 22 2 19.4 2 16.2V7.8A5.8 5.8 0 0 1 7.8 2m-.2 2A3.6 3.6 0 0 0 4 7.6v8.8C4 18.39 5.61 20 7.6 20h8.8a3.6 3.6 0 0 0 3.6-3.6V7.6C20 5.61 18.39 4 16.4 4H7.6m9.65 1.5a1.25 1.25 0 0 1 1.25 1.25A1.25 1.25 0 0 1 17.25 8 1.25 1.25 0 0 1 16 6.75a1.25 1.25 0 0 1 1.25-1.25M12 7a5 5 0 0 1 5 5 5 5 0 0 1-5 5 5 5 0 0 1-5-5 5 5 0 0 1 5-5m0 2a3 3 0 0 0-3 3 3 3 0 0 0 3 3 3 3 0 0 0 3-3 3 3 0 0 0-3-3z',
  },
  {
    name: 'YouTube',
    viewBox: '0 0 24 24',
    path: 'M23.498 6.186a3.016 3.016 0 0 0-2.122-2.136C19.505 3.545 12 3.545 12 3.545s-7.505 0-9.377.505A3.017 3.017 0 0 0 .502 6.186C0 8.07 0 12 0 12s0 3.93.502 5.814a3.016 3.016 0 0 0 2.122 2.136c1.871.505 9.376.505 9.376.505s7.505 0 9.377-.505a3.015 3.015 0 0 0 2.122-2.136C24 15.93 24 12 24 12s0-3.93-.502-5.814zM9.545 15.568V8.432L15.818 12l-6.273 3.568z',
  },
  {
    name: 'Pinterest',
    viewBox: '0 0 24 24',
    path: 'M12.017 0C5.396 0 .029 5.367.029 11.987c0 5.079 3.158 9.417 7.618 11.162-.105-.949-.199-2.403.041-3.439.219-.937 1.406-5.957 1.406-5.957s-.359-.72-.359-1.781c0-1.668.967-2.914 2.171-2.914 1.023 0 1.518.769 1.518 1.69 0 1.029-.655 2.568-.994 3.995-.283 1.194.599 2.169 1.777 2.169 2.133 0 3.772-2.249 3.772-5.495 0-2.873-2.064-4.882-5.012-4.882-3.414 0-5.418 2.561-5.418 5.207 0 1.031.397 2.138.893 2.738a.36.36 0 0 1 .083.345l-.333 1.36c-.053.22-.174.267-.402.161-1.499-.698-2.436-2.889-2.436-4.649 0-3.785 2.75-7.262 7.929-7.262 4.163 0 7.398 2.967 7.398 6.931 0 4.136-2.607 7.464-6.227 7.464-1.216 0-2.359-.631-2.75-1.378l-.748 2.853c-.271 1.043-1.002 2.35-1.492 3.146C9.57 23.812 10.763 24 12.017 24c6.624 0 11.99-5.367 11.99-11.988C24.007 5.367 18.641.001 12.017.001z',
  },
  {
    name: 'Spotify',
    viewBox: '0 0 24 24',
    path: 'M12 0C5.4 0 0 5.4 0 12s5.4 12 12 12 12-5.4 12-12S18.66 0 12 0zm5.521 17.34c-.24.359-.66.48-1.021.24-2.82-1.74-6.36-2.101-10.561-1.141-.418.122-.779-.179-.899-.539-.12-.421.18-.78.54-.9 4.56-1.021 8.52-.6 11.64 1.32.42.18.479.659.301 1.02zm1.44-3.3c-.301.42-.841.6-1.262.3-3.239-1.98-8.159-2.58-11.939-1.38-.479.12-1.02-.12-1.14-.6-.12-.48.12-1.021.6-1.141C9.6 9.9 15 10.561 18.72 12.84c.361.181.54.78.241 1.2zm.12-3.36C15.24 8.4 8.82 8.16 5.16 9.301c-.6.179-1.2-.181-1.38-.721-.18-.601.18-1.2.72-1.381 4.26-1.26 11.28-1.02 15.721 1.621.539.3.719 1.02.419 1.56-.299.421-1.02.599-1.559.3z',
  },
  {
    name: 'Facebook',
    viewBox: '0 0 24 24',
    path: 'M24 12.073c0-6.627-5.373-12-12-12s-12 5.373-12 12c0 5.99 4.388 10.954 10.125 11.854v-8.385H7.078v-3.47h3.047V9.43c0-3.007 1.792-4.669 4.533-4.669 1.312 0 2.686.235 2.686.235v2.953H15.83c-1.491 0-1.956.925-1.956 1.874v2.25h3.328l-.532 3.47h-2.796v8.385C19.612 23.027 24 18.062 24 12.073z',
  },
  {
    name: 'Reddit',
    viewBox: '0 0 24 24',
    path: 'M12 0A12 12 0 0 0 0 12a12 12 0 0 0 12 12 12 12 0 0 0 12-12A12 12 0 0 0 12 0zm5.01 4.744c.688 0 1.25.561 1.25 1.249a1.25 1.25 0 0 1-2.498.056l-2.597-.547-.8 3.747c1.824.07 3.48.632 4.674 1.488.308-.309.73-.491 1.207-.491.968 0 1.754.786 1.754 1.754 0 .716-.435 1.333-1.01 1.614a3.111 3.111 0 0 1 .042.52c0 2.694-3.13 4.87-7.004 4.87-3.874 0-7.004-2.176-7.004-4.87 0-.183.015-.366.043-.534A1.748 1.748 0 0 1 4.028 12c0-.968.786-1.754 1.754-1.754.463 0 .898.196 1.207.49 1.207-.883 2.878-1.43 4.744-1.487l.885-4.182a.342.342 0 0 1 .14-.197.35.35 0 0 1 .238-.042l2.906.617a1.214 1.214 0 0 1 1.108-.701zM9.25 12C8.561 12 8 12.562 8 13.25c0 .687.561 1.248 1.25 1.248.687 0 1.248-.561 1.248-1.249 0-.688-.561-1.249-1.249-1.249zm5.5 0c-.687 0-1.248.561-1.248 1.25 0 .687.561 1.248 1.249 1.248.688 0 1.249-.561 1.249-1.249 0-.687-.562-1.249-1.25-1.249zm-5.466 3.99a.327.327 0 0 0-.231.094.33.33 0 0 0 0 .463c.842.842 2.484.913 2.961.913.477 0 2.105-.056 2.961-.913a.361.361 0 0 0 .029-.463.33.33 0 0 0-.464 0c-.547.533-1.684.73-2.512.73-.828 0-1.979-.196-2.512-.73a.326.326 0 0 0-.232-.095z',
  },
  {
    name: 'Snapchat',
    viewBox: '0 0 24 24',
    path: 'M12.206.793c.99 0 4.347.276 5.93 3.821.529 1.193.403 3.219.299 4.847l-.003.06c-.012.18-.022.345-.03.51.075.045.203.09.401.09.3-.016.659-.12.922-.214.12-.042.239-.075.344-.1a.88.88 0 0 1 .223-.034c.239 0 .384.12.444.233a.65.65 0 0 1 .054.508c-.12.359-.509.778-1.383 1.157-.06.03-.149.069-.27.12-.418.165-1.283.509-1.498 1.158-.12.359-.075.778.15 1.197l.03.045c.015.03.18.314.474.808.674 1.122 1.828 3.042 1.932 3.536.12.554-.045.913-.239 1.122-.27.27-.704.404-1.048.404-.12 0-.239-.015-.344-.045l-.075-.015c-.149-.045-.344-.09-.644-.09-.18 0-.359.015-.539.045-.314.045-.599.195-.913.36-.434.224-.928.479-1.708.584-.12.015-.24.03-.359.03-.509 0-.868-.195-1.138-.359-.239-.15-.418-.27-.674-.27h-.03c-.254.016-.464.12-.704.27-.269.15-.614.314-1.093.314l-.09-.004c-.749-.045-1.258-.33-1.723-.584a2.814 2.814 0 0 0-.853-.33 3.677 3.677 0 0 0-.524-.03c-.284 0-.509.03-.689.075l-.06.015c-.12.03-.239.045-.359.045-.344 0-.779-.135-1.048-.404-.21-.21-.359-.568-.24-1.122.12-.509 1.272-2.413 1.932-3.521.27-.449.449-.764.474-.808.224-.419.27-.838.15-1.197-.224-.654-1.078-.993-1.498-1.157a3.89 3.89 0 0 1-.27-.12C3.04 11.59 2.65 11.171 2.53 10.812a.65.65 0 0 1 .054-.508c.06-.12.21-.233.449-.233.075 0 .149.015.224.034.12.03.224.06.344.1.27.09.629.195.928.195.18 0 .314-.03.389-.075-.015-.149-.03-.314-.045-.494l-.003-.06c-.104-1.642-.229-3.654.299-4.847C7.35 1.069 10.707.793 11.697.793h.509z',
  },
]

const platformIconsRow2 = [
  {
    name: 'X',
    viewBox: '0 0 24 24',
    path: 'M18.901 1.153h3.68l-8.04 9.19L24 22.846h-7.406l-5.8-7.584-6.638 7.584H.474l8.6-9.83L0 1.154h7.594l5.243 6.932ZM17.61 20.644h2.039L6.486 3.24H4.298Z',
  },
  {
    name: 'TikTok',
    viewBox: '0 0 24 24',
    path: 'M12.525.02c1.31-.02 2.61-.01 3.91-.02.08 1.53.63 3.09 1.75 4.17 1.12 1.11 2.7 1.62 4.24 1.79v4.03c-1.44-.05-2.89-.35-4.2-.97-.57-.26-1.1-.59-1.62-.93-.01 2.92.01 5.84-.02 8.75-.08 1.4-.54 2.79-1.35 3.94-1.31 1.92-3.58 3.17-5.91 3.21-1.43.08-2.86-.31-4.08-1.03-2.02-1.19-3.44-3.37-3.65-5.71-.02-.5-.03-1-.01-1.49.18-1.9 1.12-3.72 2.58-4.96 1.66-1.44 3.98-2.13 6.15-1.72.02 1.48-.04 2.96-.04 4.44-.99-.32-2.15-.23-3.02.37-.63.41-1.11 1.04-1.36 1.75-.21.51-.15 1.07-.14 1.61.24 1.64 1.82 3.02 3.5 2.87 1.12-.01 2.19-.66 2.77-1.61.19-.33.4-.67.41-1.06.1-1.79.06-3.57.07-5.36.01-4.03-.01-8.05.02-12.07z',
  },
  {
    name: 'LinkedIn',
    viewBox: '0 0 24 24',
    path: 'M20.447 20.452h-3.554v-5.569c0-1.328-.027-3.037-1.852-3.037-1.853 0-2.136 1.445-2.136 2.939v5.667H9.351V9h3.414v1.561h.046c.477-.9 1.637-1.85 3.37-1.85 3.601 0 4.267 2.37 4.267 5.455v6.286zM5.337 7.433a2.062 2.062 0 0 1-2.063-2.065 2.064 2.064 0 1 1 2.063 2.065zm1.782 13.019H3.555V9h3.564v11.452zM22.225 0H1.771C.792 0 0 .774 0 1.729v20.542C0 23.227.792 24 1.771 24h20.451C23.2 24 24 23.227 24 22.271V1.729C24 .774 23.2 0 22.222 0h.003z',
  },
  {
    name: 'Medium',
    viewBox: '0 0 24 24',
    path: 'M13.54 12a6.8 6.8 0 01-6.77 6.82A6.8 6.8 0 010 12a6.8 6.8 0 016.77-6.82A6.8 6.8 0 0113.54 12zM20.96 12c0 3.54-1.51 6.42-3.38 6.42-1.87 0-3.39-2.88-3.39-6.42s1.52-6.42 3.39-6.42 3.38 2.88 3.38 6.42M24 12c0 3.17-.53 5.75-1.19 5.75-.66 0-1.19-2.58-1.19-5.75s.53-5.75 1.19-5.75C23.47 6.25 24 8.83 24 12z',
  },
  {
    name: 'Amazon',
    viewBox: '0 0 24 24',
    path: 'M.045 18.02c.07-.116.372-.197.58-.197.073 0 .146.008.207.027a8.76 8.76 0 0 0 3.224 1.162c.469.077.955.116 1.44.116 1.346 0 2.724-.342 3.817-.915.448-.23.858-.5 1.242-.786.08-.06.183-.09.28-.09.08 0 .16.024.22.073l.003.001c.135.108.166.3.074.442-1.872 2.908-5.04 4.61-8.654 4.61-1.476 0-2.895-.34-4.186-.975C-.536 20.975.008 18.855.045 18.02zM6.572 8.66c-.233.224-.613.364-.996.364-.4 0-.78-.14-1.012-.364-.143-.136-.223-.3-.223-.48 0-.176.08-.34.223-.476.232-.224.612-.364 1.012-.364.383 0 .763.14.996.364.143.136.223.3.223.476 0 .18-.08.344-.223.48zm10.248 1.92c-.236.247-.66.4-1.107.4-.447 0-.872-.153-1.107-.4-.16-.168-.248-.372-.248-.582 0-.21.088-.414.248-.582.235-.247.66-.4 1.107-.4.447 0 .871.153 1.107.4.16.168.248.372.248.582 0 .21-.089.414-.248.582zM24 15.68c0 2.03-1.373 3.88-3.74 5.16-2.01 1.084-4.627 1.702-7.24 1.702-2.73 0-5.248-.654-7.09-1.843l-.01-.006c-.196-.13-.24-.39-.095-.577.14-.18.395-.222.572-.096 1.667 1.074 3.95 1.655 6.41 1.655 2.38 0 4.773-.554 6.573-1.52 2.03-1.092 3.18-2.616 3.18-4.177 0-.196-.016-.393-.048-.586-.04-.237.1-.464.316-.512.217-.048.428.1.47.336.04.24.06.487.06.735 0 .002-.048.23-.048.232l-.05.177z',
  },
  {
    name: 'Google Maps',
    viewBox: '0 0 24 24',
    path: 'M12 2C8.13 2 5 5.13 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.87-3.13-7-7-7zm0 9.5a2.5 2.5 0 010-5 2.5 2.5 0 010 5z',
  },
  {
    name: 'Apple Maps',
    viewBox: '0 0 24 24',
    path: 'M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm0 18c-4.41 0-8-3.59-8-8s3.59-8 8-8 8 3.59 8 8-3.59 8-8 8zm-1-8l-3 7 7-3 3-7-7 3zm1-1c-.55 0-1 .45-1 1s.45 1 1 1 1-.45 1-1-.45-1-1-1z',
  },
  {
    name: 'Yandex Maps',
    viewBox: '0 0 24 24',
    path: 'M12 2C6.477 2 2 6.477 2 12s4.477 10 10 10 10-4.477 10-10S17.523 2 12 2zm1 14h-2v-5L7 7h2.5l2.5 3 2.5-3H17l-4 4v5z',
  },
  {
    name: 'Behance',
    viewBox: '0 0 24 24',
    path: 'M22 7h-7V5h7zm1.726 10c-.442 1.297-2.029 3-5.101 3-3.074 0-5.564-1.729-5.564-5.675 0-3.91 2.325-5.92 5.466-5.92 3.082 0 4.964 1.782 5.375 4.426.078.506.109 1.188.095 2.14H15.97c.13 3.211 3.483 3.312 4.588 2.029h3.168zm-7.686-4h4.965c-.105-1.547-1.136-2.219-2.477-2.219-1.466 0-2.277.768-2.488 2.219zm-9.574 6.988H0V5.021h6.953c5.476.081 5.58 5.444 2.72 6.906 3.461 1.26 3.577 8.061-3.207 8.061zM3 11h3.584c2.508 0 2.906-3-.312-3H3v3zm3.391 3H3v3.016h3.341c3.055 0 2.868-3.016.05-3.016z',
  },
  {
    name: 'Dribbble',
    viewBox: '0 0 24 24',
    path: 'M12 24C5.385 24 0 18.615 0 12S5.385 0 12 0s12 5.385 12 12-5.385 12-12 12zm10.12-10.358c-.35-.11-3.17-.953-6.384-.438 1.34 3.684 1.887 6.684 1.992 7.308 2.3-1.555 3.936-4.02 4.395-6.87zm-6.115 7.808c-.153-.9-.75-4.032-2.19-7.77l-.066.02c-5.79 2.015-7.86 6.025-8.04 6.4 1.73 1.358 3.92 2.166 6.29 2.166 1.42 0 2.77-.29 4-.81zm-11.62-2.58c.232-.4 3.045-5.055 8.332-6.765.135-.045.27-.084.405-.12-.26-.585-.54-1.167-.832-1.74C7.17 11.775 2.206 11.71 1.756 11.7l-.004.312c0 2.633.998 5.037 2.634 6.855zm-2.42-8.955c.46.008 4.683.026 9.477-1.248-1.698-3.018-3.53-5.558-3.8-5.928-2.868 1.35-5.01 3.99-5.676 7.17zM9.6 2.052c.282.38 2.145 2.914 3.822 6 3.645-1.365 5.19-3.44 5.373-3.702C16.86 2.61 14.545 1.62 12 1.62c-.8 0-1.6.1-2.4.285v.15zm10.335 3.483c-.218.29-1.91 2.493-5.724 4.04.24.49.47.985.68 1.486.08.18.15.36.22.53 3.41-.43 6.8.26 7.14.33-.02-2.42-.88-4.64-2.31-6.38z',
  },
  {
    name: 'Web Links',
    viewBox: '0 0 24 24',
    path: 'M3.9 12c0-1.71 1.39-3.1 3.1-3.1h4V7H7c-2.76 0-5 2.24-5 5s2.24 5 5 5h4v-1.9H7c-1.71 0-3.1-1.39-3.1-3.1zM8 13h8v-2H8v2zm9-6h-4v1.9h4c1.71 0 3.1 1.39 3.1 3.1s-1.39 3.1-3.1 3.1h-4V17h4c2.76 0 5-2.24 5-5s-2.24-5-5-5z',
  },
]

/* ─── hero platform icon blocks ─── */
const platformBlocks = [
  [
    { name: 'YouTube', path: 'M23.498 6.186a3.016 3.016 0 0 0-2.122-2.136C19.505 3.545 12 3.545 12 3.545s-7.505 0-9.377.505A3.017 3.017 0 0 0 .502 6.186C0 8.07 0 12 0 12s0 3.93.502 5.814a3.016 3.016 0 0 0 2.122 2.136c1.871.505 9.376.505 9.376.505s7.505 0 9.377-.505a3.015 3.015 0 0 0 2.122-2.136C24 15.93 24 12 24 12s0-3.93-.502-5.814zM9.545 15.568V8.432L15.818 12l-6.273 3.568z' },
    { name: 'Instagram', path: 'M7.8 2h8.4C19.4 2 22 4.6 22 7.8v8.4a5.8 5.8 0 0 1-5.8 5.8H7.8C4.6 22 2 19.4 2 16.2V7.8A5.8 5.8 0 0 1 7.8 2m-.2 2A3.6 3.6 0 0 0 4 7.6v8.8C4 18.39 5.61 20 7.6 20h8.8a3.6 3.6 0 0 0 3.6-3.6V7.6C20 5.61 18.39 4 16.4 4H7.6m9.65 1.5a1.25 1.25 0 0 1 1.25 1.25A1.25 1.25 0 0 1 17.25 8 1.25 1.25 0 0 1 16 6.75a1.25 1.25 0 0 1 1.25-1.25M12 7a5 5 0 0 1 5 5 5 5 0 0 1-5 5 5 5 0 0 1-5-5 5 5 0 0 1 5-5m0 2a3 3 0 0 0-3 3 3 3 0 0 0 3 3 3 3 0 0 0 3-3 3 3 0 0 0-3-3z' },
    { name: 'X', path: 'M18.901 1.153h3.68l-8.04 9.19L24 22.846h-7.406l-5.8-7.584-6.638 7.584H.474l8.6-9.83L0 1.154h7.594l5.243 6.932ZM17.61 20.644h2.039L6.486 3.24H4.298Z' },
    { name: 'TikTok', path: 'M12.525.02c1.31-.02 2.61-.01 3.91-.02.08 1.53.63 3.09 1.75 4.17 1.12 1.11 2.7 1.62 4.24 1.79v4.03c-1.44-.05-2.89-.35-4.2-.97-.57-.26-1.1-.59-1.62-.93-.01 2.92.01 5.84-.02 8.75-.08 1.4-.54 2.79-1.35 3.94-1.31 1.92-3.58 3.17-5.91 3.21-1.43.08-2.86-.31-4.08-1.03-2.02-1.19-3.44-3.37-3.65-5.71-.02-.5-.03-1-.01-1.49.18-1.9 1.12-3.72 2.58-4.96 1.66-1.44 3.98-2.13 6.15-1.72.02 1.48-.04 2.96-.04 4.44-.99-.32-2.15-.23-3.02.37-.63.41-1.11 1.04-1.36 1.75-.21.51-.15 1.07-.14 1.61.24 1.64 1.82 3.02 3.5 2.87 1.12-.01 2.19-.66 2.77-1.61.19-.33.4-.67.41-1.06.1-1.79.06-3.57.07-5.36.01-4.03-.01-8.05.02-12.07z' },
    { name: 'Pinterest', path: 'M12.017 0C5.396 0 .029 5.367.029 11.987c0 5.079 3.158 9.417 7.618 11.162-.105-.949-.199-2.403.041-3.439.219-.937 1.406-5.957 1.406-5.957s-.359-.72-.359-1.781c0-1.668.967-2.914 2.171-2.914 1.023 0 1.518.769 1.518 1.69 0 1.029-.655 2.568-.994 3.995-.283 1.194.599 2.169 1.777 2.169 2.133 0 3.772-2.249 3.772-5.495 0-2.873-2.064-4.882-5.012-4.882-3.414 0-5.418 2.561-5.418 5.207 0 1.031.397 2.138.893 2.738a.36.36 0 0 1 .083.345l-.333 1.36c-.053.22-.174.267-.402.161-1.499-.698-2.436-2.889-2.436-4.649 0-3.785 2.75-7.262 7.929-7.262 4.163 0 7.398 2.967 7.398 6.931 0 4.136-2.607 7.464-6.227 7.464-1.216 0-2.359-.631-2.75-1.378l-.748 2.853c-.271 1.043-1.002 2.35-1.492 3.146C9.57 23.812 10.763 24 12.017 24c6.624 0 11.99-5.367 11.99-11.988C24.007 5.367 18.641.001 12.017.001z' },
  ],
  [
    { name: 'Reddit', path: 'M12 0A12 12 0 0 0 0 12a12 12 0 0 0 12 12 12 12 0 0 0 12-12A12 12 0 0 0 12 0zm5.01 4.744c.688 0 1.25.561 1.25 1.249a1.25 1.25 0 0 1-2.498.056l-2.597-.547-.8 3.747c1.824.07 3.48.632 4.674 1.488.308-.309.73-.491 1.207-.491.968 0 1.754.786 1.754 1.754 0 .716-.435 1.333-1.01 1.614a3.111 3.111 0 0 1 .042.52c0 2.694-3.13 4.87-7.004 4.87-3.874 0-7.004-2.176-7.004-4.87 0-.183.015-.366.043-.534A1.748 1.748 0 0 1 4.028 12c0-.968.786-1.754 1.754-1.754.463 0 .898.196 1.207.49 1.207-.883 2.878-1.43 4.744-1.487l.885-4.182a.342.342 0 0 1 .14-.197.35.35 0 0 1 .238-.042l2.906.617a1.214 1.214 0 0 1 1.108-.701zM9.25 12C8.561 12 8 12.562 8 13.25c0 .687.561 1.248 1.25 1.248.687 0 1.248-.561 1.248-1.249 0-.688-.561-1.249-1.249-1.249zm5.5 0c-.687 0-1.248.561-1.248 1.25 0 .687.561 1.248 1.249 1.248.688 0 1.249-.561 1.249-1.249 0-.687-.562-1.249-1.25-1.249zm-5.466 3.99a.327.327 0 0 0-.231.094.33.33 0 0 0 0 .463c.842.842 2.484.913 2.961.913.477 0 2.105-.056 2.961-.913a.361.361 0 0 0 .029-.463.33.33 0 0 0-.464 0c-.547.533-1.684.73-2.512.73-.828 0-1.979-.196-2.512-.73a.326.326 0 0 0-.232-.095z' },
    { name: 'LinkedIn', path: 'M20.447 20.452h-3.554v-5.569c0-1.328-.027-3.037-1.852-3.037-1.853 0-2.136 1.445-2.136 2.939v5.667H9.351V9h3.414v1.561h.046c.477-.9 1.637-1.85 3.37-1.85 3.601 0 4.267 2.37 4.267 5.455v6.286zM5.337 7.433a2.062 2.062 0 0 1-2.063-2.065 2.064 2.064 0 1 1 2.063 2.065zm1.782 13.019H3.555V9h3.564v11.452zM22.225 0H1.771C.792 0 0 .774 0 1.729v20.542C0 23.227.792 24 1.771 24h20.451C23.2 24 24 23.227 24 22.271V1.729C24 .774 23.2 0 22.222 0h.003z' },
    { name: 'Spotify', path: 'M12 0C5.4 0 0 5.4 0 12s5.4 12 12 12 12-5.4 12-12S18.66 0 12 0zm5.521 17.34c-.24.359-.66.48-1.021.24-2.82-1.74-6.36-2.101-10.561-1.141-.418.122-.779-.179-.899-.539-.12-.421.18-.78.54-.9 4.56-1.021 8.52-.6 11.64 1.32.42.18.479.659.301 1.02zm1.44-3.3c-.301.42-.841.6-1.262.3-3.239-1.98-8.159-2.58-11.939-1.38-.479.12-1.02-.12-1.14-.6-.12-.48.12-1.021.6-1.141C9.6 9.9 15 10.561 18.72 12.84c.361.181.54.78.241 1.2zm.12-3.36C15.24 8.4 8.82 8.16 5.16 9.301c-.6.179-1.2-.181-1.38-.721-.18-.601.18-1.2.72-1.381 4.26-1.26 11.28-1.02 15.721 1.621.539.3.719 1.02.419 1.56-.299.421-1.02.599-1.559.3z' },
    { name: 'Medium', path: 'M13.54 12a6.8 6.8 0 01-6.77 6.82A6.8 6.8 0 010 12a6.8 6.8 0 016.77-6.82A6.8 6.8 0 0113.54 12zM20.96 12c0 3.54-1.51 6.42-3.38 6.42-1.87 0-3.39-2.88-3.39-6.42s1.52-6.42 3.39-6.42 3.38 2.88 3.38 6.42M24 12c0 3.17-.53 5.75-1.19 5.75-.66 0-1.19-2.58-1.19-5.75s.53-5.75 1.19-5.75C23.47 6.25 24 8.83 24 12z' },
    { name: 'Dribbble', path: 'M12 24C5.385 24 0 18.615 0 12S5.385 0 12 0s12 5.385 12 12-5.385 12-12 12zm10.12-10.358c-.35-.11-3.17-.953-6.384-.438 1.34 3.684 1.887 6.684 1.992 7.308 2.3-1.555 3.936-4.02 4.395-6.87zm-6.115 7.808c-.153-.9-.75-4.032-2.19-7.77l-.066.02c-5.79 2.015-7.86 6.025-8.04 6.4 1.73 1.358 3.92 2.166 6.29 2.166 1.42 0 2.77-.29 4-.81zm-11.62-2.58c.232-.4 3.045-5.055 8.332-6.765.135-.045.27-.084.405-.12-.26-.585-.54-1.167-.832-1.74C7.17 11.775 2.206 11.71 1.756 11.7l-.004.312c0 2.633.998 5.037 2.634 6.855zm-2.42-8.955c.46.008 4.683.026 9.477-1.248-1.698-3.018-3.53-5.558-3.8-5.928-2.868 1.35-5.01 3.99-5.676 7.17zM9.6 2.052c.282.38 2.145 2.914 3.822 6 3.645-1.365 5.19-3.44 5.373-3.702C16.86 2.61 14.545 1.62 12 1.62c-.8 0-1.6.1-2.4.285v.15zm10.335 3.483c-.218.29-1.91 2.493-5.724 4.04.24.49.47.985.68 1.486.08.18.15.36.22.53 3.41-.43 6.8.26 7.14.33-.02-2.42-.88-4.64-2.31-6.38z' },
  ],
  [
    { name: 'GitHub', path: 'M12 .297c-6.63 0-12 5.373-12 12 0 5.303 3.438 9.8 8.205 11.385.6.113.82-.258.82-.577 0-.285-.01-1.04-.015-2.04-3.338.724-4.042-1.61-4.042-1.61C4.422 18.07 3.633 17.7 3.633 17.7c-1.087-.744.084-.729.084-.729 1.205.084 1.838 1.236 1.838 1.236 1.07 1.835 2.809 1.305 3.495.998.108-.776.417-1.305.76-1.605-2.665-.3-5.466-1.332-5.466-5.93 0-1.31.465-2.38 1.235-3.22-.135-.303-.54-1.523.105-3.176 0 0 1.005-.322 3.3 1.23.96-.267 1.98-.399 3-.405 1.02.006 2.04.138 3 .405 2.28-1.552 3.285-1.23 3.285-1.23.645 1.653.24 2.873.12 3.176.765.84 1.23 1.91 1.23 3.22 0 4.61-2.805 5.625-5.475 5.92.42.36.81 1.096.81 2.22 0 1.606-.015 2.896-.015 3.286 0 .315.21.69.825.57C20.565 22.092 24 17.592 24 12.297c0-6.627-5.373-12-12-12' },
    { name: 'Twitch', path: 'M11.571 4.714h1.715v5.143H11.57zm4.715 0H18v5.143h-1.714zM6 0L1.714 4.286v15.428h5.143V24l4.286-4.286h3.428L22.286 12V0zm14.571 11.143l-3.428 3.428h-3.429l-3 3v-3H6.857V1.714h13.714z' },
    { name: 'Vimeo', path: 'M23.977 6.416c-.105 2.338-1.739 5.543-4.894 9.609-3.268 4.247-6.026 6.37-8.29 6.37-1.409 0-2.578-1.294-3.553-3.881L5.322 11.4C4.603 8.816 3.834 7.522 3.01 7.522c-.179 0-.806.378-1.881 1.132L0 7.197c1.185-1.044 2.351-2.084 3.501-3.128C5.08 2.701 6.266 1.984 7.055 1.91c1.867-.18 3.016 1.1 3.447 3.838.465 2.953.789 4.789.971 5.507.539 2.45 1.131 3.674 1.776 3.674.502 0 1.256-.796 2.265-2.385 1.004-1.589 1.54-2.797 1.612-3.628.144-1.371-.395-2.061-1.614-2.061-.574 0-1.167.121-1.777.391 1.186-3.868 3.434-5.757 6.762-5.637 2.473.06 3.628 1.664 3.493 4.797l-.013.01z' },
    { name: 'Behance', path: 'M22 7h-7V5h7zm1.726 10c-.442 1.297-2.029 3-5.101 3-3.074 0-5.564-1.729-5.564-5.675 0-3.91 2.325-5.92 5.466-5.92 3.082 0 4.964 1.782 5.375 4.426.078.506.109 1.188.095 2.14H15.97c.13 3.211 3.483 3.312 4.588 2.029h3.168zm-7.686-4h4.965c-.105-1.547-1.136-2.219-2.477-2.219-1.466 0-2.277.768-2.488 2.219zm-9.574 6.988H0V5.021h6.953c5.476.081 5.58 5.444 2.72 6.906 3.461 1.26 3.577 8.061-3.207 8.061zM3 11h3.584c2.508 0 2.906-3-.312-3H3v3zm3.391 3H3v3.016h3.341c3.055 0 2.868-3.016.05-3.016z' },
    { name: 'Product Hunt', path: 'M14.751 12H11.5v3.25h3.251a1.625 1.625 0 0 0 0-3.25zm0-4.75H11.5v3.25h3.251a1.625 1.625 0 0 0 0-3.25zM24 12c0 6.627-5.373 12-12 12S0 18.627 0 12 5.373 0 12 0s12 5.373 12 12zm-6.375 2.25a4.875 4.875 0 0 0-4.874-4.875H8.625v8.25h4.126a4.875 4.875 0 0 0 4.874-4.875z' },
  ],
]

const blockOpacities = [1, 0.7, 0.5, 0.35, 0.2]

function HeroPlatformIcons() {
  const [activeBlock, setActiveBlock] = useState(0)

  useEffect(() => {
    const timer = setInterval(() => {
      setActiveBlock((prev) => (prev + 1) % platformBlocks.length)
    }, 3000)
    return () => clearInterval(timer)
  }, [])

  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ delay: 0.9, duration: 0.6 }}
      className="flex items-center gap-3 mt-4 sm:mt-12 justify-center lg:justify-start"
    >
      <AnimatePresence mode="wait">
        <motion.div
          key={activeBlock}
          initial={{ opacity: 0, filter: 'blur(4px)' }}
          animate={{ opacity: 1, filter: 'blur(0px)' }}
          exit={{ opacity: 0, filter: 'blur(4px)' }}
          transition={{ duration: 0.5, ease: [0.22, 1, 0.36, 1] }}
          className="flex items-center gap-3"
        >
          {platformBlocks[activeBlock].map((platform, i) => (
            <div
              key={platform.name}
              className="w-10 h-10 rounded-full bg-white/10 backdrop-blur-sm flex items-center justify-center"
              style={{ opacity: blockOpacities[i] }}
            >
              <svg
                width="18"
                height="18"
                viewBox="0 0 24 24"
                fill="white"
                className="w-[18px] h-[18px]"
              >
                <path d={platform.path} />
              </svg>
            </div>
          ))}
        </motion.div>
      </AnimatePresence>
    </motion.div>
  )
}

function Section({ children, className = '', id }: { children: React.ReactNode; className?: string; id?: string }) {
  const ref = useRef(null)
  const inView = useInView(ref, { once: true, margin: '-60px' })
  return (
    <motion.section
      ref={ref}
      id={id}
      initial="hidden"
      animate={inView ? 'visible' : 'hidden'}
      variants={stagger}
      className={className}
    >
      {children}
    </motion.section>
  )
}

/* ─── phone mockup ─── */
function PhoneMockup({ src, alt, size = 'md' }: { src: string; alt: string; size?: 'sm' | 'md' | 'lg' }) {
  const sizes = { sm: 'w-40 md:w-48', md: 'w-52 md:w-60', lg: 'w-40 sm:w-52 md:w-72' }
  return (
    <div className={`${sizes[size]} mx-auto`}>
      <div className="phone-frame-apple">
        <Image src={src} alt={alt} width={300} height={650} className="w-full" />
      </div>
    </div>
  )
}

/* ─── app showcase carousel ─── */
const carouselImages = [
  '/images/mockups/air/karsilama.png',
  '/images/mockups/air/login.png',
  '/images/mockups/air/home.png',
  '/images/mockups/air/home_feed.png',
  '/images/mockups/air/home_masonary.png',
  '/images/mockups/air/koleksiyon.png',
  '/images/mockups/air/search.png',
  '/images/mockups/air/profil.png',
  '/images/mockups/air/login_sonrasi_icerikhazirlanma.png',
  '/images/mockups/vibe/home.png',
  '/images/mockups/vibe/home_feed.png',
  '/images/mockups/vibe/koleksiyon.png',
  '/images/mockups/vibe/koleksiyon_duzenle.png',
  '/images/mockups/vibe/tema.png',
]

function AppShowcase() {
  return (
    <Section id="ekranlar" className="py-32 bg-white overflow-hidden">
      <div className="max-w-6xl mx-auto px-6 sm:px-8">
        <motion.div variants={fadeUp} className="text-center mb-16">
          <p className="text-sm font-medium text-[#688E8B] uppercase tracking-widest mb-4">Uygulama Ekranları</p>
          <h2 className="text-4xl sm:text-5xl font-semibold text-gray-900 tracking-tight mb-4">
            Basit. Güçlü. Güzel.
          </h2>
          <p className="text-gray-500 text-lg max-w-xl mx-auto leading-relaxed">
            Beğendiğin içeriklere her zaman tek dokunuşla ulaş. Temiz, sade ve göze zevk veren bir deneyim.
          </p>
        </motion.div>
      </div>

      <motion.div variants={fadeUp} className="relative py-4">
        {/* Fade edges */}
        <div className="absolute left-0 top-0 bottom-0 w-16 sm:w-24 bg-gradient-to-r from-white to-transparent z-10 pointer-events-none" />
        <div className="absolute right-0 top-0 bottom-0 w-16 sm:w-24 bg-gradient-to-l from-white to-transparent z-10 pointer-events-none" />

        <Swiper
          modules={[Autoplay]}
          grabCursor
          centeredSlides
          slidesPerView={2.3}
          breakpoints={{
            480: { slidesPerView: 3.3 },
            640: { slidesPerView: 5.7 },
          }}
          loop
          autoplay={{ delay: 2500, disableOnInteraction: false, pauseOnMouseEnter: true }}
          speed={700}
          spaceBetween={12}
          className="!overflow-x-hidden !overflow-y-visible py-10"
        >
          {carouselImages.map((src, i) => (
            <SwiperSlide key={i}>
              <div className="carousel-card relative rounded-[1.5rem] overflow-hidden">
                <Image
                  src={src}
                  alt={`Somine ekran ${i + 1}`}
                  width={220}
                  height={476}
                  className="w-full h-auto"
                />
              </div>
            </SwiperSlide>
          ))}
        </Swiper>
      </motion.div>
    </Section>
  )
}

/* ─── main page ─── */
export default function Home() {
  const heroRef = useRef(null)

  const features = [
    {
      icon: Play,
      title: 'Her Platformdan İçerik',
      desc: 'Instagram, YouTube, Pinterest ve daha fazlası — beğendiğin içerikleri hangi platformda olursa olsun koleksiyonuna ekle.',
      accent: '#6FBFAC',
    },
    {
      icon: FolderOpen,
      title: 'Akıllı Kategoriler',
      desc: 'Beğendiğin içerikleri düzenli ve bulunması kolay hale getir. İstediğin kadar kategori oluştur, istediğin gibi düzenle.',
      accent: '#95C5C1',
    },
    {
      icon: StickyNote,
      title: 'Kişisel Notlar',
      desc: 'Her içeriğe kendi notunu ekle. Neden beğendiğini, ne yapmak istediğini kaybet.',
      accent: '#B8DDD9',
    },
    {
      icon: ShieldCheck,
      title: 'Gizli Kasa',
      desc: 'Sadece senin görmeni istediğin içerikler için. Face ID ile korunan özel koleksiyonlar. Tamamen ücretsiz.',
      accent: '#688E8B',
    },
    {
      icon: Share2,
      title: 'Kolay Paylaşım',
      desc: 'Kullanıcı adı veya e-posta ile arkadaşını bul ve koleksiyonunu gönder. Kabul ettiği anda içerikler onun kütüphanesinde.',
      accent: '#6FBFAC',
    },
    {
      icon: Palette,
      title: 'Premium Temalar',
      desc: 'Air, Midnight, Vibe — tüm temalar ücretsiz. Ana ekran uygulama ikonu ve özel koleksiyon ikonları Premium ile gelir.',
      accent: '#95C5C1',
    },
  ]


  return (
    <main className="min-h-screen">
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{
          __html: JSON.stringify({
            '@context': 'https://schema.org',
            '@type': 'SoftwareApplication',
            name: 'Somine',
            operatingSystem: 'iOS',
            applicationCategory: 'ProductivityApplication',
            description: 'Sevdiğin platformların içerikleri ile web linklerini kişisel koleksiyonlarında organize et.',
            url: 'https://somineapp.com',
            offers: {
              '@type': 'Offer',
              price: '0',
              priceCurrency: 'TRY',
            },
          }),
        }}
      />
      <Navbar />

      {/* ══════════ HERO ══════════ */}
      <section ref={heroRef} className="relative min-h-screen flex items-center overflow-hidden" style={{ background: 'linear-gradient(135deg, #688E8B 0%, #7AA39F 30%, #6FBFAC 60%, #8DD0C0 80%, #A8DDD0 100%)' }}>
        {/* Ambient glow */}
        <div className="absolute inset-0 overflow-hidden pointer-events-none">
          <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[800px] h-[800px] bg-gradient-to-r from-[#95C5C1]/25 via-[#B8DDD9]/15 to-[#D4EDE9]/25 rounded-full blur-[120px]" style={{ animation: 'pulse-glow 6s ease-in-out infinite' }} />
          <div className="absolute top-[20%] left-[10%] w-[300px] h-[300px] bg-gradient-to-br from-[#95C5C1]/15 to-transparent rounded-full blur-[80px]" />
        </div>

        {/* Grid pattern overlay */}
        <div className="absolute inset-0 opacity-[0.03]" style={{ backgroundImage: 'radial-gradient(circle, #fff 1px, transparent 1px)', backgroundSize: '40px 40px' }} />

        {/* Floating particles */}
        <motion.div
          animate={{ y: [0, -25, 0], opacity: [0.3, 0.6, 0.3] }}
          transition={{ duration: 7, repeat: 9999, ease: 'easeInOut' }}
          className="absolute top-[18%] left-[12%] w-1.5 h-1.5 rounded-full bg-white/40 hidden lg:block"
        />
        <motion.div
          animate={{ y: [0, 18, 0], opacity: [0.2, 0.5, 0.2] }}
          transition={{ duration: 5, repeat: 9999, ease: 'easeInOut', delay: 1 }}
          className="absolute top-[35%] right-[18%] w-1 h-1 rounded-full bg-white/30 hidden lg:block"
        />
        <motion.div
          animate={{ y: [0, -15, 0], x: [0, 10, 0] }}
          transition={{ duration: 9, repeat: 9999, ease: 'easeInOut', delay: 2 }}
          className="absolute bottom-[30%] left-[25%] w-2 h-2 rounded-full bg-white/20 hidden lg:block"
        />
        <motion.div
          animate={{ y: [0, 20, 0], x: [0, -8, 0] }}
          transition={{ duration: 11, repeat: 9999, ease: 'easeInOut', delay: 3 }}
          className="absolute top-[50%] right-[10%] w-1.5 h-1.5 rounded-full bg-white/30 hidden lg:block"
        />

        <div className="max-w-6xl mx-auto px-6 sm:px-8 w-full pt-8 pb-8 md:py-20 relative z-10">
          <div className="grid lg:grid-cols-2 gap-4 lg:gap-12 items-center">
            {/* Left: Text */}
            <motion.div
              initial={{ opacity: 0, y: 40 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 1, ease: [0.22, 1, 0.36, 1] }}
              className="text-center lg:text-left order-2 lg:order-1"
            >
              <motion.h1
                initial={{ opacity: 0, y: 30 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.3, duration: 0.8, ease: [0.22, 1, 0.36, 1] }}
                className="text-4xl sm:text-6xl lg:text-7xl font-semibold text-white leading-[1.08] mb-3 sm:mb-8 tracking-tight"
              >
                Beğendiklerini{' '}
                <span className="bg-gradient-to-r from-white to-[#D4EDE9] bg-clip-text text-transparent">
                  Tek Bir Yerde Topla
                </span>
              </motion.h1>

              <motion.p
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.5, duration: 0.7, ease: [0.22, 1, 0.36, 1] }}
                className="text-sm sm:text-lg md:text-xl text-white max-w-lg mx-auto lg:mx-0 mb-6 sm:mb-10 leading-relaxed font-light"
              >
                {'Instagram\'dan, Pinterest\'ten, YouTube\'dan — beğendiğin her şey artık bir arada.'}
              </motion.p>

              <motion.div
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.7, duration: 0.6 }}
                className="flex flex-col sm:flex-row items-center gap-4 justify-center lg:justify-start"
              >
                <motion.a
                  href="https://apps.apple.com"
                  target="_blank"
                  rel="noopener noreferrer"
                  whileHover={{ scale: 1.04, y: -2 }}
                  whileTap={{ scale: 0.98 }}
                  className="hidden sm:inline-flex items-center gap-3 bg-white text-[#1a3b38] text-base font-medium px-7 py-3.5 rounded-full shadow-[0_0_40px_rgba(255,255,255,0.15)] hover:shadow-[0_0_60px_rgba(255,255,255,0.25)] transition-shadow"
                >
                  <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor">
                    <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.8-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z" />
                  </svg>
                  <div className="text-left">
                    <div className="text-[10px] opacity-50 leading-none font-normal">İndir</div>
                    <div className="font-semibold leading-tight text-sm">App Store</div>
                  </div>
                </motion.a>

                <motion.div whileHover={{ scale: 1.02 }} whileTap={{ scale: 0.98 }} className="hidden sm:block">
                  <Link href="/#ozellikler">
                    <Button
                      variant="outline"
                      size="lg"
                      className="rounded-full bg-white/[0.08] border-white/[0.15] text-white/80 hover:bg-white/[0.15] hover:text-white hover:border-white/[0.25] gap-2 backdrop-blur-sm font-medium"
                    >
                      Özellikleri Keşfet
                      <ArrowRight className="w-4 h-4" />
                    </Button>
                  </Link>
                </motion.div>
              </motion.div>

              {/* Mobile App Store CTA */}
              <motion.a
                href="https://apps.apple.com"
                target="_blank"
                rel="noopener noreferrer"
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.8, duration: 0.6 }}
                className="sm:hidden inline-flex items-center gap-3 bg-white text-[#1a3b38] text-base font-medium px-7 py-3.5 rounded-full shadow-[0_0_40px_rgba(255,255,255,0.15)] mb-6"
              >
                <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor">
                  <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.8-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z" />
                </svg>
                <div className="text-left">
                  <div className="text-[10px] opacity-50 leading-none font-normal">İndir</div>
                  <div className="font-semibold leading-tight text-sm">App Store</div>
                </div>
              </motion.a>

              {/* Platform Icons */}
              <HeroPlatformIcons />
            </motion.div>

            {/* Right: Phone mockup */}
            <motion.div
              initial={{ opacity: 0, y: 60, scale: 0.9 }}
              animate={{ opacity: 1, y: 0, scale: 1 }}
              transition={{ duration: 1.2, delay: 0.4, ease: [0.22, 1, 0.36, 1] }}
              className="flex justify-center lg:justify-end order-1 lg:order-2"
            >
              <div className="relative">
                {/* Glow behind phone */}
                <div className="absolute inset-0 bg-gradient-to-b from-[#95C5C1]/25 via-[#B8DDD9]/10 to-transparent rounded-[3rem] blur-3xl scale-110" />

                {/* Orbiting ring */}
                <motion.div
                  animate={{ rotate: 360 }}
                  transition={{ duration: 25, repeat: 9999, ease: 'linear' }}
                  className="absolute -inset-10 rounded-full border border-white/[0.08]"
                />

                <div className="relative animate-float">
                  <PhoneMockup src="/images/mockups/vibe/home.png" alt="Somine Ana Sayfa" size="lg" />
                </div>
              </div>
            </motion.div>
          </div>
        </div>

        {/* Scroll indicator */}
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 2 }}
          className="absolute bottom-10 left-1/2 -translate-x-1/2 z-10 hidden sm:block"
        >
          <motion.div
            animate={{ y: [0, 6, 0] }}
            transition={{ repeat: 9999, duration: 2.5, ease: 'easeInOut' }}
            className="flex flex-col items-center gap-2"
          >
            <span className="text-[11px] text-white/30 uppercase tracking-widest">Keşfet</span>
            <div className="w-5 h-8 rounded-full border border-white/15 flex items-start justify-center pt-1.5">
              <motion.div
                animate={{ opacity: [0.5, 0], y: [0, 6] }}
                transition={{ repeat: 9999, duration: 2.5 }}
                className="w-1 h-1 rounded-full bg-white/50"
              />
            </div>
          </motion.div>
        </motion.div>
      </section>

      {/* ══════════ FEATURES BENTO ══════════ */}
      <Section id="ozellikler" className="py-32 bg-[#E8F1EF]">
        <div className="max-w-6xl mx-auto px-6 sm:px-8">
          <motion.div variants={fadeUp} className="text-center mb-20">
            <p className="text-sm font-medium text-[#688E8B] uppercase tracking-widest mb-4">Özellikler</p>
            <h2 className="text-4xl sm:text-5xl font-semibold text-gray-900 tracking-tight mb-4">
              Her Şeyi Tek Bir Yerde Topla
            </h2>
            <p className="text-gray-500 text-lg max-w-xl mx-auto leading-relaxed">
              Sadece kaydetmekle kalmaz — kategorize eder, not alır, güvende tutar ve paylaşırsın.
            </p>
          </motion.div>

          <motion.div variants={stagger} className="grid grid-cols-1 md:grid-cols-3 gap-5">
            {features.map((f) => (
              <motion.div
                key={f.title}
                variants={fadeUp}
                whileHover={{ y: -4 }}
                transition={{ type: 'spring', stiffness: 300, damping: 25 }}
                className="group relative rounded-2xl border border-gray-100 bg-white p-8 hover:border-[#D4EDE9] hover:shadow-[0_8px_40px_rgba(104,142,139,0.08)] transition-all duration-500"
              >
                <div
                  className="w-16 h-16 rounded-2xl flex items-center justify-center mb-6"
                  style={{ background: `linear-gradient(135deg, ${f.accent}, #B8DDD9)` }}
                >
                  <f.icon className="w-7 h-7 text-white" />
                </div>
                <h3 className="text-base font-semibold text-gray-900 mb-2">{f.title}</h3>
                <p className="text-gray-500 text-sm leading-relaxed">{f.desc}</p>
              </motion.div>
            ))}
          </motion.div>
        </div>
      </Section>

      {/* ══════════ APP SHOWCASE ══════════ */}
      <AppShowcase />

      {/* ══════════ HOW IT WORKS ══════════ */}
      <Section id="nasil-calisir" className="py-32 bg-[#E8F1EF]">
        <div className="max-w-6xl mx-auto px-6 sm:px-8">
          <motion.div variants={fadeUp} className="text-center mb-20">
            <p className="text-sm font-medium text-[#688E8B] uppercase tracking-widest mb-4">Nasıl Çalışır</p>
            <h2 className="text-4xl sm:text-5xl font-semibold text-gray-900 tracking-tight mb-4">
              Tek Tıkla Koleksiyonuna Ekle
            </h2>
            <p className="text-gray-500 text-lg max-w-xl mx-auto leading-relaxed">
              Herhangi bir uygulamadan içeriklerini Somine koleksiyonlarına kaydetmek sadece 3 adım. İçerik kopyalanmaz — orijinal haliyle platforma bağlı kalır.
            </p>
          </motion.div>

          {/* Steps with connecting line */}
          <div className="relative">
            {/* Connecting line — Segment 1 (desktop) */}
            <div className="hidden md:block absolute top-[4.5rem] left-[22%] w-[23%] h-[2px] overflow-hidden">
              <div className="absolute inset-0 bg-[#D4EDE9]" />
              <div
                className="absolute inset-y-[-5px] w-[35%] animate-glow-seg1"
                style={{ background: 'linear-gradient(90deg, transparent, rgba(111,191,172,0.5), transparent)', filter: 'blur(4px)' }}
              />
              <div
                className="absolute inset-y-0 w-[25%] animate-pulse-seg1"
                style={{ background: 'linear-gradient(90deg, transparent, #6FBFAC, #6FBFAC, transparent)' }}
              />
            </div>
            {/* Connecting line — Segment 2 (desktop) */}
            <div className="hidden md:block absolute top-[4.5rem] left-[55%] w-[23%] h-[2px] overflow-hidden">
              <div className="absolute inset-0 bg-[#D4EDE9]" />
              <div
                className="absolute inset-y-[-5px] w-[35%] animate-glow-seg2"
                style={{ background: 'linear-gradient(90deg, transparent, rgba(111,191,172,0.5), transparent)', filter: 'blur(4px)' }}
              />
              <div
                className="absolute inset-y-0 w-[25%] animate-pulse-seg2"
                style={{ background: 'linear-gradient(90deg, transparent, #6FBFAC, #6FBFAC, transparent)' }}
              />
            </div>

            <motion.div variants={stagger} className="grid grid-cols-1 md:grid-cols-3 gap-10 md:gap-6">
              {[
                {
                  icon: Share2,
                  title: 'Platformtan Paylaş',
                  desc: 'Desteklediğimiz platformlardan share (paylaş) seçimi yap.',
                  num: '01',
                },
                {
                  icon: MousePointerClick,
                  title: 'Somine\'ye Tıkla',
                  desc: 'Çıkan uygulama listesinden Somine logosuna tıkla.',
                  num: '02',
                },
                {
                  icon: BookmarkPlus,
                  title: 'Koleksiyona Ekle',
                  desc: '"Koleksiyona Ekle" ile içeriğini kaydet — İşte bu kadar kolay!',
                  num: '03',
                },
              ].map((step, idx) => (
                <motion.div
                  key={step.title}
                  variants={fadeUp}
                  className="relative text-center group"
                >
                  {/* Step circle with icon */}
                  <div
                    className="relative inline-flex items-center justify-center mb-8 animate-step-bounce"
                    style={{ animationDelay: `${idx * 1.5}s` }}
                  >
                    {/* Number badge */}
                    <span
                      className="absolute -top-3 -right-3 w-8 h-8 rounded-full text-white text-xs font-bold flex items-center justify-center z-10 shadow-md"
                      style={{ background: 'linear-gradient(135deg, #688E8B, #6FBFAC)' }}
                    >
                      {step.num}
                    </span>

                    {/* Icon container */}
                    <div
                      className="w-[7.5rem] h-[7.5rem] rounded-2xl flex items-center justify-center group-hover:scale-105 transition-transform duration-300 shadow-lg"
                      style={{ background: 'linear-gradient(135deg, #688E8B, #6FBFAC)' }}
                    >
                      <step.icon className="w-10 h-10 text-white" />
                    </div>
                  </div>

                  <h3 className="text-lg font-semibold text-[#688E8B] mb-2">{step.title}</h3>
                  <p className="text-gray-500 text-sm leading-relaxed max-w-[250px] mx-auto">
                    {step.desc}
                  </p>

                  {/* Mobile connector */}
                  {idx < 2 && (
                    <div className="md:hidden flex justify-center my-4">
                      <div className="relative w-[2px] h-8 overflow-hidden">
                        <div className="absolute inset-0 bg-gradient-to-b from-[#B8DDD9] to-transparent" />
                        <div
                          className="absolute inset-x-0 h-[40%] animate-electric-pulse-v"
                          style={{ background: 'linear-gradient(180deg, transparent, #6FBFAC, transparent)' }}
                        />
                      </div>
                    </div>
                  )}
                </motion.div>
              ))}
            </motion.div>
          </div>
        </div>
      </Section>

      {/* ══════════ PLATFORM SUPPORT ══════════ */}
      <Section id="platformlar" className="py-32 bg-[#0A0A0A] relative overflow-hidden">
        {/* Ambient glow */}
        <div className="absolute inset-0 pointer-events-none">
          <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[600px] h-[600px] bg-gradient-to-r from-[#95C5C1]/8 to-[#D4EDE9]/5 rounded-full blur-[100px]" />
        </div>

        <div className="max-w-6xl mx-auto px-6 sm:px-8 relative z-10">
          {/* Header */}
          <motion.div variants={fadeUp} className="text-center mb-20">
            <p className="text-sm font-medium text-gray-500 uppercase tracking-widest mb-4">Platform Desteği</p>
            <h2 className="text-4xl sm:text-5xl lg:text-6xl font-semibold text-white tracking-tight mb-4">
              Her Yerden{' '}
              <span className="bg-gradient-to-r from-[#95C5C1] to-[#D4EDE9] bg-clip-text text-transparent">Kaydet</span>
            </h2>
            <p className="text-gray-500 text-lg max-w-xl mx-auto leading-relaxed">
              Instagram, YouTube, Pinterest ve daha fazlası — 15+ popüler platformun yanı sıra tüm web linklerini tek bir yerde topla.
            </p>
          </motion.div>
        </div>

        {/* Platform grid */}
        <div className="max-w-4xl mx-auto px-6 sm:px-8 relative z-10">
          <motion.div
            variants={stagger}
            className="grid grid-cols-4 sm:grid-cols-7 gap-4"
          >
            {[...platformIconsRow1, ...platformIconsRow2].map((icon, i) => (
              <motion.div
                key={i}
                variants={fadeUp}
                className="flex flex-col items-center gap-2 group"
              >
                <div className="w-14 h-14 sm:w-16 sm:h-16 rounded-2xl bg-white/[0.03] border border-white/[0.06] flex items-center justify-center hover:bg-white/[0.08] hover:border-white/[0.2] hover:scale-105 transition-all duration-300">
                  <svg viewBox={icon.viewBox} className="w-6 h-6 sm:w-7 sm:h-7 fill-gray-500 group-hover:fill-white transition-colors duration-300">
                    <path d={icon.path} />
                  </svg>
                </div>
                <span className="text-[10px] text-gray-600 group-hover:text-gray-400 transition-colors duration-300 text-center leading-tight">{icon.name}</span>
              </motion.div>
            ))}
          </motion.div>
        </div>
      </Section>

      {/* ══════════ THEMES SHOWCASE ══════════ */}
      <Section id="temalar" className="py-32 bg-[#FAFAFA] overflow-hidden">
        <div className="max-w-6xl mx-auto px-6 sm:px-8">
          <motion.div variants={fadeUp} className="text-center mb-20">
            <p className="text-sm font-medium text-gray-400 uppercase tracking-widest mb-4">Temalar</p>
            <h2 className="text-4xl sm:text-5xl font-semibold tracking-tight mb-4 animate-theme-gradient">
              Kendi Tarzını Yansıt
            </h2>
            <p className="text-gray-500 text-lg max-w-xl mx-auto leading-relaxed">
              Air ücretsiz, Midnight ve Vibe ise Premium ile açılır. Hangisi sana uygunsa onu seç, uygulamanı istediğin gibi hissettir.
            </p>
          </motion.div>

          <motion.div variants={stagger} className="grid grid-cols-1 md:grid-cols-3 gap-6">
            {/* Air Theme */}
            <motion.div
              variants={fadeUp}
              whileHover={{ y: -8 }}
              transition={{ type: 'spring', stiffness: 300, damping: 25 }}
              className="group rounded-2xl overflow-hidden bg-white border border-gray-100 hover:shadow-[0_20px_60px_rgba(0,0,0,0.08)] transition-all duration-500"
            >
              <div className="aspect-[9/16] relative">
                <div className="absolute inset-0 bg-gradient-to-b from-[#688E8B] to-[#E8F1EF]" />
                <div className="absolute inset-0 flex flex-col items-center justify-center p-8 gap-4">
                  <div className="w-full flex flex-col items-center gap-3 rounded-2xl py-5 px-4">
                    <div className="w-14 h-14 rounded-xl bg-white/20 flex items-center justify-center backdrop-blur-sm">
                      <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round">
                        <circle cx="12" cy="12" r="4" />
                        <path d="M12 2v2" /><path d="M12 20v2" />
                        <path d="m4.93 4.93 1.41 1.41" /><path d="m17.66 17.66 1.41 1.41" />
                        <path d="M2 12h2" /><path d="M20 12h2" />
                        <path d="m6.34 17.66-1.41 1.41" /><path d="m19.07 4.93-1.41 1.41" />
                      </svg>
                    </div>
                    <div className="text-center">
                      <p className="text-lg font-semibold text-white">Air</p>
                      <p className="text-xs text-white/70">Minimalist & Ferah</p>
                    </div>
                  </div>
                  <div className="w-full space-y-2.5 mt-2">
                    <div className="h-3 rounded-md bg-[#688E8B]/20 relative overflow-hidden"><div className="absolute inset-0 skeleton-shimmer rounded-md" /></div>
                    <div className="h-3 rounded-md bg-[#688E8B]/20 w-4/5 relative overflow-hidden"><div className="absolute inset-0 skeleton-shimmer rounded-md" style={{ animationDelay: '0.3s' }} /></div>
                    <div className="h-3 rounded-md bg-[#95C5C1]/25 w-3/5 relative overflow-hidden"><div className="absolute inset-0 skeleton-shimmer rounded-md" style={{ animationDelay: '0.6s' }} /></div>
                    <div className="h-8 rounded-md bg-[#688E8B]/15 w-2/5 mt-3 relative overflow-hidden"><div className="absolute inset-0 skeleton-shimmer rounded-md" style={{ animationDelay: '0.9s' }} /></div>
                  </div>
                </div>
              </div>
              <div className="p-5 border-t border-[#D4E8E4] bg-[#E8F1EF]">
                <p className="font-semibold text-[#2D312F] text-sm">Air Teması</p>
                <p className="text-xs text-[#636E72] mt-0.5">Açık renkler, sade tasarım</p>
              </div>
            </motion.div>

            {/* Midnight Theme */}
            <motion.div
              variants={fadeUp}
              whileHover={{ y: -8 }}
              transition={{ type: 'spring', stiffness: 300, damping: 25 }}
              className="group rounded-2xl overflow-hidden bg-white border border-gray-100 hover:shadow-[0_20px_60px_rgba(0,0,0,0.08)] transition-all duration-500"
            >
              <div className="aspect-[9/16] relative">
                <div className="absolute inset-0 bg-gradient-to-b from-[#2DD4BF] to-[#1E1E1E]" />
                <div className="absolute inset-0 flex flex-col items-center justify-center p-8 gap-4">
                  <div className="w-full flex flex-col items-center gap-3 rounded-2xl py-5 px-4">
                    <div className="w-14 h-14 rounded-xl bg-white/20 flex items-center justify-center backdrop-blur-sm">
                      <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round">
                        <path d="M12 3a6 6 0 0 0 9 9 9 9 0 1 1-9-9Z" />
                      </svg>
                    </div>
                    <div className="text-center">
                      <p className="text-lg font-semibold text-white">Midnight</p>
                      <p className="text-xs text-white/70">Karanlık & Şık</p>
                    </div>
                  </div>
                  <div className="w-full space-y-2.5 mt-2">
                    <div className="h-3 rounded-md bg-white/5 relative overflow-hidden"><div className="absolute inset-0 skeleton-shimmer-dark rounded-md" /></div>
                    <div className="h-3 rounded-md bg-white/5 w-4/5 relative overflow-hidden"><div className="absolute inset-0 skeleton-shimmer-dark rounded-md" style={{ animationDelay: '0.3s' }} /></div>
                    <div className="h-3 rounded-md bg-white/5 w-3/5 relative overflow-hidden"><div className="absolute inset-0 skeleton-shimmer-dark rounded-md" style={{ animationDelay: '0.6s' }} /></div>
                    <div className="h-8 rounded-md bg-white/3 w-2/5 mt-3 relative overflow-hidden"><div className="absolute inset-0 skeleton-shimmer-dark rounded-md" style={{ animationDelay: '0.9s' }} /></div>
                  </div>
                </div>
              </div>
              <div className="p-5 bg-[#1E1E1E] border-t border-white/5">
                <p className="font-semibold text-[#F1F5F9] text-sm">Midnight Teması</p>
                <p className="text-xs text-[#94A3B8] mt-0.5">Koyu tonlar, göz dostu</p>
              </div>
            </motion.div>

            {/* Vibe Theme */}
            <motion.div
              variants={fadeUp}
              whileHover={{ y: -8 }}
              transition={{ type: 'spring', stiffness: 300, damping: 25 }}
              className="group rounded-2xl overflow-hidden bg-white border border-gray-100 hover:shadow-[0_20px_60px_rgba(0,0,0,0.08)] transition-all duration-500"
            >
              <div className="aspect-[9/16] relative">
                <div className="absolute inset-0 bg-gradient-to-b from-[#E86B8A] to-[#1A2A3A]" />
                <div className="absolute inset-0 flex flex-col items-center justify-center p-8 gap-4">
                  <div className="w-full flex flex-col items-center gap-3 rounded-2xl py-5 px-4">
                    <div className="w-14 h-14 rounded-xl bg-white/20 flex items-center justify-center backdrop-blur-sm">
                      <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round">
                        <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2" />
                      </svg>
                    </div>
                    <div className="text-center">
                      <p className="text-lg font-semibold text-white">Vibe</p>
                      <p className="text-xs text-white/70">Enerjik & Cesur</p>
                    </div>
                  </div>
                  <div className="w-full space-y-2.5 mt-2">
                    <div className="h-3 rounded-md bg-white/5 relative overflow-hidden"><div className="absolute inset-0 skeleton-shimmer-dark rounded-md" /></div>
                    <div className="h-3 rounded-md bg-white/5 w-4/5 relative overflow-hidden"><div className="absolute inset-0 skeleton-shimmer-dark rounded-md" style={{ animationDelay: '0.3s' }} /></div>
                    <div className="h-3 rounded-md bg-white/5 w-3/5 relative overflow-hidden"><div className="absolute inset-0 skeleton-shimmer-dark rounded-md" style={{ animationDelay: '0.6s' }} /></div>
                    <div className="h-8 rounded-md bg-white/3 w-2/5 mt-3 relative overflow-hidden"><div className="absolute inset-0 skeleton-shimmer-dark rounded-md" style={{ animationDelay: '0.9s' }} /></div>
                  </div>
                </div>
              </div>
              <div className="p-5 bg-[#1A2A3A] border-t border-[#E86B8A]/10">
                <p className="font-semibold text-[#F5F5F5] text-sm">Vibe Teması</p>
                <p className="text-xs text-[#B0C0C8] mt-0.5">Pembe-mavi gradient, enerjik</p>
              </div>
            </motion.div>
          </motion.div>

          <motion.div variants={fadeUp} className="text-center mt-14">
            <p className="text-sm text-gray-400">
              Premium&apos;a geçerek tüm temalara ve özel uygulama ikonlarına eriş
            </p>
          </motion.div>
        </div>
      </Section>

      {/* ══════════ PREMIUM ══════════ */}
      <Section id="premium" className="py-20 sm:py-28 bg-[#0A0A0A] relative overflow-hidden">
        {/* Ambient glow */}
        <div className="absolute inset-0 pointer-events-none">
          <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[600px] h-[600px] bg-gradient-to-r from-[#95C5C1]/8 to-[#D4EDE9]/5 rounded-full blur-[100px]" />
        </div>

        <div className="max-w-6xl mx-auto px-6 sm:px-8 relative z-10">
          <motion.div variants={fadeUp} className="text-center mb-20">
            <p className="text-sm font-medium text-gray-500 uppercase tracking-widest mb-4">Premium</p>
            <h2 className="text-4xl sm:text-5xl lg:text-6xl font-semibold text-white tracking-tight mb-4">
              Sınırları{' '}
              <span className="bg-gradient-to-r from-[#95C5C1] to-[#D4EDE9] bg-clip-text text-transparent">Kaldır</span>
            </h2>
            <p className="text-gray-500 text-lg max-w-xl mx-auto leading-relaxed">
              Sınırları kaldır, koleksiyonlarını ve içeriklerini sınırsız büyüt. Uygulamanı tamamen kendine göre özelleştir.
            </p>
          </motion.div>

          {/* Plan comparison */}
          <motion.div variants={stagger} className="max-w-4xl mx-auto">
            <div className="grid sm:grid-cols-2 gap-6">

              {/* Starter */}
              <motion.div variants={fadeUp} className="bg-white/[0.03] border border-white/[0.06] rounded-2xl p-7">
                <p className="text-xs font-medium text-gray-500 uppercase tracking-widest mb-2">Ücretsiz</p>
                <h3 className="text-2xl font-semibold text-white mb-1">Starter</h3>
                <p className="text-sm text-gray-500 mb-6">Temel ihtiyaçlar için tamamen ücretsiz</p>
                <div className="space-y-3">
                  {[
                    { label: '10 Koleksiyon', ok: true },
                    { label: 'Koleksiyon başına 5 içerik', ok: true },
                    { label: 'Gizli Kasa (Face ID / Touch ID)', ok: true },
                    { label: 'Bulut senkronizasyonu', ok: true },
                    { label: 'Koleksiyon paylaşımı', ok: false },
                    { label: 'Akıllı link önizleme', ok: true },
                    { label: 'Air teması', ok: true },
                    { label: '15+ platform desteği', ok: true },
                    { label: 'Özel uygulama ikonları', ok: false },
                  ].map((f) => (
                    <div key={f.label} className="flex items-center gap-3">
                      {f.ok
                        ? <Check className="w-4 h-4 text-[#95C5C1] shrink-0" />
                        : <X className="w-4 h-4 text-white/15 shrink-0" />
                      }
                      <span className={`text-sm ${f.ok ? 'text-gray-300' : 'text-gray-600'}`}>{f.label}</span>
                    </div>
                  ))}
                </div>
              </motion.div>

              {/* Premium */}
              <motion.div variants={fadeUp} className="relative bg-gradient-to-b from-[#95C5C1]/10 to-white/[0.02] border border-[#95C5C1]/25 rounded-2xl p-7">
                <div className="absolute top-4 right-4 text-[11px] font-medium bg-[#95C5C1]/15 text-[#95C5C1] px-3 py-1 rounded-full border border-[#95C5C1]/20">
                  👑 Premium
                </div>
                <p className="text-xs font-medium text-[#95C5C1]/60 uppercase tracking-widest mb-2">Ücretli</p>
                <h3 className="text-2xl font-semibold text-white mb-1">Premium</h3>
                <p className="text-sm text-gray-500 mb-6">Sınırsız özgürlük, tam özelleştirme</p>
                <div className="space-y-3">
                  {[
                    'Sınırsız koleksiyon',
                    'Sınırsız içerik',
                    'Gizli Kasa (Face ID / Touch ID)',
                    'Bulut senkronizasyonu',
                    'Koleksiyon paylaşımı',
                    'Akıllı link önizleme',
                    'Air, Midnight, Vibe temaları',
                    '15+ platform desteği',
                    '5 Özel uygulama ikonu',
                  ].map((f) => (
                    <div key={f} className="flex items-center gap-3">
                      <Check className="w-4 h-4 text-[#95C5C1] shrink-0" />
                      <span className="text-sm text-gray-300">{f}</span>
                    </div>
                  ))}
                </div>
              </motion.div>

            </div>
          </motion.div>
        </div>
      </Section>

      {/* ══════════ CTA ══════════ */}
      <Section className="py-24 sm:py-32 bg-[#0A0A0A] relative overflow-hidden">
        {/* Glow */}
        <div className="absolute inset-0 pointer-events-none">
          <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[500px] h-[500px] bg-gradient-to-r from-[#688E8B]/20 via-[#95C5C1]/10 to-[#D4EDE9]/10 rounded-full blur-[100px]" />
        </div>

        <div className="max-w-2xl mx-auto px-6 sm:px-8 text-center relative z-10">
          <motion.div variants={fadeUp}>
            <motion.p variants={fadeUp} className="text-sm font-medium text-[#95C5C1]/70 uppercase tracking-widest mb-4">
              Ücretsiz başla
            </motion.p>
            <motion.h2
              variants={fadeUp}
              className="text-4xl sm:text-5xl lg:text-6xl font-semibold tracking-tight mb-5 text-white"
            >
              Beğendiklerini{' '}
              <span className="bg-gradient-to-r from-[#95C5C1] to-[#D4EDE9] bg-clip-text text-transparent">
                tek bir yerde topla
              </span>
            </motion.h2>
            <motion.p
              variants={fadeUp}
              className="text-white/40 text-lg max-w-md mx-auto mb-10 leading-relaxed"
            >
              Artık her şeyin bir yeri var.
            </motion.p>
            <motion.div variants={fadeUp}>
              <motion.a
                href="https://apps.apple.com"
                target="_blank"
                rel="noopener noreferrer"
                whileHover={{ scale: 1.04, y: -2 }}
                whileTap={{ scale: 0.98 }}
                className="inline-flex items-center gap-3 bg-white text-[#1a3b38] text-sm font-medium px-7 py-3.5 rounded-full shadow-[0_0_50px_rgba(149,197,193,0.2)] hover:shadow-[0_0_70px_rgba(149,197,193,0.35)] transition-shadow"
              >
                <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor">
                  <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.8-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z" />
                </svg>
                <div className="text-left">
                  <div className="text-[10px] opacity-50 leading-none font-normal">Ücretsiz İndir</div>
                  <div className="font-semibold leading-tight text-[13px]">App Store</div>
                </div>
              </motion.a>
            </motion.div>
          </motion.div>
        </div>
      </Section>

      <Footer />

      {/* Scroll to top */}
      <ScrollToTop />
    </main>
  )
}

function ScrollToTop() {
  const [visible, setVisible] = useState(false)

  useEffect(() => {
    const onScroll = () => setVisible(window.scrollY > 400)
    window.addEventListener('scroll', onScroll)
    return () => window.removeEventListener('scroll', onScroll)
  }, [])

  return (
    <AnimatePresence>
      {visible && (
        <motion.button
          initial={{ opacity: 0, y: 10 }}
          animate={{ opacity: 1, y: 0 }}
          exit={{ opacity: 0, y: 10 }}
          onClick={() => window.scrollTo({ top: 0, behavior: 'smooth' })}
          className="fixed bottom-6 right-6 z-50 w-11 h-11 rounded-full bg-[#3d5c59] text-white shadow-lg hover:bg-[#2e4542] hover:scale-105 transition-all duration-300 flex items-center justify-center"
          aria-label="Yukarı çık"
        >
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
            <path d="M18 15l-6-6-6 6" />
          </svg>
        </motion.button>
      )}
    </AnimatePresence>
  )
}
