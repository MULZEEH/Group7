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
SAMPLES = ["M1076080470",
           "M1053959057",
           "M1078114725",
           "M1230650551",
           "M1245365434",
           "M1305644168",
           "M1319770895",
           "M1338737711",
           "M1366869580",
           "M1377790479",
           "M1468428565",
           "M1574952059",
           "M1588242869",
           "M1615715501",
           "M1618962711",
           "M1629152784",
           "M1659720332",
           "M1685111908",
           "M1694502688",
           "M1713418412",
           "M1812631083",
           "M1865579949",
           "M1865732633",
           "M1872771052",
           "M1891500794",
           "M1928604994",
           "M1934704281",
           "M1949040058",
           "M1961092429",
           "M1973206991"]

# --- Workflow Rules ---

rule all:
    input:
        "results/checked.txt",
        "results/checkm2/quality_report.tsv",
        "results/pangenome/summary_statistics.txt"
        
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

rule check:
    input:
        bins = "data/mags/"
    output:
        flag = ".tmp/checked.txt",
        files = expand("data/mags/{sample}.fna", sample=SAMPLES)
    run:
        import os
        import bz2
        # Check if files are correctly present in the data/mags/ directory
        if not os.path.exists(input.bins):
            raise FileNotFoundError(f"Input bins not found at {input.bins}")
        
        # Get the list of files in the mags directory
        files_in_dir = set()
        for file in os.listdir(input.bins):
            if os.path.isfile(os.path.join(input.bins, file)):
                # Remove file extension to get sample name (not sure its the best approach but it works for now)
                sample_name = os.path.splitext(os.path.splitext(file)[0])[0]
                # sample_name = os.path.splitext(sample_name)[0]
                files_in_dir.add(sample_name)
        
        # Compare with SAMPLES list
        samples_set = set(SAMPLES)

# ------DEBUG PRINTS --------
        # print(f"Files in directory: {files_in_dir}")
        # print(f"Expected samples: {samples_set}")

        missing_samples = samples_set - files_in_dir
        extra_files = files_in_dir - samples_set
        
        if missing_samples:
            raise ValueError(f"Missing samples in data/mags/: {missing_samples}")
        
        if extra_files:
            raise ValueError(f"Extra unexpected files in data/mags/: {extra_files}")
        
        # All checks passed
        with open(output.flag, 'w') as f:
            f.write("All file names match SAMPLES list. Bins are present and ready for analysis.\n")

        # Check the unzipping of the files is terminated without any error
    
        # Find and extract all zip files
        print("Checking for bz2 files to extract...")
        for filename in os.listdir(input.bins):
            filepath = os.path.join(input.bins, filename)
            newfilepath = os.path.join(input.bins, os.path.splitext(filename)[0])  # Remove .bz2 extension (maybe there is a prettier way to do that)
            with open(newfilepath, 'wb') as new_file, bz2.BZ2File(filepath, 'rb') as file:
                for data in iter(lambda : file.read(100 * 1024), b''):
                    new_file.write(data)
        # Create flag file
        with open(output.flag, 'a') as f:
            f.write("All bz2 files have been extracted.\n")

# --- STEP 1: Quality Checking ---
rule qc:
    input:
        preprap = ".tmp/setup_complete.txt",
        bins = "data/mags/",
        flag = "log/checked.txt"
    output:
        report = "results/checkm2/quality_report.tsv"
    conda:
        "envs/QC.yml"
    # exporting db is not working correctly but checkm2 replaced with checkm
    shell:
        """
        export CHECKM2DB={config[checkm2_db_path]}
        checkm2 database --download
        checkm2 predict --threads 8 --input {input.bins} --output-directory results/checkm2
        # then procede to remove useless junk that has been made by checkm
        mv -p results/checkm2/*.log log/
        """

# --- STEP 2: Taxonomy Assignment (Phylophlan) ---
# currently not written in the correct way
rule taxo:
    input:
        preprap = ".tmp/setup_complete.txt",
        folder = "data/mags/"
    output:
        "results/taxonomy/taxonomy_report.tsv"
    shell:
        """
        phylophlan_metagenomics -i data/mags/ -d results/taxonomy -o results/taxonomy/ --nproc 8
        """

# --- STEP 3: Annotation (Prokka) ---
rule anno:
    input:
        preprap = ".tmp/setup_complete.txt",    
        mags = expand("data/mags/{sample}.fna", sample=SAMPLES)
    output:
        "results/annotation/{sample}/{sample}.gff"
    conda:
        "envs/ANNO.yml"
    shell:
        """
        mkdir -p results/annotaiton
        prokka --outdir {output} --prefix {wildcard.sample} {input.mags} --centre X --compliant # --force
        # eggnog-mapper -i {input.mags} -o {output} --cpu 8 --data_dir {config[eggnog_db_path]} --output_dir results/functional_annotation/ --override
        """
# rule fun_anno:
#     input: 
#     output: 
#     run: 

rule visual_fun_anno:
    input: 
        txt = config["kegg_annotations_file"]
    output:
        "results/kegg/kegganog_results.tsv"
    conda:
        "envs/KEGGA.yml"
    shell:
        """
        echo "Visualizing KEGG annotations with KEGGaNOG..."
        KEGGaNOG -M -i {input.txt} -o results/kegg --overwrite -g -v &2>1 | tee -a log/kegganog_fun_anno.log
        echo "done, this is to be updated" > {output}
        python scripts/Anno/visual.py results/kegg/merged_pathways.tsv results/kegg/
        """

# --- STEP 4: Pangenome (Roary) ---
# roary is stupid and want to beexecuted directly in the folder, so the options are:
# - creating soft links in a tmp folder
# - moving later the results from the /data/ folder to the results

# currently problems with linking this step with the previous one
rule pan:
    input:
        "finished.file.anno.txt"
    output:
        "results/pangenome/summary_statistics.txt"
    # params:
        # outdir = config[outdir_pan]
    conda:
        "envs/PAN.yml"
    shell:
        """
        mkdir -p path
        
        for dir in {input}/*/; do
            sample=$(basename $dir)
            ln -sf $(realpath $dir/$)
        """


# --- STEP 5: Phylogeny (PhyloPhlAn) ---
# not handling database? dont remember how do i download it (has to add in the download rule)
rule phylo:
    input:
        expand("data/mags/{sample}/{sample}.faa", sample=SAMPLES)
    output:
        "results/phylogeny/phylo_tree.nwk"
    params:
        outdir = config["phylophlan_out_dir"],
        db = config["phylophlan_db_path"]
    shell:
        """
        # should do a check on the prsence of the 
        philophlan_write_default_configs.sh
        
        phylophlan -i {input} -o {params.outdir} -d {params.db} \
        --nproc 8 -t a -f supermatrix_aa.cfg --diversity low --accurate 
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
