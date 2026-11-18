"""Perbarui daftar unduhan APK di README.md secara otomatis.

Membaca folder `apk sinau/Versi X/`, mengambil APK *universal* di tiap folder, lalu menulis tabel
(versi, tanggal & jam update, ukuran, link download) di antara penanda
<!-- APK-LIST:START --> dan <!-- APK-LIST:END --> di README.md.

Tanggal & jam update = waktu commit yang pertama kali menaikkan versi di pubspec.yaml
(mis. "version: 1.2." untuk Versi 1.2.11,26). Versi yang belum di-commit memakai waktu sekarang.

Dijalankan otomatis oleh hook pre-commit (.githooks/pre-commit), atau manual:
    python scripts/update_readme_apk.py
"""
import re
import subprocess
from datetime import datetime, timedelta, timezone
from pathlib import Path
from urllib.parse import quote

ROOT = Path(__file__).resolve().parent.parent
APK_DIR = ROOT / 'apk sinau'
README = ROOT / 'README.md'
START, END = '<!-- APK-LIST:START -->', '<!-- APK-LIST:END -->'
WIB = timezone(timedelta(hours=7))
BULAN = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des']


def git(*args: str) -> str:
    try:
        return subprocess.run(['git', *args], cwd=ROOT, capture_output=True, text=True, encoding='utf-8').stdout.strip()
    except OSError:
        return ''


def repo_url() -> str:
    url = git('remote', 'get-url', 'origin') or 'https://github.com/zidney953-commits/Sinau.git'
    m = re.search(r'github\.com[:/](.+?)(?:\.git)?$', url)
    return f'https://github.com/{m.group(1)}' if m else url.removesuffix('.git')


def released_at(version: str) -> datetime:
    """Waktu commit pertama yang memuat 'version: <mayor>.<minor>.' di pubspec.yaml."""
    major_minor = '.'.join(version.split('.')[:2]) + '.'
    out = git('log', '-S', f'version: {major_minor}', '--format=%cI', '--reverse', '--', 'pubspec.yaml')
    if out:
        return datetime.fromisoformat(out.splitlines()[0]).astimezone(WIB)
    return datetime.now(WIB)


def vkey(v: str):
    return [int(x) for x in re.findall(r'\d+', v)]


def build_table() -> str:
    rows = []
    for folder in APK_DIR.glob('Versi *'):
        apks = sorted(folder.glob('*universal*.apk'))
        if not folder.is_dir() or not apks:
            continue
        version = folder.name.removeprefix('Versi ').strip()
        rows.append((version, apks[0], released_at(version)))
    if not rows:
        return '_Belum ada APK._'
    rows.sort(key=lambda r: vkey(r[0]), reverse=True)
    base = repo_url()
    lines = [
        '| Versi | Tanggal & jam update | Ukuran | Download |',
        '|---|---|---|---|',
    ]
    for i, (version, apk, t) in enumerate(rows):
        rel = apk.relative_to(ROOT).as_posix()
        link = f'{base}/raw/main/{quote(rel)}'
        size = apk.stat().st_size / 1024 / 1024
        tag = ' 🆕 **Terbaru**' if i == 0 else ''
        when = f'{t.day} {BULAN[t.month - 1]} {t.year}, {t:%H.%M} WIB'
        lines.append(f'| **{version}**{tag} | {when} | {size:.1f} MB | [⬇️ Download APK]({link}) |')
    latest = rows[0]
    latest_link = f'{base}/raw/main/{quote(latest[1].relative_to(ROOT).as_posix())}'
    return '\n'.join([
        f'**👉 [Download Sinau versi terbaru ({latest[0]})]({latest_link})** — APK universal, jalan di semua HP Android.',
        '',
        *lines,
        '',
        '_Tabel ini diperbarui otomatis setiap commit (lihat `scripts/update_readme_apk.py`)._',
    ])


def main() -> None:
    text = README.read_text(encoding='utf-8')
    if START not in text or END not in text:
        raise SystemExit(f'Penanda {START} / {END} tidak ada di README.md')
    head, rest = text.split(START, 1)
    _, tail = rest.split(END, 1)
    new = f'{head}{START}\n{build_table()}\n{END}{tail}'
    if new != text:
        README.write_text(new, encoding='utf-8', newline='\n')
        print('README.md: daftar APK diperbarui')
    else:
        print('README.md: daftar APK sudah terbaru')


if __name__ == '__main__':
    main()
