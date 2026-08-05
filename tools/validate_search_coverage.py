import json, re
from collections import defaultdict
from datetime import datetime, timezone
from pathlib import Path
ROOT = Path(__file__).resolve().parent.parent
EXPORT = ROOT / "tools/data/firestore/india_colleges_firestore_full.json"
OUT_JSON = ROOT / "tools/data/search_validation_evidence.json"
OUT_COVERAGE = ROOT / "SEARCH_COVERAGE_REPORT.md"
CATEGORIES = ["Engineering","Medical","MBA","Pharmacy","Nursing","Law","Commerce","Arts","Science","General","Polytechnic","Agriculture","Architecture","Fashion"]
POPULAR = [("Mumbai","Maharashtra"),("Delhi","Delhi"),("Bangalore","Karnataka"),("Pune","Maharashtra"),("Hyderabad","Telangana"),("Chennai","Tamil Nadu"),("Kolkata","West Bengal"),("Ahmedabad","Gujarat")]
STATE_ALIASES = {"chhatisgarh":"chhattisgarh","chhattisgarh":"chhattisgarh","uttrakhand":"uttarakhand","uttarakhand":"uttarakhand","orissa":"odisha","pondicherry":"puducherry","nct of delhi":"delhi","delhi nct":"delhi"}
CITY_KEYS = {"bangalore":{"bangalore","bengaluru"},"bengaluru":{"bangalore","bengaluru"},"bombay":{"mumbai","bombay"},"mumbai":{"mumbai","bombay"},"madras":{"chennai","madras"},"chennai":{"chennai","madras"},"calcutta":{"kolkata","calcutta"},"kolkata":{"kolkata","calcutta"},"poona":{"pune","poona"},"pune":{"pune","poona"},"delhi":{"delhi","new delhi"},"new delhi":{"delhi","new delhi"},"gurgaon":{"gurgaon","gurugram"},"gurugram":{"gurgaon","gurugram"}}
def norm(s):
    return re.sub(r"\s+"," ",(s or "").strip().lower())
def norm_state(s):
    return STATE_ALIASES.get(norm(s), norm(s))
def keys(city):
    n = norm(city); return CITY_KEYS.get(n,{n}) if n else set()
def city_match_row(cl, dl, city_filter):
    ks = keys(city_filter)
    if not ks: return True
    return any(k in cl or k in dl for k in ks)
def city_eq_row(cl, city_filter):
    return cl in keys(city_filter)
rows = [r for r in json.loads(EXPORT.read_text(encoding="utf-8")) if r.get("isActive", True)]
pre = [(norm_state(r.get("state") or ""), norm(r.get("cityLower") or r.get("city") or ""), norm(r.get("district") or ""), r.get("category") or "", norm(r.get("type") or ""), r.get("city") or "") for r in rows]
rc1 = []
for city, state in POPULAR:
    ns = norm_state(state); eq = uni = 0
    for st, cl, dl, cat, tp, _ in pre:
        if st != ns: continue
        if city_eq_row(cl, city): eq += 1
        if city_match_row(cl, dl, city): uni += 1
    rc1.append({"city":city,"state":state,"legacy_equality_count":eq,"unified_contains_count":uni,"delta":uni-eq,"pass":uni>=eq and uni>0})
cat_counts = {c: sum(1 for *_, cat, __, ___ in pre if cat==c) for c in CATEGORIES}
states = sorted({st for st,_,_,_,_,_ in pre if st})
state_counts = {s: sum(1 for st,_,_,_,_,_ in pre if st==s) for s in states}
city_index = defaultdict(int); city_sample = {}
for st, cl, dl, cat, tp, disp in pre:
    ct = norm(disp)
    if st and ct:
        city_index[(st, ct)] += 1
        city_sample.setdefault((st, ct), (cl, dl, disp))
city_failures = []
for (st, ct), n in city_index.items():
    cl, dl, disp = city_sample[(st, ct)]
    if not city_match_row(cl, dl, disp.strip() or ct):
        city_failures.append({"state":st,"city":disp,"raw_rows":n})
ownership_counts = {t: sum(1 for *_, tp, __ in pre if tp==t) for t in ["private","government","autonomous","deemed"]}
popular_pass = all(r["pass"] for r in rc1)
cat_pass = all(cat_counts.get(c,0)>0 for c in ["Engineering","Medical","Nursing"])
city_pass = len(city_failures)==0
evidence = {"generated_at":datetime.now(timezone.utc).isoformat(),"source":str(EXPORT),"total_active":len(rows),"states":len(states),"distinct_state_city_pairs":len(city_index),"root_cause_rc1_popular_cities":rc1,"category_counts":cat_counts,"state_counts":state_counts,"ownership_counts":ownership_counts,"city_zero_match_failure_count":len(city_failures),"city_zero_match_failures":city_failures[:50],"gates":{"popular_cities_nonempty":popular_pass,"mandatory_categories_nonempty":cat_pass,"no_city_zero_unified_failures":city_pass,"all_pass":popular_pass and cat_pass and city_pass}}
OUT_JSON.write_text(json.dumps(evidence, indent=2), encoding="utf-8")
lines = ["# Search Coverage Report","",f"Generated: {evidence['generated_at']}",f"Source: `{EXPORT}`","",f"Active colleges: **{len(rows)}**",f"States: **{len(states)}**",f"Distinct state+city pairs: **{len(city_index)}**","","## RC-1 legacy equality vs unified contains (popular deep links)","","| City | State | Legacy (=) | Unified (contains) | Delta |","|------|-------|--------------|--------------------|-------|"]
for r in rc1:
    lines.append("| {city} | {state} | {legacy} | {uni} | +{delta} |".format(city=r["city"], state=r["state"], legacy=r["legacy_equality_count"], uni=r["unified_contains_count"], delta=r["delta"]))
lines += ["","","## Category totals",""]
for c in CATEGORIES: lines.append(f"- {c}: {cat_counts.get(c,0)}")
lines += ["","","## Ownership (type) totals",""]
for k,v in ownership_counts.items(): lines.append(f"- {k}: {v}")
overall = "PASS" if evidence["gates"]["all_pass"] else "FAIL"
lines += ["","","## Gates","",f"- Popular cities: **{'PASS' if popular_pass else 'FAIL'}**",f"- Engineering/Medical/Nursing: **{'PASS' if cat_pass else 'FAIL'}**",f"- City self-match failures: **{len(city_failures)}** ({'PASS' if city_pass else 'FAIL'})","",f"**Overall: {overall}**"]
OUT_COVERAGE.write_text("\n".join(lines)+"\n", encoding="utf-8")
print("overall", overall)
for r in rc1: print(r)
