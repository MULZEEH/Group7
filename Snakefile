# Snakefile
# File containting the run and structure of the overall pipeline;
# Pipeline Steps:
# 1) QC: First step is to perfrom a QUALITY CHECK on all the MAGs. The QC has been done using CheckM2(or QUAST) tool, 
#       which provides a comprehensive report on the quality of the MAGs, including completeness, contamination, and other relevant metrics. 
#       This step ensures that only high-quality MAGs are included in subsequent analyses.
#       What this needs: 
#       What this gives us: 
#       Why:
# 2) Taxonomy Assignment: Secondly GTDB-Tk	( https://doi.org/10.1093/bioinformatics/btz848) or Segata's PhyloPhlAn (https://pubmed.ncbi.nlm.nih.gov/23942190/) 
#       will be used to assign taxonomy to the MAGs, providing insights into their taxonomic classification and potential ecological roles.
#       What this needs: 
#       What this gives us: 
#       Why:
# 3) Genome Annotation: Crucial step	Bakta (or Prokka)
#       What this needs: 
#       What this gives us: 
#       Why:	
# 4) Pangenome analysis	(Roary)
#       What this needs: 
#       What this gives us: 
#       Why:
# 5) Phylogeny analysis	IQ-TREE 2	
#       What this needs: 
#       What this gives us: 
#       Why:
# 6) Association with host Metadata	Python (Pandas)	
#       What this needs: 
#       What this gives us: 
#       Why:


# Load configuration
configfile: "config.yml"

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

rule all:
    input:
        "results/checked.txt",
        "results/checkm2/quality_report.tsv",
        "results/pangenome/summary_statistics.txt"

rule check:
    input:
        bins = "data/mags/"
    output:
        flag = "results/checked.txt",
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
rule checkm2:
    input:
        bins = "data/mags/",
        flag = "results/checked.txt"
    output:
        report = "results/checkm2/quality_report.tsv"
    conda:
        "envs/QC.yml"
    shell:
        """
        export CHECKM2DB={config[checkm2_db_path]}
        checkm2 database --download
        checkm2 predict --threads 8 --input {input.bins} --output-directory results/checkm2
        """

# --- STEP 2: Taxonomy Assignment (GTDB-Tk) ---
rule gtdbtk:
    input:
        "data/mags/{sample}.fasta"
    output:
        "results/taxonomy/{sample}_classification.tsv"
    shell:
        "gtdbtk classify_wf --genome_dir data/mags/ --out_dir results/taxonomy/ --cpus 8 --extension fasta"

# --- STEP 3: Annotation (Prokka) ---
rule prokka:
    input:
        fasta = expand("data/mags/{sample}.fna", sample=SAMPLES),
        flag = "results/checked.txt"
    output:
        gff = "results/annotations/{sample}/{sample}.gff"
    params:
        outdir = "results/annotations/{sample}"
    shell:
        "prokka --outdir {params.outdir} --prefix {wildcards.sample} {input.fna} --force"

# --- STEP 4: Pangenome (Roary) ---
rule roary:
    input:
        expand("results/annotations/{sample}/{sample}.gff", sample=SAMPLES)
    output:
        "results/pangenome/summary_statistics.txt"
    params:
        outdir = "results/pangenome"
    shell:
        # Roary needs a folder of GFFs; we move them or point to the directory
        "roary -f {params.outdir} -e -n -v {input}"

# --- STEP 5: Metadata Association (Python) ---
rule associate_metadata:
    input:
        pangenome = "results/pangenome/gene_presence_absence.csv",
        metadata = "data/host_metadata.csv"
    output:
        "results/final_analysis/metadata_joined.csv"
    run:
        from importlib_metadata import files
        import pandas as pd
        pan = pd.read_csv(input.pangenome)
        meta = pd.read_csv(input.metadata)
        # Your custom Python logic here to link SGBs to host traits
        result = pan.merge(meta, left_on='Gene', right_on='Host_ID') 
        result.to_csv(output[0])