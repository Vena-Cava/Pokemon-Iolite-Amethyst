#!/usr/bin/env python3
"""
PBS Editor MVP for Pokemon Essentials-style PBS files.

External, generic editor:
- Choose a PBS folder
- Opens any .txt PBS file
- Parses [SECTION] blocks with Key = Value lines
- Lets you search, edit, add/delete keys, add/duplicate/delete records
- Saves back to PBS text format with automatic .bak backup

This is intentionally generic, so it works with custom/plugin PBS files as well as
standard Essentials files. It does not compile PBS; use Essentials' compiler after saving.
"""
from __future__ import annotations

import os
import shutil
import tkinter as tk
from tkinter import filedialog, messagebox, simpledialog
from tkinter import ttk
from dataclasses import dataclass, field
from typing import Dict, List, Optional

KNOWN_SCHEMAS: Dict[str, List[str]] = {
    "abilities": ["Name", "ShortDesc", "Description", "Flags"],
    "types": ["Name", "IconPosition", "IsSpecialType", "IsPseudoType", "Weaknesses", "Resistances", "Immunities", "Flags"],
    "moves": ["Name", "Type", "Category", "Power", "Accuracy", "TotalPP", "Target", "Priority", "FunctionCode", "Flags", "EffectChance", "Description"],
    "items": ["Name", "NamePlural", "PortionName", "PortionNamePlural", "Pocket", "Price", "SellPrice", "BPPrice", "FieldUse", "BattleUse", "Flags", "Consumable", "ShowQuantity", "Move", "Description"],
    "pokemon": ["Name", "FormName", "Types", "BaseStats", "GenderRatio", "GrowthRate", "BaseExp", "EVs", "CatchRate", "Happiness", "Abilities", "HiddenAbilities", "Moves", "TutorMoves", "EggMoves", "EggGroups", "HatchSteps", "HatchCycles", "Height", "Weight", "Color", "Shape", "Habitat", "Category", "Pokedex", "IoPokedex", "AmPokedex", "Generation", "Flags", "WildItemCommon", "WildItemUncommon", "WildItemRare", "Evolutions", "RaidRanks"],
    "pokemon_forms": ["FormName", "PokedexForm", "MegaStone", "MegaMove", "UnmegaForm", "MegaMessage", "Types", "BaseStats", "BaseExp", "EVs", "CatchRate", "Happiness", "Abilities", "HiddenAbilities", "Moves", "TutorMoves", "EggMoves", "EggGroups", "HatchCycles", "Offspring", "Height", "Weight", "Color", "Shape", "Habitat", "Category", "Pokedex", "Generation", "Flags", "WildItemCommon", "WildItemUncommon", "WildItemRare", "Evolutions", "RaidRanks"],
    "trainer_types": ["Name", "Gender", "BaseMoney", "SkillLevel", "Flags", "IntroBGM", "BattleBGM", "VictoryBGM"],
}

@dataclass
class Record:
    section: str
    values: Dict[str, str] = field(default_factory=dict)
    key_order: List[str] = field(default_factory=list)
    leading_comments: List[str] = field(default_factory=list)

    def set_value(self, key: str, value: str) -> None:
        if key not in self.values:
            self.key_order.append(key)
        self.values[key] = value

    def delete_key(self, key: str) -> None:
        self.values.pop(key, None)
        self.key_order = [k for k in self.key_order if k != key]

class PBSFile:
    def __init__(self, path: str):
        self.path = path
        self.header_comments: List[str] = []
        self.records: List[Record] = []
        self.load()

    def load(self) -> None:
        self.header_comments.clear()
        self.records.clear()
        current: Optional[Record] = None
        pending_comments: List[str] = []
        with open(self.path, "r", encoding="utf-8-sig", errors="replace") as f:
            for raw in f.read().splitlines():
                line = raw.rstrip("\r\n")
                stripped = line.strip()
                if not stripped:
                    pending_comments.append("")
                    continue
                if stripped.startswith("#"):
                    pending_comments.append(line)
                    continue
                if stripped.startswith("[") and stripped.endswith("]"):
                    section = stripped[1:-1].strip()
                    current = Record(section=section, leading_comments=pending_comments)
                    self.records.append(current)
                    pending_comments = []
                    continue
                if current is None:
                    self.header_comments.extend(pending_comments)
                    pending_comments = []
                    self.header_comments.append(line)
                    continue
                if "=" in line:
                    key, value = line.split("=", 1)
                    current.set_value(key.strip(), value.strip())
                else:
                    # Preserve unusual non key/value lines as comment-like data.
                    pending_comments.append("# UNPARSED: " + line)
        if not self.records and pending_comments:
            self.header_comments.extend(pending_comments)

    def save(self) -> None:
        if os.path.exists(self.path):
            backup = self.path + ".bak"
            shutil.copy2(self.path, backup)
        with open(self.path, "w", encoding="utf-8", newline="\r\n") as f:
            if self.header_comments:
                for line in self.header_comments:
                    f.write(line + "\n")
            for i, rec in enumerate(self.records):
                comments = rec.leading_comments or (["#-------------------------------"] if i else [])
                for line in comments:
                    f.write(line + "\n")
                f.write(f"[{rec.section}]\n")
                for key in rec.key_order:
                    if key in rec.values and rec.values[key] != "":
                        f.write(f"{key} = {rec.values[key]}\n")

