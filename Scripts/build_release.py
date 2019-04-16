#!/usr/bin/env python3

# This script will build the zipped version of the mod that is ready for release on the mod portal
# It will also first bump versions and the changelog(, and commit and push to github at the end -> doesn't work atm)
# This should be run in the directory that contains your factorio installation as well as the mod project folder
# You can set a modname, although this only works if the filestructure is the same as my factoryplanner mod

from pathlib import Path
import itertools
import json
import subprocess
from datetime import datetime
import shutil
import os

# Script config
MODNAME = "factoryplanner"

# Some git setup
cwd = Path.cwd()
""" os.chdir(cwd / MODNAME)
subprocess.run(["git", "checkout", "master"], shell=True)
os.chdir(Path.cwd() / "..") """

# Determine path and version-number
mod_folder_path = list(itertools.islice((cwd / MODNAME).glob(MODNAME + "_*"), 1))[0]
old_version = mod_folder_path.parts[-1].split("_")[-1]
split_old_version = old_version.split(".")
split_old_version[-1] = str(int(split_old_version[-1]) + 1)
new_version = ".".join(split_old_version)

# Bump mod folder version
new_mod_folder_path = Path(MODNAME, MODNAME + "_" + new_version)
mod_folder_path.rename(new_mod_folder_path)
print("- mod folder version bumped")

# Update factorio folder mod symlink
factorio_mod_folder_path = list(itertools.islice(cwd.glob("Factorio_*"), 1))[0] / "mods"
old_symlink_path = list(itertools.islice(factorio_mod_folder_path.glob(MODNAME + "_*"), 1))[0]
old_symlink_path.rmdir()
new_symlink_path = Path(factorio_mod_folder_path, MODNAME + "_" + new_version)
# This kind of symlink is best done with subprocess (on Windows)
subprocess.run(["mklink", "/J", str(new_symlink_path), str(new_mod_folder_path), ">nul"], shell=True)
print("- mod folder symlink updated")

# Bump info.json version
with (new_mod_folder_path / "info.json").open("r") as file:
    data = json.load(file)
data["version"] = new_version
with (new_mod_folder_path / "info.json").open("w") as file:
    json.dump(data, file, indent=4)
print("- info.json version bumped")

# Update changelog file for release
tmp_path = Path(new_mod_folder_path / "tmp")
old_changelog_path = new_mod_folder_path / "changelog.txt"

with (tmp_path.open("w")) as new_file:
    with (old_changelog_path).open("r") as old_file:
        changes = 0  # Only changes the first changelog entry
        for line in old_file:
            if changes < 2 and "Version" in line:
                new_file.write("Version: " + new_version + "\n")
                changes += 1
            elif changes < 2 and "Date" in line:
                new_file.write("Date: " + datetime.today().strftime("%d. %m. %Y") + "\n")
                changes += 1
            else:
                new_file.write(line)

old_changelog_path.unlink()
new_changelog_path = new_mod_folder_path / "changelog.txt"
tmp_path.rename(new_changelog_path)
print("- changelog updated for release")

# Create zip archive
zipfile_path = Path(cwd, MODNAME, "Releases", MODNAME + "_" + new_version)
shutil.make_archive(zipfile_path, "zip", new_mod_folder_path)
print("- zip archive created")

# Commit and push to GitHub
""" os.chdir(cwd / MODNAME)
subprocess.run(["git", "add", "-A"], shell=True)
subprocess.run(["git", "commit", "-m", "Release " + new_version], shell=True)
subprocess.run(["git", "push", "origin", "master"], shell=True)
os.chdir(Path.cwd() / "..")
print("- changes committed and pushed") """

# Update changelog file for further development
new_changelog_entry = ("-----------------------------------------------------------------------------------------------"
                       "----\nVersion: 0.17.00\nDate: 00. 00. 0000\n  Features:\n    - \n  Changes:\n    -\n  Bugfixes:"
                       "\n    - \n\n")
with (new_changelog_path.open("r")) as changelog:
    old_changelog = changelog.readlines()
old_changelog.insert(0, new_changelog_entry)
with (new_changelog_path.open("w")) as changelog:
    changelog.writelines(old_changelog)
print("- changelog updated for further development")

# Update workspace
workspace_path = cwd / "fp.code-workspace"
with (workspace_path.open("r")) as ws:
    workspace = ws.readlines()
with (workspace_path.open("w")) as ws:
    for line in workspace:
        ws.write(line.replace("factoryplanner_" + old_version, "factoryplanner_" + new_version))
print("- workspace updated")