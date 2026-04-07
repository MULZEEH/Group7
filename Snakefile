# Snakefile
# File containting the run and structure of the overall pipeline;
# Pipeline Steps:
# 1) QC: First step is to perfrom a QUALITY CHECK on all the MAGs. The QC has been done using CheckM2(or QUAST) tool, 
#       which provides a comprehensive report on the quality of the MAGs, including completeness, contamination, and other relevant metrics. 
#       This step ensures that only high-quality MAGs are included in subsequent analyses.
#       What this needs: MAGs (FASTA files)
#       What this gives us: Contamination/Completeness and other useless information
#       Why:To ensure data reliability (setting filters/analysis as extra 'metadata')
# 2) Taxonomy Assignment: Secondly GTDB-Tk	( https://doi.org/10.1093/bioinformatics/btz848) or Segata's PhyloPhlAn (https://pubmed.ncbi.nlm.nih.gov/23942190/) 
#       will be used to assign taxonomy to the MAGs, providing insights into their taxonomic classification and potential ecological roles.
#       What this needs: MAGs (FASTA files)
#       What this gives us: Taxonomic rank -> Genus/Species
#       Why: Identify the organism for contextualizing the organism genome characteristic
# 3) Genome Annotation: Crucial step Prokka
#       What this needs: MAGs (FASTA files)
#       What this gives us: Annotation files (GFF)
#       Why: To document metabolic structure
# 4) Pangenome analysis	(Roary)
#       What this needs: Annotation files (GFF)
#       What this gives us: Gene presence/behavior Matrix
#       Why: To find shared vs Unique traits (pangenome insight)
# 5) Phylogeny analysis	Phylophlan + tree... -> could be done some /alpha and /beta diversity analysis	
#       What this needs: 
#       What this gives us: Evolutionary Tree (.nwk)
#       Why: To map evolutionary history
# 6) Association with host Metadata	( actually runned in all others steps )
#       What this needs: Previous Results + Metadata CSV file
#       What this gives us: Statistical Correlation
#       Why: To give biological meaning between results and sample contextualization

# to hadnle in a clean way the output --verbose 2>&1 | tee -a log.txt # or path to the log file

# snakemake --dag | dot -Tsvg > pipeline_dag.svg

# Load configuration
configfile: "config.yml"
import os

# --- Configuration Logic ---
DO_BACKUP = config.get("backup", False) # RUN also a backup rule after the workflow ended -> probabily gonna remove it
DO_CORRELATION = config.get("correlation", False) # run also the correlation script
IS_PLANE = config.get("plane", False)
KEEP_JUNK = config.get("keep_junk", False)
MAG_DIR = config.get("mag_input_dir", "data/mags")
THREADS = config.get("threads", 4)


# here has to be updated with the real targets of the pipelines
# taxonomy -> 
# quality_control ->
# annotation ->
# functional_annotation ->
# pangenome ->
# phylogeny ->
# correlation ->
standard_targets = ["taxonomy", "quality_control", "annotation", "Pangenome", "phylogeny"]
if not IS_PLANE:
    standard_targets.append("functional_annotation")
if DO_CORRELATION:
    standard_targets.append("correlation")
    standard_targets.append("functional_annotation")


# --- Handlers for Automatic Cleanup ---

onsuccess:
    if os.path.exists(".tmp/setup_complete.txt"):
        os.remove(".tmp/setup_complete.txt")
    print("Workflow finished successfully. Cleanup complete.")

onerror:
    if os.path.exists(".tmp/setup_complete.txt"):
        os.remove(".tmp/setup_complete.txt")
    print("Workflow failed. Cleanup complete.")


# Define MAG samples (IF THE INPUT DATA IS CHANGED THIS LIST NEEDS TO BE UPDATED) -> could be also automitized but for now kept like this to insert some awereness of the user on the matter of data input
# SAMPLES = config.get("samples", [])

# Automatized version
SAMPLES, = glob_wildcards(f"{MAG_DIR}/{{sample}}.fna")


