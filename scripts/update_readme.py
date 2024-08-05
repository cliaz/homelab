#!/usr/env/bin python3

import os, re

root_directory = '.'      # the root of the repo
stacks_section_placeholder = "# Stacks\n\n"
folders_with_readme_files = []

# build a list of all subfolders that contain a README.md file
for root, dirs, files in os.walk(root_directory):
    if root != root_directory:
        for file in files:
            if file.endswith('README.md'):
                folders_with_readme_files.append(root)


# open the main readme, which has the {<subfolder>_README} placeholders to be substituted
with open ("scripts/README.stub", "r") as file:
    readme_stub = file.read()


## This whole section is a bit janky
# replace "# Stacks" section with a placeholder for each subfolder's README.md file
# this involves updating the stacks_section_placeholder to first include any {<subfolder>_README} blocks
# already defined in the readme_stub
#pattern = r'^# Stacks\n+(^\{.*_README\}$\n*)*^# '
pattern = r'^# Stacks\n+(^.*$\n*)*^# '
regex = re.compile(pattern, re.MULTILINE)
if regex.search(readme_stub):
    stacks_section_placeholder = regex.search(readme_stub).group()
    stacks_section_placeholder = stacks_section_placeholder[:-3]

# Once we've identified where the bottom of the already-included {<subfolder>_README} blocks are,
# add any missing ones at the bottom
# by updatong the stacks section placeholder to include any {<subfolder>_README} blocks
# that are not already in the stub
placeholder_list = stacks_section_placeholder+"\n"
for folder in sorted(folders_with_readme_files):
    placeholder = "{"+folder.split('/')[-1].upper()+"_README}"
    if placeholder not in readme_stub:
        placeholder_list += placeholder+"\n\n"

readme_stub = readme_stub.replace(stacks_section_placeholder, placeholder_list)

## End jank



# folder by folder, replace the placeholders in the main readme with the content of the 
# subfolder's README.md file
for folder in folders_with_readme_files:
    replacement_content = ""
    replacement_placeholder = ""
    
    # get the placeholder to replace
    replacement_placeholder = "{"+folder.split('/')[-1].upper()+"_README}"
    
    # get the subfolder readme.md content 
    with open (folder+"/README.md", "r") as file:
        replacement_content = file.read()

        # update the readme stub with the content of the subfolder's README.md file
        # needs to update the in-memory readme_stub each loop iteration
        readme_stub = readme_stub.replace(replacement_placeholder, replacement_content)
        
   
with open ("README.md", "w") as file:
    file.write(readme_stub)
