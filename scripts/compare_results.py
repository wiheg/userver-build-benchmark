#!/usr/bin/env python3
import os, re, sys
from datetime import datetime


def parse_cba(path):
    if not os.path.exists(path): return None
    with open(path, "r", encoding="utf-8", errors="replace") as f:
        txt = f.read()

    get_sec = lambda pat: float(m.group(1)) if (m := re.search(pat, txt)) else None
    fe = get_sec(r"Parsing\s*\(frontend\):\s*([\d\.]+)\s*s")
    be = get_sec(r"Codegen\s*&\s*opts\s*\(backend\):\s*([\d\.]+)\s*s")

    # parse files
    files = {}
    m_parse = re.search(r"\*\*\*\* Files that took longest to parse \(compiler frontend\):\s*\n(.*?)(?=\n\*\*\*\*|\Z)",
                        txt, re.S)
    if m_parse:
        for line in m_parse.group(1).strip().splitlines()[:15]:
            if m := re.match(r"\s*(\d+)\s*ms:\s*(.+)", line):
                files[m.group(2).strip()] = int(m.group(1))

    # headers
    headers = []
    m_hdrs = re.search(r"\*\*\*\* Expensive headers:\s*\n(.*?)(?=\n\s*done|\Z)", txt, re.S)
    if m_hdrs:
        for ms, h, inc in re.findall(r"(\d+)\s*ms:\s*([^\n\(]+)(?:\(included\s+(\d+)\s+times)?", m_hdrs.group(1))[:6]:
            headers.append((int(ms), h.strip(), inc or "?"))

    # templates
    templates = []
    m_tmpl = re.search(r"\*\*\*\* Templates that took longest to instantiate:\s*\n(.*?)(?=\n\*\*\*\*|\Z)", txt, re.S)
    if m_tmpl:
        for line in m_tmpl.group(1).strip().splitlines()[:5]:
            if m := re.match(r"\s*(\d+)\s*ms:\s*(.+?)(?:\s*\(\d+\s*times|\Z)", line):
                templates.append((int(m.group(1)), m.group(2).strip()))

    return {"fe": fe, "be": be, "tot": round(fe + be, 2) if fe and be else None, "files": files, "headers": headers,
            "templates": templates}


def diff(b, h):
    if b is None or h is None: return "N/A"
    return f"{h - b:+.2f}s, {((h - b) / b) * 100:+.1f}%"


def main():
    b_file = sys.argv[1]
    h_file = sys.argv[2]
    out = sys.argv[3]

    b, h = parse_cba(b_file), parse_cba(h_file)
    if not b: sys.exit(f"error: {b_file} not found")

    now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    lines = [
        f"Время замера: {now}\n",
        "1. Сводные метрики:",
        f"  Frontend: {b['fe']:.1f}s -> {h['fe']:.1f}s ({diff(b['fe'], h['fe'])})",
        f"  Backend: {b['be']:.1f}s -> {h['be']:.1f}s ({diff(b['be'], h['be'])})",
        f"  Total: {b['tot']:.1f}s -> {h['tot']:.1f}s ({diff(b['tot'], h['tot'])})",
        "\n2. Время парсинга исходников (.cpp):"
    ]

    target_files = [
        "src/hello_postgres.cpp.o",
        "src/hello_grpc.cpp.o",
        "src/hello.cpp.o",
        "src/greeting_benchmark.cpp.o",
        "src/main.cpp.o"
    ]

    min_b = min(b["files"].values()) if b["files"] else 500
    min_h = min(h["files"].values()) if h and h["files"] else 500

    for k in target_files:
        b_ms = next((v for p, v in b["files"].items() if k in p), None)
        h_ms = next((v for p, v in (h["files"].items() if h else []) if k in p), None)
        fname = k.replace(".o", "")
        if b_ms and h_ms:
            d, pct = h_ms - b_ms, ((h_ms - b_ms) / b_ms) * 100
            lines.append(f"  {fname}: {b_ms} ms -> {h_ms} ms ({d:+d} ms, {pct:+.1f}%)")
        elif b_ms and not h_ms:
            lines.append(f"  {fname}: {b_ms} ms -> <{min_h} ms")
        elif not b_ms and h_ms:
            lines.append(f"  {fname}: <{min_b} ms -> {h_ms} ms")

    text = "\n".join(lines) + "\n"
    os.makedirs(os.path.dirname(out), exist_ok=True)
    with open(out, "w", encoding="utf-8") as f:
        f.write(text)
    print("\n" + text)


if __name__ == "__main__":
    main()