# --- Workflow Rules ---
rule all:
    input:
        # 1. Quality Control Report
        "results/checkm2/quality_report.tsv",
        
        # 2. Taxonomy Report
        #"results/taxonomy/ppa_m.tsv",
        
        # 3. All Annotation files (GFF and FAA for every sample)
        expand("results/annotation/{sample}/{sample}.gff", sample=SAMPLES),
        expand("results/annotation/{sample}/{sample}.faa", sample=SAMPLES),
        
        # 4. Pangenome Summary
        "results/pangenome/summary_statistics.txt",
        
        # 5. The Final Phylogeny Tree
        "results/phylogeny/RAxML_bestTree.faa_refined.tre"
        
rule preprep:
    output:
        temp(".tmp/setup_complete.txt")
    shell:
        """
        ORANGE='\033[38;2;255;140;0m'
        RESET='\033[0m'

        echo -e "${{ORANGE}}"
        cat << "EOF"
  ██████╗  █████╗ ███╗   ██╗      ██████╗ ██╗ ██████╗ ██████╗ ██╗███╗   ██╗
  ██╔══██╗██╔══██╗████╗  ██║      ██╔══██╗██║██╔═══██╗██╔══██╗██║████╗  ██║
  ██████╔╝███████║██╔██╗ ██║█████╗██████╔╝██║██║   ██║██████╔╝██║██╔██╗ ██║
  ██╔═══╝ ██╔══██║██║╚██╗██║╚════╝██╔══██╗██║██║   ██║██╔══██╗██║██║╚██╗██║
  ██║     ██║  ██║██║ ╚████║      ██████╔╝██║╚██████╔╝██████╔╝██║██║ ╚████║
  ╚═╝     ╚═╝  ╚═╝╚═╝  ╚═══╝      ╚═════╝ ╚═╝ ╚═════╝ ╚═════╝ ╚═╝╚═╝  ╚═══╝
EOF
        echo -e "${{RESET}}"
        
# here ADD ADDITIONAL CHECK for GITTOKEN and DATABASES (CHECKM2 AND EGGNOG) and other stuff that is needed for the pipeline to run correctly, if not present exit with an error message

        mkdir -p log
        mkdir -p results
        mkdir -p .tmp
        echo "Setup complete." > {output}
        """

# --- STEP 1: Quality Checking ---
rule qc:
    input:
        preprap = ".tmp/setup_complete.txt",
        bins = MAG_DIR,
    output:
        report = "results/checkm2/quality_report.tsv"
    conda:
        "envs/QC.yml"
    shell:
        """
        rm -rf results/checkm2
        # 1. Set the database path from config
        export CHECKM2DB={config[checkm2_db_path]}
        
        # 2. Remove old results so CheckM2 doesn't complain
        rm -rf results/checkm2
        mkdir -p results/taxonomy
        
        checkm2 predict \
            --threads {THREADS} \
            --input {MAG_DIR} \
            --output-directory results/checkm2
            
        # 4. Clean up logs
        mv results/checkm2/*.log log/ 2>/dev/null || true
        """

# --- STEP 2: Taxonomy Assignment (Phylophlan) ---
rule taxo:
    input:
        preprep = ".tmp/setup_complete.txt",
        folder = MAG_DIR 
    output:
        report = "results/taxonomy/ppa_m.tsv"
    shell:
        """
        # 1. Clean the output folder first to avoid conflicts
        rm -rf results/taxonomy
        mkdir -p results/taxonomy

        # 2. Run the tool using variables
        phylophlan_metagenomics \
            -i {input.folder} \
            -o results/taxonomy \
            --output_file {output.report} \
            -d CMG2526 \
            --nproc {THREADS}
        """

# --- STEP 3: Annotation (Prokka) ---
rule anno:
    input:
        preprep = ".tmp/setup_complete.txt",
        mags = os.path.join(MAG_DIR, "{sample}.fna")
    output:
        dir = directory("results/annotation/{sample}"),
        gff = "results/annotation/{sample}/{sample}.gff",
        faa = "results/annotation/{sample}/{sample}.faa"
    conda:
        "envs/ANNO.yml"
    shell:
        """
        prokka \
            --outdir {output.dir} \
            --prefix {wildcards.sample} \
            --cpus {THREADS} \
            --centre X \
            --compliant \
            --force \
            {input.mags}      

        """

