
# script to create the tmp folder containing the links to each of the subgroups of study.

import csv
import sys
import os
import shutil

def get_ids_by_smoking_state(file_path, target_state="smoker"):
    """
    Reads a TSV file and returns a list of IDs where the smoking state matches
    target_state. Assumes the TSV has headers: 'id' and 'smoking_state'.
    """
    results = []
    
    if not os.path.exists(file_path):
        print(f"Error: File '{file_path}' not found.")
        return results

    try:
        with open(file_path, mode='r', encoding='utf-8') as f:
            # The 'delimiter' tells the reader to look for tabs instead of commas
            reader = csv.DictReader(f, delimiter='\t')
            
            for row in reader:
                # Using .strip() to handle potential accidental whitespace
                if row.get('smoking_state', '').strip().lower() == target_state.lower():
                    results.append(row.get('magID'))
                    
    except Exception as e:
        print(f"An error occurred: {e}")
        
    return results

def get_ids_by_group(file_path, target_group="healthy"):
    """
    Reads a TSV file and returns a list of IDs where the group matches target_group.
    Assumes the TSV has headers: 'id' and 'group'.
    """
    results = []
    
    if not os.path.exists(file_path):
        print(f"Error: File '{file_path}' not found.")
        return results

    try:
        with open(file_path, mode='r', encoding='utf-8') as f:
            # The 'delimiter' tells the reader to look for tabs instead of commas
            reader = csv.DictReader(f, delimiter='\t')
            
            for row in reader:
                # Using .strip() to handle potential accidental whitespace
                if row.get('study_group', '').strip().lower() == target_group.lower():
                    results.append(row.get('magID'))
                    
    except Exception as e:
        print(f"An error occurred: {e}")
        
    return results

# it has been modified to cretate the links for the AA files
if __name__ == "__main__":
    # Example usage: provide path via command line or hardcode it
    # path = "data.tsv"
    if len(sys.argv) > 1:
        based_on_groups = True #based generation is on groups by default
        based_on_states = False

        # variables that will be setted by the user using 'both' or 'group' or 'smoking_state' as arguments
        if len(sys.argv) > 2:

            print("execution with decision on group selection")
            if sys.argv[2] == "group":
                based_on_groups = True
            elif sys.argv[2] == "smoking_state":
                based_on_states = True
                based_on_groups = False
            elif sys.argv[2] == "both":
                based_on_groups = True
                based_on_states = True
            else:
                print("Invalid argument. Please use 'group', 'smoking_state', or 'both'.")

        # keeping the path to the csv 
        path = sys.argv[1]

        # Exectution on GROUPS TYPE
        if based_on_groups:
            group_types_label = ["healthy","mucositis","periimplantitis"]
            healthy = get_ids_by_group(path)
            mucositis = get_ids_by_group(path, "mucositis")
            periimplantitis = get_ids_by_group(path, "periimplantitis")
            group_types = [healthy,mucositis,periimplantitis]
            # print(f"IDs with group 'healthy': {ids}")

            # Move a file from source to destination
            # This works for moving to a new folder OR renaming the file
            
            # HERE THERE IS HARDCODED PATHS
            for i in range(0, 3):
                print(f"creo {group_types_label[i]}")
                
                # 1. Create the directory
                os.system(f"mkdir -p tmp/{group_types_label[i]}")
                
                # 2. Define the path for the total file
                tot_file_path = f"tmp/{group_types_label[i]}/tot.faa"
                
                # 3. Open the 'tot' file in write mode ('w') first to ensure it's empty 
                # for this specific group, then use append mode ('a') inside the loop
                with open(tot_file_path, "w") as tot_file:
                    for h in group_types[i]:
                        source_path = f"results/checkm2/protein_files/{h}.faa"
                        
                        # Check if source file exists to avoid errors
                        if os.path.exists(source_path):
                            with open(source_path, "r") as source_file:
                                # Read the content of the individual protein file and write to tot
                                tot_file.write(source_file.read())
                                # Optional: ensure there is a newline between files
                                tot_file.write("\n")
        # Execution on SMOKING STATE 
        if based_on_states:

            group_types_label = ["smoker","non-smoker","ex-smoker"]
            non_smoker = get_ids_by_smoking_state(path, "non-smoker")
            ex_smoker = get_ids_by_smoking_state(path, "ex-smoker")
            smoker = get_ids_by_smoking_state(path, "smoker")
            group_types = [non_smoker,ex_smoker, smoker]
            
            
            for i in range(0, 3):
                print(f"creo {group_types_label[i]}")
                
                # 1. Create the directory
                os.system(f"mkdir -p tmp/{group_types_label[i]}")
                
                # 2. Define the path for the total file
                tot_file_path = f"tmp/{group_types_label[i]}/tot.faa"
                
                # 3. Open the 'tot' file in write mode ('w') first to ensure it's empty 
                # for this specific group, then use append mode ('a') inside the loop
                with open(tot_file_path, "w") as tot_file:
                    for h in group_types[i]:
                        source_path = f"results/checkm2/protein_files/{h}.faa"
                        
                        # Check if source file exists to avoid errors
                        if os.path.exists(source_path):
                            with open(source_path, "r") as source_file:
                                # Read the content of the individual protein file and write to tot
                                tot_file.write(source_file.read())
                                # Optional: ensure there is a newline between files
                                tot_file.write("\n")
            # shutil.move("old_folder/data.tsv", "new_folder/data.tsv")
    else:
        print("Please provide a file path. Usage: python script.py your_file.tsv")