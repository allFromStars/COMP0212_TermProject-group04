"""Record manual marker readings from the inspected original CC BY figure.

Coordinates are approximate marker centers in the native 600 x 376 image.
The 3-pixel envelope is an extraction sensitivity range, not an assay SD.
"""
from pathlib import Path
import argparse
import csv
import hashlib
import json
from datetime import datetime, timezone
ROOT = Path(__file__).resolve().parent
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--figure', type=Path,
                    default=ROOT / 'sources/ISRN.PHARMACOLOGY2013-147238.002.jpg',
                    help='Original unmodified 600 x 376 Figure 2 image.')
args = parser.parse_args()
image = args.figure
if not image.is_file():
    parser.error(f'Missing figure: {image}. Run retrieve_literature.py or pass --figure. The digitized CSV is already included.')
(ROOT / 'data').mkdir(exist_ok=True)
# Known protocol times identify markers; y readings are independently recorded.
minutes = [10, 20, 30, 40, 60, 90, 120, 240, 480, 720]
y_center = [160, 91, 83, 84, 95, 112, 119, 149, 188, 208]
held_out = {20, 40, 90, 480}
with (ROOT / "data/teekachunhatean2013_cc_digitized.csv").open("w", newline="") as f:
    w = csv.writer(f)
    w.writerow(["time_h", "mean_mg_L", "pixel_y", "extraction_envelope_mg_L",
                "split", "source_field", "data_level"])
    for minute, y in zip(minutes, y_center):
        w.writerow([minute/60, (237-y)/69, y, 3/69,
                    "holdout" if minute in held_out else "calibration",
                    "Figure 2 / CC open triangles", "digitized_group_mean_n11"])
manifest = {"figure": image.name, "sha256": hashlib.sha256(image.read_bytes()).hexdigest(),
            "source_doi": "10.1155/2013/147238", "license": "CC BY",
            "access_utc": datetime.now(timezone.utc).isoformat(),
            "image_size_px": [600, 376], "zero_axis_y_px": 237,
            "three_mg_L_axis_y_px": 30, "pixels_per_mg_L": 69,
            "method": "Manual inspection of original image; protocol times used, not inferred x values",
            "extraction_envelope_pixels": 3,
            "envelope_distribution": "No empirical distribution; uniform perturbations are sensitivity scenarios only",
            "split_status": "Fixed before optimization, but not prospectively registered or blinded",
            "limitations": "Approximate group means, not participant records; marker overlap and line width; second-reader check needed",
            "figure_package_url": "https://www.ebi.ac.uk/europepmc/webservices/rest/PMC3603218/supplementaryFiles"}
(ROOT / "data/digitization_manifest.json").write_text(json.dumps(manifest, indent=2))
print("Saved 10 approximate group-mean points: 6 calibration and 4 holdout.")
