// Edge Function "tech-news": mengambil berita teknologi terbaru (RSS Antara Tekno & CNN Indonesia Teknologi),
// lalu mengembalikannya sebagai JSON untuk kartu "Berita TI" di halaman Belajar.
// Publik (tanpa login): hanya membaca berita umum, tidak menyentuh database.

const FEEDS = [
  { source: "ANTARA", url: "https://www.antaranews.com/rss/tekno.xml" },
  { source: "CNN Indonesia", url: "https://www.cnnindonesia.com/teknologi/rss" },
];

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "GET, OPTIONS",
};

type Item = { title: string; link: string; image: string | null; source: string; published: string | null; summary: string };

function decode(s: string): string {
  return s
    .replace(/<!\[CDATA\[([\s\S]*?)\]\]>/g, "$1")
    .replace(/&amp;/g, "&").replace(/&lt;/g, "<").replace(/&gt;/g, ">")
    .replace(/&quot;/g, '"').replace(/&#39;|&apos;/g, "'")
    .replace(/&#(\d+);/g, (_, n) => String.fromCharCode(Number(n)))
    .trim();
}

function tag(xml: string, name: string): string {
  const m = xml.match(new RegExp(`<${name}[^>]*>([\\s\\S]*?)</${name}>`, "i"));
  return m ? decode(m[1]) : "";
}

function image(xml: string): string | null {
  const m = xml.match(/<enclosure[^>]*url="([^"]+)"/i) ??
    xml.match(/<media:content[^>]*url="([^"]+)"/i) ??
    xml.match(/<media:thumbnail[^>]*url="([^"]+)"/i) ??
    decode(xml).match(/<img[^>]*src="([^"]+)"/i);
  return m ? decode(m[1]) : null;
}

async function readFeed(f: { source: string; url: string }): Promise<Item[]> {
  try {
    const r = await fetch(f.url, { headers: { "User-Agent": "Mozilla/5.0 (SinauNews)" }, signal: AbortSignal.timeout(8000) });
    if (!r.ok) return [];
    const xml = await r.text();
    return [...xml.matchAll(/<item\b[\s\S]*?<\/item>/gi)].map(([it]) => {
      const date = new Date(tag(it, "pubDate"));
      return {
        title: tag(it, "title"),
        link: tag(it, "link"),
        image: image(it),
        source: f.source,
        published: isNaN(date.getTime()) ? null : date.toISOString(),
        summary: tag(it, "description").replace(/<[^>]+>/g, " ").replace(/\s+/g, " ").trim().slice(0, 220),
      };
    }).filter((i) => i.title && i.link.startsWith("http"));
  } catch (_) {
    return [];
  }
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });
  const all = (await Promise.all(FEEDS.map(readFeed))).flat();
  const seen = new Set<string>();
  const items = all
    .filter((i) => !seen.has(i.title) && seen.add(i.title))
    .sort((a, b) => (b.published ?? "").localeCompare(a.published ?? ""))
    .slice(0, 40);
  return new Response(JSON.stringify({ updated: new Date().toISOString(), items }), {
    headers: { ...CORS, "Content-Type": "application/json; charset=utf-8", "Cache-Control": "public, max-age=1800" },
  });
});
