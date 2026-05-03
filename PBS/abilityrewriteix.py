import re

START_NUMBER = 268
INPUT_FILE = "abilities_1_Gen_9_Pack.txt"
OUTPUT_FILE = "gen9_ability_rows.wiki"

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

for i, ability in enumerate(abilities, start=START_NUMBER):
    name = ability["Name"]
    short = ability.get("ShortDesc", "").strip()
    desc = ability.get("Description", "").strip()

    if short and short != desc:
        row = f'''|-
| rowspan="2" | {i}
| rowspan="2" | {{{{a|{name}}}}}
| class="l" | {short}
{{{{Gentable|IX|rowspan=2}}}}
|-
| class="l" | {desc}'''
    else:
        row = f'''|-
| {i}
| {{{{a|{name}}}}}
| class="l" | {desc}
{{{{Gentable|IX}}}}'''

    rows.append(row)

with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
    f.write("\n".join(rows))

input(f"Done! Output saved to {OUTPUT_FILE}. Press Enter to close.")