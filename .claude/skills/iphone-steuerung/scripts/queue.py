#!/usr/bin/env python3
"""Verwaltet die iPhone-Befehlswarteschlange für Route A/B des Skills iphone-steuerung.

Zweck: Befehle landen nur dann in der Queue, wenn der genannte Kurzbefehl auf dem
Telefon des Nutzers wirklich existiert. Ein Tippfehler im Namen scheitert am Gerät
still – das Skript fängt das vorher ab.

Alle Dateien liegen neben dem Skill unter state/ und sind reiner Klartext:
  state/capabilities.json  – welche CL_*-Kurzbefehle das Telefon kennt
  state/pending.json       – der Auftrag, den das Telefon abholt
  state/log.jsonl          – was abgesetzt wurde (Nachvollziehbarkeit)

Beispiele:
  queue.py status
  queue.py cap add CL_Timer --beschreibung "Timer, Eingabe = Minuten" --stufe 1
  queue.py add CL_Timer --input 10 --note "Timer 10 Minuten"
  queue.py publish
  queue.py clear
"""

import argparse
import json
import os
import secrets
import sys
from datetime import datetime, timedelta, timezone
from pathlib import Path

STATE = Path(__file__).resolve().parent.parent / "state"
CAPS = STATE / "capabilities.json"
PENDING = STATE / "pending.json"
LOG = STATE / "log.jsonl"
DEFAULT_TTL_MIN = 60


def now():
    return datetime.now(timezone.utc)


def iso(dt):
    return dt.replace(microsecond=0).isoformat().replace("+00:00", "Z")


def load(path, fallback):
    if not path.exists():
        return fallback
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as e:
        sys.exit(f"{path} ist kein gültiges JSON ({e}). Bitte prüfen oder löschen.")