class PBSEditor(tk.Tk):
    def __init__(self):
        super().__init__()
        self.title("PBS Editor MVP")
        self.geometry("1100x700")
        self.pbs_dir: Optional[str] = None
        self.file: Optional[PBSFile] = None
        self.current_record: Optional[Record] = None
        self._build_ui()

    def _build_ui(self) -> None:
        toolbar = ttk.Frame(self)
        toolbar.pack(side=tk.TOP, fill=tk.X, padx=6, pady=6)
        ttk.Button(toolbar, text="Open PBS Folder", command=self.open_folder).pack(side=tk.LEFT)
        ttk.Button(toolbar, text="Save", command=self.save_file).pack(side=tk.LEFT, padx=(6, 0))
        ttk.Label(toolbar, text="Search:").pack(side=tk.LEFT, padx=(18, 4))
        self.search_var = tk.StringVar()
        self.search_var.trace_add("write", lambda *_: self.refresh_records())
        ttk.Entry(toolbar, textvariable=self.search_var, width=35).pack(side=tk.LEFT)

        main = ttk.PanedWindow(self, orient=tk.HORIZONTAL)
        main.pack(fill=tk.BOTH, expand=True)

        left = ttk.Frame(main)
        main.add(left, weight=1)
        ttk.Label(left, text="PBS files").pack(anchor=tk.W, padx=6)
        self.files_list = tk.Listbox(left, exportselection=False)
        self.files_list.pack(fill=tk.BOTH, expand=True, padx=6, pady=(0, 6))
        self.files_list.bind("<<ListboxSelect>>", lambda e: self.open_selected_file())

        mid = ttk.Frame(main)
        main.add(mid, weight=1)
        recbar = ttk.Frame(mid)
        recbar.pack(fill=tk.X, padx=6)
        ttk.Label(recbar, text="Records").pack(side=tk.LEFT)
        ttk.Button(recbar, text="Add", command=self.add_record).pack(side=tk.RIGHT)
        ttk.Button(recbar, text="Duplicate", command=self.duplicate_record).pack(side=tk.RIGHT, padx=3)
        ttk.Button(recbar, text="Delete", command=self.delete_record).pack(side=tk.RIGHT)
        self.records_list = tk.Listbox(mid, exportselection=False)
        self.records_list.pack(fill=tk.BOTH, expand=True, padx=6, pady=(0, 6))
        self.records_list.bind("<<ListboxSelect>>", lambda e: self.select_record())

        right = ttk.Frame(main)
        main.add(right, weight=3)
        top = ttk.Frame(right)
        top.pack(fill=tk.X, padx=6)
        ttk.Label(top, text="Section ID:").pack(side=tk.LEFT)
        self.section_var = tk.StringVar()
        ttk.Entry(top, textvariable=self.section_var, width=30).pack(side=tk.LEFT, padx=4)
        ttk.Button(top, text="Rename ID", command=self.rename_record).pack(side=tk.LEFT)
        ttk.Button(top, text="Add Key", command=self.add_key).pack(side=tk.RIGHT)
        ttk.Button(top, text="Delete Key", command=self.delete_key).pack(side=tk.RIGHT, padx=4)

        self.tree = ttk.Treeview(right, columns=("key", "value"), show="headings", selectmode="browse")
        self.tree.heading("key", text="Key")
        self.tree.heading("value", text="Value")
        self.tree.column("key", width=180, stretch=False)
        self.tree.column("value", width=620, stretch=True)
        self.tree.pack(fill=tk.BOTH, expand=True, padx=6, pady=6)
        self.tree.bind("<<TreeviewSelect>>", lambda e: self.load_value())

        edit = ttk.Frame(right)
        edit.pack(fill=tk.X, padx=6, pady=(0, 6))
        ttk.Label(edit, text="Value:").pack(anchor=tk.W)
        self.value_text = tk.Text(edit, height=5, wrap=tk.WORD)
        self.value_text.pack(fill=tk.X)
        ttk.Button(edit, text="Apply Value", command=self.apply_value).pack(anchor=tk.E, pady=4)

    def open_folder(self) -> None:
        d = filedialog.askdirectory(title="Choose your PBS folder")
        if not d:
            return
        self.pbs_dir = d
        self.files_list.delete(0, tk.END)
        files = []
        for root, _, names in os.walk(d):
            for name in names:
                if name.lower().endswith(".txt"):
                    files.append(os.path.relpath(os.path.join(root, name), d))
        for rel in sorted(files, key=str.lower):
            self.files_list.insert(tk.END, rel)

    def open_selected_file(self) -> None:
        if not self.pbs_dir or not self.files_list.curselection():
            return
        rel = self.files_list.get(self.files_list.curselection()[0])
        try:
            self.file = PBSFile(os.path.join(self.pbs_dir, rel))
        except Exception as e:
            messagebox.showerror("Open failed", str(e))
            return
        self.current_record = None
        self.refresh_records()
        self.clear_editor()

    def refresh_records(self) -> None:
        self.records_list.delete(0, tk.END)
        if not self.file:
            return
        q = self.search_var.get().strip().lower()
        for i, rec in enumerate(self.file.records):
            hay = rec.section.lower() + "\n" + "\n".join(f"{k}={v}" for k, v in rec.values.items()).lower()
            if not q or q in hay:
                name = rec.values.get("Name", "")
                self.records_list.insert(tk.END, f"{i:04d}  [{rec.section}]  {name}")

    def _selected_record_index(self) -> Optional[int]:
        if not self.records_list.curselection():
            return None
        label = self.records_list.get(self.records_list.curselection()[0])
        try:
            return int(label.split()[0])
        except Exception:
            return None

    def select_record(self) -> None:
        idx = self._selected_record_index()
        if self.file is None or idx is None:
            return
        self.current_record = self.file.records[idx]
        self.section_var.set(self.current_record.section)
        self.refresh_keys()

    def clear_editor(self) -> None:
        self.section_var.set("")
        self.tree.delete(*self.tree.get_children())
        self.value_text.delete("1.0", tk.END)

    def refresh_keys(self) -> None:
        self.tree.delete(*self.tree.get_children())
        if not self.current_record:
            return
        shown = set()
        for key in self.current_record.key_order:
            if key in self.current_record.values:
                self.tree.insert("", tk.END, iid=key, values=(key, self.current_record.values[key]))
                shown.add(key)
        # show known-but-missing keys as grey-ish placeholders by prefixing +
        if self.file:
            basename = os.path.basename(self.file.path).lower().replace(".txt", "")
            base = basename.split("_")[0]
            if basename.startswith("pokemon_forms"):
                base = "pokemon_forms"
            elif basename.startswith("trainer_types"):
                base = "trainer_types"
            elif basename.startswith("pokemon"):
                base = "pokemon"
            elif basename.startswith("items"):
                base = "items"
            elif basename.startswith("moves"):
                base = "moves"
            elif basename.startswith("abilities"):
                base = "abilities"
            for key in KNOWN_SCHEMAS.get(base, []):
                if key not in shown:
                    self.tree.insert("", tk.END, iid="+" + key, values=("+ " + key, ""))

    def load_value(self) -> None:
        self.value_text.delete("1.0", tk.END)
        if not self.current_record or not self.tree.selection():
            return
        key = self.tree.selection()[0].lstrip("+")
        self.value_text.insert("1.0", self.current_record.values.get(key, ""))

    def apply_value(self) -> None:
        if not self.current_record or not self.tree.selection():
            return
        key = self.tree.selection()[0].lstrip("+")
        value = self.value_text.get("1.0", tk.END).strip().replace("\n", " ")
        self.current_record.set_value(key, value)
        self.refresh_keys()
        self.refresh_records()

    def rename_record(self) -> None:
        if self.current_record:
            new_id = self.section_var.get().strip().upper()
            if new_id:
                self.current_record.section = new_id
                self.refresh_records()

    def add_key(self) -> None:
        if not self.current_record:
            return
        key = simpledialog.askstring("Add Key", "PBS key name:")
        if key:
            self.current_record.set_value(key.strip(), "")
            self.refresh_keys()

    def delete_key(self) -> None:
        if not self.current_record or not self.tree.selection():
            return
        key = self.tree.selection()[0].lstrip("+")
        self.current_record.delete_key(key)
        self.refresh_keys()

    def add_record(self) -> None:
        if not self.file:
            return
        section = simpledialog.askstring("Add Record", "New section ID, e.g. MYABILITY:")
        if not section:
            return
        rec = Record(section=section.strip().upper(), leading_comments=["#-------------------------------"])
        self.file.records.append(rec)
        self.refresh_records()

    def duplicate_record(self) -> None:
        if not self.file or not self.current_record:
            return
        section = simpledialog.askstring("Duplicate Record", "New section ID:")
        if not section:
            return
        old = self.current_record
        rec = Record(section=section.strip().upper(), values=dict(old.values), key_order=list(old.key_order), leading_comments=["#-------------------------------"])
        self.file.records.append(rec)
        self.refresh_records()

    def delete_record(self) -> None:
        if not self.file:
            return
        idx = self._selected_record_index()
        if idx is None:
            return
        if messagebox.askyesno("Delete Record", "Delete this whole PBS record?"):
            del self.file.records[idx]
            self.current_record = None
            self.refresh_records()
            self.clear_editor()

    def save_file(self) -> None:
        if not self.file:
            return
        try:
            self.file.save()
            messagebox.showinfo("Saved", "Saved PBS file and created/updated .bak backup.")
        except Exception as e:
            messagebox.showerror("Save failed", str(e))

if __name__ == "__main__":
    PBSEditor().mainloop()
