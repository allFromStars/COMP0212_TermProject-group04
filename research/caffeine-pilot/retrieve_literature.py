"""Bounded, reproducible Europe PMC retrieval; no model calculations."""
from pathlib import Path
from urllib.parse import urlencode
from datetime import datetime, timezone
import hashlib
import json
import subprocess
import zipfile
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parent
RAW = ROOT / "sources"
BASE = "https://www.ebi.ac.uk/europepmc/webservices/rest"

def main():
    RAW.mkdir(parents=True, exist_ok=True)
    calls = []
    query = 'caffeine AND (pharmacokinetics OR "concentration time") AND (oral OR repeated)'
    jobs = [("search.json", BASE + "/search?" + urlencode({"query": query, "format": "json", "pageSize": 20, "resultType": "core"}))]
    for pmcid in ["PMC3603218", "PMC8849224", "PMC4898153", "PMC8914174"]:
        jobs.append((pmcid + ".xml", BASE + "/" + pmcid + "/fullTextXML"))
    for pmcid in ["PMC3603218", "PMC8849224", "PMC4898153"]:
        jobs.append((pmcid + "_supplements.zip", BASE + "/" + pmcid + "/supplementaryFiles"))
    for pmid in ["19125908", "6832208", "2401126"]:
        jobs.append(("MED_" + pmid + ".json", BASE + "/search?" + urlencode({"query": "EXT_ID:" + pmid + " AND SRC:MED", "format": "json", "pageSize": 1, "resultType": "core"})))
    for name, url in jobs:
        dest = RAW / name
        result = subprocess.run(["curl", "--location", "--silent", "--show-error", "--max-time", "60", "--output", str(dest), "--write-out", "%{http_code}", url], capture_output=True, text=True)
        record = {"url": url, "file": name, "http_status": result.stdout, "curl_returncode": result.returncode,
                  "access_utc": datetime.now(timezone.utc).isoformat()}
        if dest.exists():
            payload = dest.read_bytes()
            record["sha256"] = hashlib.sha256(payload).hexdigest()
            if name.endswith(".xml"):
                try:
                    body = ET.fromstring(payload).find('.//body')
                    record['has_article_body'] = body is not None
                    if body is not None:
                        paragraphs = [' '.join(''.join(p.itertext()).split()) for p in body.iter('p')]
                        dest.with_suffix('.txt').write_text('\n\n'.join(paragraphs), encoding='utf-8')
                except ET.ParseError as error:
                    record['xml_error'] = str(error)
            if name.endswith(".json"):
                try:
                    data = json.loads(payload)
                    record["hitCount"] = data.get("hitCount")
                    record["retrieved"] = len(data.get("resultList", {}).get("result", []))
                    record["errCode"] = data.get("errCode")
                except ValueError:
                    record["error"] = "Not JSON"
            if name.endswith(".zip"):
                record["valid_zip"] = zipfile.is_zipfile(dest)
                if record["valid_zip"]:
                    with zipfile.ZipFile(dest) as archive:
                        record["members"] = archive.namelist()
                        for member in archive.namelist():
                            if member.lower().endswith((".docx", ".csv", ".xlsx", ".txt", ".jpg")):
                                target = RAW / Path(member).name
                                target.write_bytes(archive.read(member))
        calls.append(record)
        (RAW / "retrieval_manifest.json").write_text(json.dumps(calls, indent=2))
        print(json.dumps(record), flush=True)

if __name__ == "__main__":
    main()