# eggnog-mapper -i {input.mags} -o {output} --cpu 8 --data_dir {config[eggnog_db_path]} --output_dir results/functional_annotation/ --override

# --- STEP 4: Pangenome (Roary) ---
rule pan:
    input:
        gffs = expand("results/annotation/{sample}/{sample}.gff", sample=SAMPLES)    
    output:
        "results/pangenome/summary_statistics.txt"
    conda:
        "envs/PAN.yml"
    shell:
        """
        rm -rf results/pangenome
        
        roary -f results/pangenome -p {THREADS} -e --mafft -r -cd 90 results/annotation/*/*gff
        """

# roary -f results/pangenome -p {THREADS} -e --mafft -r -cd 90 {input.gffs}

# --- STEP 5: Phylogeny (PhyloPhlAn) ---
rule phylo:
    input:
        faas = expand("results/annotation/{sample}/{sample}.faa", sample=SAMPLES)
    output:
        tree = "results/phylogeny/RAxML_bestTree.faa_refined.tre"
    params:
        input_dir = "results/annotation",
        db = config.get("phylophlan_db_path", "phylophlan"),
        out_dir = "results/phylogeny"
    conda:
        "envs/PHYLO.yml"
    shell:
        """
        rm -rf results/phylogeny

        # 1. Generate the config in the .tmp folder
        phylophlan_write_default_configs.sh .tmp/
        
        rm -rf .tmp/faa
        mkdir -p .tmp/faa
        cd .tmp/faa
        ln -s ../../results/annotation/*/*faa .
        cd ../..

        # 2. Run directly to the results folder
        phylophlan \
            -i .tmp/faa \
            -o {params.out_dir} \
            -d phylophlan \
            -t a \
            -f .tmp/supermatrix_aa.cfg \
            --diversity low \
            --fast \
            --nproc {THREADS} \
            --verbose 2>&1 | tee log/phylo.log

        # 3. CLEANUP: Remove the "scaffolding" files
        # PhyloPhlAn leaves behind folders like 'alignments' and 'sequences'
        rm -rf {params.out_dir}/alignments
        rm -rf {params.out_dir}/sequences
        rm -rf .tmp/*.cfg
        rm -rf .tmp/faa
        """

# --- STEP 6: Metadata Association with Phylogeny(Anpan) ---
# Probabily i will have to split this rule in multiple steps, but for now i will keep it like this to have a general idea of the workflow;
rule correlation:
    input:
        pangenome = "results/pangenome/gene_presence_absence.csv",
        metadata = "data/host_metadata.csv"
    output:
        "results/final_analysis/metadata_joined.csv"
    conda:
        "envs/anpan.yml"
    run:
        from importlib_metadata import files
        import pandas as pd
        pan = pd.read_csv(input.pangenome)
        meta = pd.read_csv(input.metadata)
        # Your custom Python logic here to link SGBs to host traits
        result = pan.merge(meta, left_on='Gene', right_on='Host_ID') 
        result.to_csv(output[0])

# rule backup:
# Saves all the results and logs in a backup folder. prepared to be cleaned and runned again
rule backup:
    shell: 
        """
        # SAVE CURRENT TIME
        TIME=$(date +%Y-%m-%d_%H-%M-%S)
        # CREATE A BACKUP OF THE RESULTS AND LOGS in BACKUP FOLDER
        mkdir -p backup
        tar -czvf backup/backup_${{TIME}}.tar.gz results/ log/
        """

 # ------ DB DOWNLOAD RULES (CHECKM2 AND EGGNOG) ----

rule database:
    input:
        check = config.get("checkm2_db_path", "data/checkm2/database/"),
        egg = ".tmp/egg_db_complete.txt"
    params:
        do_egg_db = DO_CORRELATION
    shell: 
        """
        # ----- DB DOWNLOAD -----
        echo "MIAO"
        """

