import re

GEN_RANGES = [
    (1, 76, "III"),
    (77, 123, "IV"),
    (124, 164, "V"),
    (165, 191, "VI"),
    (192, 233, "VII"),
    (234, 267, "VIII"),
    (268, 318, "IX"),
    (319, 999, "Fake")
]

def get_gen(num):
    for start, end, gen in GEN_RANGES:
        if start <= num <= end:
            return gen
    return "IX"

with open("abilities.txt", "r", encoding="utf-8") as f:
    text = f.read()

blocks = re.split(r"#-+\s*", text)
abilities = []

for block in blocks:
    block = block.strip()
    if not block or not block.startswith("["):
        continue

    section_match = re.match(r"\[([^\]]+)\]", block)
    if not section_match:
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
    name = ability["Name"]
    short = ability.get("ShortDesc", "").strip()
    desc = ability.get("Description", "").strip()
    gen = get_gen(i)

    if short and short != desc:
        row = f'''|-
| rowspan="2" | {i}
| rowspan="2" | {{{{a|{name}}}}}
| class="l" | {short}
{{{{Gentable|{gen}|rowspan=2}}}}
|-
| class="l" | {desc}'''
    else:
        row = f'''|-
| {i}
| {{{{a|{name}}}}}
| class="l" | {desc}
{{{{Gentable|{gen}}}}}'''

    rows.append(row)

with open("ability_rows.wiki", "w", encoding="utf-8") as f:
    f.write("\n".join(rows))

input("Done! Output saved to ability_rows.wiki. Press Enter to close.")