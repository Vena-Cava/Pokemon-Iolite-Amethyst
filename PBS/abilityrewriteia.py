import re

INPUT_FILE = "abilities_2_IA.txt"
OUTPUT_FILE = "ability_rows_ia.wiki"

with open(INPUT_FILE, "r", encoding="utf-8") as f:
    text = f.read()

blocks = re.split(r"#-+\s*", text)
abilities = []

for block in blocks:
    block = block.strip()
    if not block or not block.startswith("["):
        continue

    data = {}
    for line in block.splitlines()[1:]:
        if "=" in line:
            key, value = line.split("=", 1)
            data[key.strip()] = value.strip()

    if "Name" in data and "Description" in data:
        abilities.append(data)

rows = []

for i, ability in enumerate(abilities, start=1):
    index = f"ia{i}"
    name = ability["Name"]
    short = ability.get("ShortDesc", "").strip()
    desc = ability.get("Description", "").strip()

    if short and short != desc:
        row = f'''|-
| rowspan="2" | {index}
| rowspan="2" | {{{{a|{name}}}}}
| class="l" | {short}
{{{{Gentable|Fake|rowspan=2}}}}
|-
| class="l" | {desc}'''
    else:
        row = f'''|-
| {index}
| {{{{a|{name}}}}}
| class="l" | {desc}
{{{{Gentable|Fake}}}}'''

    rows.append(row)

with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
    f.write("\n".join(rows))

input(f"Done! Output saved to {OUTPUT_FILE}. Press Enter to close.")