rule check_db:
    conda:
        "envs/QC.yml"
    output:
        check = temp(".tmp/checkm2_db_complete.txt")
    shell:
        """
        mkdir -p {config[checkm2_db_path]}
        # export CHECKM2DB={config[checkm2_db_path]}
        checkm2 database --download --path {config[checkm2_db_path]}
        echo "CheckM2 database download complete." > {output.check}
        """
# rule to be fixed
rule egg_db:
    conda:
        "envs/EGG.yml"
    output: 
        egg = temp(".tmp/egg_db_complete.txt")
    shell:
        """
        if [ {DO_CORRELATION} = True ]; then
            echo "EggNOG database download skipped as correlation analysis is not enabled."
            exit 0
        fi
        # download_eggnog_data.py --data_dir {config[eggnog_db_path]} --cpu 8
        echo "EggNOG database download complete." > {output.egg}
        """ 



## Visual Difference
# ```
# RULE (static):
#   Start → Build full DAG → Run A → Run B → Run C → Done
#           [everything known]

# CHECKPOINT (dynamic):
#   Start → Build partial DAG → Run A → STOP → Rebuild DAG → Run B → Run C → Done
#                                        [inspect outputs]
#  ```

# rule check:
#     input:
#         bins = MAG_DIR
#     output:
#         flag = temp(".tmp/checked.txt"),
#         files = expand(f"{MAG_DIR}/{{sample}}.fna", sample=SAMPLES)    
#     run:
#         import os
#         import bz2

#         # 1. Check if the directory itself exists
#         if not os.path.isdir(input.bins):
#             raise FileNotFoundError(f"Directory not found: {input.bins}")

#         # 2. Use SAMPLES as the source of truth
#         # We check that every sample in your config actually has a file on disk
#         for sample in SAMPLES:
#             fna_path = os.path.join(input.bins, f"{sample}.fna")
#             bz2_path = os.path.join(input.bins, f"{sample}.fna.bz2")
            
#             if not (os.path.exists(fna_path) or os.path.exists(bz2_path)):
#                 raise FileNotFoundError(
#                     f"Sample '{sample}' defined in config, but {sample}.fna "
#                     f"or {sample}.fna.bz2 was not found in {input.bins}"
#                 )

#         # 3. Optional: Check for "Intruders" (Extra files)
#         all_files = os.listdir(input.bins)
#         for f in all_files:
#             if not any(f.startswith(s) for s in SAMPLES):
#                 print(f"Note: Ignoring extra file in directory: {f}")
        
#         # Compare with SAMPLES list
#         samples_set = set(SAMPLES)

# # ------DEBUG PRINTS --------
#         # print(f"Files in directory: {files_in_dir}")
#         # print(f"Expected samples: {samples_set}")

#         missing_samples = samples_set - files_in_dir
#         extra_files = files_in_dir - samples_set
        
#         if missing_samples:
#             raise ValueError(f"Missing samples in data/mags/: {missing_samples}")
        
#         if extra_files:
#             raise ValueError(f"Extra unexpected files in data/mags/: {extra_files}")
        
#         # All checks passed
#         with open(output.flag, 'w') as f:
#             f.write("All file names match SAMPLES list. Bins are present and ready for analysis.\n")

#         # Check the unzipping of the files is terminated without any error
    
#         # Find and extract all zip files
#         print("Checking for bz2 files to extract...")
#         for filename in os.listdir(input.bins):
#             filepath = os.path.join(input.bins, filename)
#             newfilepath = os.path.join(input.bins, os.path.splitext(filename)[0])  # Remove .bz2 extension (maybe there is a prettier way to do that)
#             with open(newfilepath, 'wb') as new_file, bz2.BZ2File(filepath, 'rb') as file:
#                 for data in iter(lambda : file.read(100 * 1024), b''):
#                     new_file.write(data)
#         # Create flag file
#         with open(output.flag, 'a') as f:
#             f.write("All bz2 files have been extracted.\n")

# rule fun_anno:
#     input: 
#     output: 
#     run: 

