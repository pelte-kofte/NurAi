// lib/quran.ts

import quranData from "@/assets/quran/final/quran_ar_tr.json";

export type Ayah = {
  surah: number;
  ayah: number;
  ar: string;
  tr_readable: string;
};

const AYAT = quranData as Ayah[];

export const TOTAL_AYAH_COUNT = AYAT.length;

export function getAyahByRef(surah: number, ayah: number): Ayah | null {
  return AYAT.find(a => a.surah === surah && a.ayah === ayah) ?? null;
}

export function getSurah(surah: number): Ayah[] {
  return AYAT.filter(a => a.surah === surah);
}

export function getRandomAyah(): Ayah {
  return AYAT[Math.floor(Math.random() * AYAT.length)];
}

export function getAyahOfTheDay(date: Date = new Date()): Ayah {
  const key = date.toISOString().slice(0, 10);
  let hash = 0;

  for (let i = 0; i < key.length; i++) {
    hash = (hash << 5) - hash + key.charCodeAt(i);
    hash |= 0;
  }

  return AYAT[Math.abs(hash) % AYAT.length];
}
