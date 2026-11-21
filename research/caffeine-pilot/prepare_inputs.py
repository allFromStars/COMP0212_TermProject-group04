"""Extract published summary values without inventing individual records."""
from pathlib import Path
from zipfile import ZipFile
import argparse
import csv
import hashlib
import json
import re
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parent
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--article', type=Path, default=ROOT / 'sources/PMC3603218.xml',
                    help='Original oral-coffee article XML.')
parser.add_argument('--supplement', type=Path, default=ROOT / 'sources/Data_Sheet_1.docx',
                    help='Original Lin Table S1 supplement DOCX.')
args = parser.parse_args()
for source in (args.article, args.supplement):
    if not source.is_file():
        parser.error(f'Missing source: {source}. Run retrieve_literature.py or pass --article and --supplement explicitly. The included CSVs are sufficient for MATLAB.')
DATA = ROOT / "data"
DATA.mkdir(exist_ok=True)

def write_csv(name, rows):
    with (DATA / name).open("w", newline="") as stream:
        writer = csv.DictWriter(stream, fieldnames=list(rows[0]))
        writer.writeheader()
        writer.writerows(rows)

article = args.article
tree = ET.parse(article)
table = tree.find(".//table-wrap[@id='tab1']/table/tbody")
spec = [("cmax", "mg/L"), ("auc_0_12", "mg*h/L"),
        ("auc_inf", "mg*h/L"), ("tmax", "h"), ("half_life", "h")]
rows = []
for tr, (metric, unit) in zip(table.findall("tr"), spec):
    cell = tr.findall("td")[2]
    value = "".join(cell.itertext()).strip()
    mean, sd = [float(x.strip()) for x in value.split("±")]
    rows.append(dict(metric=metric, mean=mean, sd=sd, unit=unit, n=11,
                     source_field="Table 1 / Oral coffee consumption / " + metric,
                     source_doi="10.1155/2013/147238", data_level="participant_summary"))
write_csv("teekachunhatean2013_oral_summary.csv", rows)
write_csv("teekachunhatean2013_protocol.csv", [dict(
    dose_mg=96.34, dose_sd_mg=1.39, assayed_servings=6,
    consumption_max_minutes=1, plasma_lloq_mg_L=0.1,
    source_doi="10.1155/2013/147238",
    source_field="Results paragraph 1; Methods 2.4 and 2.8")])

supplement = args.supplement
ns = {"w": "http://schemas.openxmlformats.org/wordprocessingml/2006/main"}
with ZipFile(supplement) as archive:
    document = ET.fromstring(archive.read("word/document.xml"))
table = document.find(".//w:tbl", ns)
conditions = ["placebo", "caffeine", "acute_caffeine_deprivation"]
saliva = []
for row in table.findall("w:tr", ns):
    cells = ["".join(t.text or "" for t in c.findall(".//w:t", ns))
             for c in row.findall("w:tc", ns)]
    if not cells or not re.fullmatch(r"Sample\s+\d+", cells[0].strip()):
        continue
    sample = int(re.search(r"\d+", cells[0]).group())
    assert len(cells) == 7, cells
    for j, text in enumerate(cells[1:]):
        mean, sd = [float(x.strip()) for x in text.split("±")]
        saliva.append(dict(sample_id=sample, condition=conditions[j // 2],
                           analyte=["caffeine", "paraxanthine"][j % 2],
                           mean_mg_L=mean, sd_mg_L=sd, time_h="",
                           source_field=f"Table S1 / Sample {sample} / {conditions[j // 2]} / {['CA', 'PX'][j % 2]}",
                           source_doi="10.3389/fnut.2021.787225",
                           data_level="group_mean_and_sd", timing_status="Exact internal times not in Table S1"))
assert len(saliva) == 66, len(saliva)
write_csv("lin2022_saliva_summary.csv", saliva)

manifest = {
    "oral_summary": {"source": article.name, "source_link": "https://pmc.ncbi.nlm.nih.gov/articles/PMC3603218/", "sha256": hashlib.sha256(article.read_bytes()).hexdigest(),
                     "rows": len(rows), "unit_conversion": "1 ug/mL = 1 mg/L; numerical values unchanged"},
    "saliva_summary": {"source": supplement.name, "sha256": hashlib.sha256(supplement.read_bytes()).hexdigest(),
                       "rows": len(saliva), "unit_conversion": "1 ug/mL = 1 mg/L; numerical values unchanged",
                       "source_link": "https://pmc.ncbi.nlm.nih.gov/articles/PMC8849224/#SM1",
                       "timing": "Figure 1 gives withdrawal endpoints 24 and 43 h after last dose. Internal sample times are intentionally blank.",
                       "sample_size": "20 enrolled; one caffeine condition excluded for noncompliance; per-cell n not supplied in Table S1"},
    "scope": "This manifest describes summary extraction only. No raw participant records or independent validation are supplied. The pilot separately fits an approximate digitized group-mean curve."
}
(DATA / "input_manifest.json").write_text(json.dumps(manifest, indent=2))
print(json.dumps({"oral_summary_rows": len(rows), "saliva_summary_rows": len(saliva), "exact_saliva_times_available": False}))