def save(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def caps():
    return load(CAPS, {"version": 1, "target": None, "capabilities": []})


def log(entry):
    LOG.parent.mkdir(parents=True, exist_ok=True)
    with LOG.open("a", encoding="utf-8") as f:
        f.write(json.dumps({"ts": iso(now()), **entry}, ensure_ascii=False) + "\n")


# --- Befehle ---------------------------------------------------------------

def cmd_status(args):
    c = caps()
    print(f"Ablageort: {c.get('target') or '— nicht gesetzt (queue.py target …) —'}")
    names = c.get("capabilities", [])
    if not names:
        print("\nFähigkeiten: keine eingetragen.")
        print("Das Telefon kann noch nichts. Leg mit dem Nutzer Kurzbefehle an")
        print("(references/route-a-shortcuts-queue.md) und trag sie dann mit")
        print("'queue.py cap add CL_Name' ein.")
    else:
        print(f"\nFähigkeiten ({len(names)}):")
        for cap in names:
            print(f"  {cap['shortcut']:<18} Stufe {cap.get('stufe', '?')}  {cap.get('beschreibung', '')}")

    p = load(PENDING, None)
    if not p or not p.get("commands"):
        print("\nWarteschlange: leer.")
        return
    exp = p.get("expires_at", "")
    stale = ""
    try:
        if datetime.fromisoformat(exp.replace("Z", "+00:00")) < now():
            stale = "  ← ABGELAUFEN, das Telefon führt das nicht mehr aus"
    except ValueError:
        pass
    print(f"\nWarteschlange: {len(p['commands'])} Befehl(e), Nonce {p.get('nonce')}, gültig bis {exp}{stale}")
    for cmdx in p["commands"]:
        print(f"  {cmdx['id']}: {cmdx['shortcut']}  input={cmdx.get('input')!r}  {cmdx.get('note', '')}")


def cmd_target(args):
    c = caps()
    c["target"] = args.url
    save(CAPS, c)
    print(f"Ablageort gesetzt: {args.url}")


def cmd_cap(args):
    c = caps()
    existing = {x["shortcut"] for x in c["capabilities"]}
    if args.cap_action == "add":
        if args.shortcut in existing:
            sys.exit(f"{args.shortcut} ist bereits eingetragen.")
        c["capabilities"].append({
            "shortcut": args.shortcut,
            "beschreibung": args.beschreibung or "",
            "stufe": args.stufe,
        })
        c["capabilities"].sort(key=lambda x: x["shortcut"])
        save(CAPS, c)
        print(f"Eingetragen: {args.shortcut} (Stufe {args.stufe})")
    elif args.cap_action == "remove":
        c["capabilities"] = [x for x in c["capabilities"] if x["shortcut"] != args.shortcut]
        save(CAPS, c)
        print(f"Entfernt: {args.shortcut}")


def cmd_add(args):
    c = caps()
    known = {x["shortcut"]: x for x in c["capabilities"]}
    if args.shortcut not in known:
        print(f"'{args.shortcut}' steht nicht im Fähigkeitenkatalog.", file=sys.stderr)
        if known:
            print("Bekannt sind: " + ", ".join(sorted(known)), file=sys.stderr)
        print("Entweder Name korrigieren, oder den Kurzbefehl mit dem Nutzer am Telefon"
              "\nanlegen und dann 'queue.py cap add' aufrufen. Mit --force trotzdem"
              "\nabsetzen (schlägt am Gerät still fehl, wenn der Name nicht stimmt).",
              file=sys.stderr)
        if not args.force:
            sys.exit(1)

    stufe = known.get(args.shortcut, {}).get("stufe")
    if stufe == 3:
        sys.exit(f"{args.shortcut} ist als Stufe 3 eingetragen – das führt dieser Skill nicht"
                 "\nautomatisch aus. Erklär dem Nutzer den Weg, er macht es am Gerät.")

    p = load(PENDING, None)
    fresh = True
    if p and p.get("commands"):
        try:
            fresh = datetime.fromisoformat(p["expires_at"].replace("Z", "+00:00")) < now()
        except (KeyError, ValueError):
            fresh = True
    if fresh or not p:
        p = {
            "version": 1,
            "issued_at": iso(now()),
            "expires_at": iso(now() + timedelta(minutes=args.ttl)),
            "nonce": secrets.token_hex(2),
            "commands": [],
        }

    cmd_id = f"c{len(p['commands']) + 1}"
    p["commands"].append({
        "id": cmd_id,
        "shortcut": args.shortcut,
        "input": args.input or "",
        "note": args.note or "",
    })
    p["expires_at"] = iso(now() + timedelta(minutes=args.ttl))
    save(PENDING, p)
    log({"event": "add", "shortcut": args.shortcut, "input": args.input, "nonce": p["nonce"]})

    print(f"Abgesetzt: {cmd_id} {args.shortcut} input={args.input!r}")
    if stufe and stufe >= 2:
        print("Stufe 2 – wirkt nach außen. Zeig dem Nutzer Inhalt und Empfänger,"
              " bevor er auslöst.")
    print(f"Nonce {p['nonce']}, gültig bis {p['expires_at']}.")
    print("Noch nicht veröffentlicht – 'queue.py publish' zeigt den Weg zum Telefon.")


def cmd_publish(args):
    p = load(PENDING, None)
    if not p or not p.get("commands"):
        sys.exit("Warteschlange ist leer – nichts zu veröffentlichen.")
    target = caps().get("target")
    print(f"Datei: {PENDING}")
    print(f"Inhalt ({len(p['commands'])} Befehl(e), Nonce {p['nonce']}):\n")
    print(json.dumps(p, indent=2, ensure_ascii=False))
    print("\nDiese Datei muss jetzt an den Ablageort, den das iPhone liest.")
    if target:
        print(f"Eingetragener Ablageort: {target}")
    print("""
Je nach Einrichtung:
  Gist   : gh gist edit <ID> -a """ + str(PENDING) + """      (oder per API-PATCH)
  Repo   : Datei committen und pushen, dann raw-URL mit ?t=<zeitstempel> lesen lassen
  iCloud : cp nach ~/Library/Mobile\\ Documents/com~apple~CloudDocs/Claude/pending.json

Danach dem Nutzer sagen, dass er auslösen soll (\"Hey Siri, Claude\") – und dass
du das Ergebnis ohne Rückkanal nicht selbst siehst.""")
    log({"event": "publish", "nonce": p["nonce"], "count": len(p["commands"])})


def cmd_clear(args):
    if PENDING.exists():
        p = load(PENDING, {})
        PENDING.unlink()
        log({"event": "clear", "nonce": p.get("nonce")})
        print("Warteschlange geleert.")
    else:
        print("Warteschlange war schon leer.")


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="action", required=True)

    sub.add_parser("status", help="Ablageort, Fähigkeiten und offene Befehle zeigen").set_defaults(func=cmd_status)

    t = sub.add_parser("target", help="URL/Pfad setzen, von dem das iPhone liest")
    t.add_argument("url")
    t.set_defaults(func=cmd_target)

    c = sub.add_parser("cap", help="Fähigkeitenkatalog pflegen")
    c.add_argument("cap_action", choices=["add", "remove"])
    c.add_argument("shortcut")
    c.add_argument("--beschreibung", default="")
    c.add_argument("--stufe", type=int, default=1, choices=[0, 1, 2, 3],
                   help="Freigabestufe laut SKILL.md (Standard 1)")
    c.set_defaults(func=cmd_cap)

    a = sub.add_parser("add", help="Befehl in die Warteschlange legen")
    a.add_argument("shortcut")
    a.add_argument("--input", default="")
    a.add_argument("--note", default="")
    a.add_argument("--ttl", type=int, default=DEFAULT_TTL_MIN, help="Gültigkeit in Minuten")
    a.add_argument("--force", action="store_true", help="auch unbekannte Kurzbefehlsnamen absetzen")
    a.set_defaults(func=cmd_add)

    sub.add_parser("publish", help="Queue anzeigen und Veröffentlichungsweg nennen").set_defaults(func=cmd_publish)
    sub.add_parser("clear", help="Warteschlange leeren").set_defaults(func=cmd_clear)

    args = ap.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
