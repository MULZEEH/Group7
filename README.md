# PAN-BIOBIN Pipeline: Dental Plaque MAG Analysis
**Group Project: The "Plaque Gang"**

## Project Overview

This pipeline analyzes **30 Metagenome-Assembled Genomes (MAGs)** recovered from dental plaque samples from the PreBiomics BetaProgram. We're characterizing an unknown species-level genome bin (uSGB) and investigating its correlation with peri-implantitis disease states.

### Why This Matters

Traditional microbiology couldn't grow most oral microbes in the lab. Using modern metagenomic shotgun sequencing, we can now bypass this "cultivation bottleneck" and study these organisms directly from environmental samples.

Our workflow follows the standard bioinformatics progression:
```
Shotgun Sequencing → Short Reads → De-novo Assembly → Contigs → Binning → MAGs
```

We focus on **SGBs (Species-level Genome Bins)** - clusters of MAGs at the species level defined using marker genes and reference databases like GTDB.

---

## The Technical Pipeline

| Step | Tool | Input | Output | Why? |
| :--- | :--- | :--- | :--- | :--- |
| **1. QC** | CheckM2 | MAGs (FASTA) | Completeness/Contamination % | Ensure data reliability |
| **2. Taxonomy** | GTDB-Tk / PhyloPhlAn | Clean MAGs (FASTA) | Taxonomic ranks (Genus/Species) | Identify the organism |
| **3. Annotation** | Prokka | Clean MAGs (FASTA) | Gene labels (GFF) | See metabolic potential |
| **4. Pangenome** | Roary | Annotation files (GFF) | Gene Presence/Absence Matrix | Find shared vs. unique traits |
| **5. Phylogeny** | PhyloPhlAn / IQ-TREE 2 | Gene Alignments | Evolutionary Tree (.nwk) | Map evolutionary history |
| **6. Metadata Association** | Python/R | Results + Host CSV | Statistical Correlations | Link genes to disease status |

---

## Setup

### 1. Prepare Your Data

Put your 30 MAG files in the `data/mags/` folder. Files should be compressed with `.bz2`:

```
data/mags/
├── M1076080470.fna.bz2
├── M1053959057.fna.bz2
├── M1078114725.fna.bz2
└── ... (all 30 samples)
```

The pipeline will automatically extract them.

### 2. Update the Sample List

Edit the `Snakefile` and update the `SAMPLES` list with your actual 30 sample names. Make sure names match your files (without the `.fna.bz2` extension).

### 3. Set Up Configuration

Create a `config.yml` file:

```yaml
# Database paths
checkm2_db_path: "data/checkm2/database/"
eggnog_db_path: "data/eggnog_db/"
phylophlan_db_path: "data/phylophlan_db/"
phylophlan_out_dir: "results/phylogeny/"
kegg_annotations_file: "data/kegg_annotations.txt"

# Options
backup: false          # Set to true to save backups after finishing
correlation: true      # Set to true to run metadata correlation with host factors
plane: false          # Set to true to skip functional annotation
keep_junk: false      # Set to true to keep temporary files
```

### 4. Set Up GitHub Token (Required for Metadata Correlation)

The **correlation** rule uses the Anpan tool, which downloads directly from GitHub. You need a personal GitHub token to do this.

**Generate your GitHub token:**
1. Go to https://github.com/settings/tokens
2. Click "Generate new token" → "Generate new token (classic)"
3. Give it a name (e.g., "anpan-pipeline")
4. Select scope: `repo` (full control of private repositories)
5. Click "Generate token" and copy it

**Add token to your system:**

Export it as an environment variable before running the pipeline:
```bash
export GITHUB_TOKEN="your_token_here"
snakemake -c 8 correlation --use-conda
```

Or permanently add it to your anpan envioronemtn in envs/anpan.yml (EOF):
```bash
variables:
  GITHUB_PATH: "[your_token_here :) ]"
```

**Note:** Only needed if you're running the `correlation` rule. If `correlation: false` in config.yml, you can skip this step.

### 5. Install Dependencies

All dependencies are in conda environments stored in the `envs/` folder:
- `envs/QC.yml` - Quality control (CheckM2)
- `envs/ANNO.yml` - Annotation (Prokka)
- `envs/PAN.yml` - Pangenome (Roary)
- `envs/EGG.yml` - EggNOG functional annotation
- `envs/KEGGA.yml` - KEGG pathway visualization
- `envs/anpan.yml` - Metadata correlation analysis

### 6. Add Metadata File

Place your host metadata CSV in `data/host_metadata.csv` with columns like:
- Sample ID
- Age
- Sex
- Smoking status
- Disease status (peri-implantitis yes/no)

This file is used by the metadata correlation step to link genes with host factors.

---

## Running the Pipeline

### Basic Run

```bash
snakemake -c 8 --use-conda
```

The `-c 8` uses 8 cores. Adjust based on your computer.

### Run Specific Steps

Quality control only:
```bash
snakemake -c 8 qc --use-conda
```

Taxonomy assignment only:
```bash
snakemake -c 8 taxo --use-conda
```

Annotation only:
```bash
snakemake -c 8 anno --use-conda
```

Pangenome analysis only:
```bash
snakemake -c 8 pan --use-conda
```

Phylogeny only:
```bash
snakemake -c 8 phylo --use-conda
```

Metadata correlation only (requires completed pangenome analysis):
```bash
snakemake -c 8 correlation --use-conda
```

---

## Additional Commands

### Download Required Databases

Before your first run, download CheckM2 and EggNOG databases:

```bash
snakemake -c 8 check_db --use-conda
snakemake -c 8 egg_db --use-conda
```

Or download both at once:
```bash
snakemake -c 8 database --use-conda
```

### Create a Backup

Save all results and logs to a backup folder (useful before cleaning):

```bash
snakemake -c 8 backup
```

Creates a compressed file with today's date.

### Visualize the Pipeline

See what steps will run before executing:

```bash
snakemake --dag | dot -Tsvg > pipeline_dag.svg
```

This generates a diagram of the workflow.

### Dry Run

Check what commands will execute without actually running them:

```bash
snakemake -c 8 --dry-run --use-conda
```

### Verbose Output

See detailed progress:

```bash
snakemake -c 8 --use-conda -v
```

---

## Output Files

After the pipeline finishes, results are organized by step:

- **results/checkm2/** - QC reports (completeness, contamination %)
- **results/taxonomy/** - Taxonomic assignments for each MAG
- **results/annotation/** - Gene predictions and annotations (GFF format)
- **results/pangenome/** - Gene presence/absence matrix and core genome
- **results/phylogeny/** - Evolutionary tree (phylo_tree.nwk) and alignments
- **results/final_analysis/** - Metadata correlation results (if enabled)
- **results/kegg/** - KEGG pathway visualizations (if enabled)
- **log/** - All pipeline log files

---

## Interpreting Results

### Quality Control
Completeness ≥ 90% and Contamination ≤ 5% indicates a high-quality MAG suitable for downstream analysis.

### Taxonomy
GTDB assigns standardized taxonomic ranks. This tells you what organism each MAG is.

### Pangenome
The core genome = genes present in ALL 30 MAGs (essential genes).
The accessory genome = genes in some but not all MAGs (variable genes).
This reveals what traits are shared vs. unique across your SGB.

### Phylogeny
The .nwk tree file shows evolutionary relationships. You can visualize it in tools like FigTree or iTOL to see how your 30 MAGs cluster.

### Metadata Correlation
Links microbial features (taxonomy, gene presence, abundance) to host factors (age, sex, smoking, disease status). This reveals which genes or traits are associated with peri-implantitis.

---

## Troubleshooting

### "Missing samples" Error

Check that:
1. File names in `data/mags/` match the `SAMPLES` list (without `.fna.bz2`)
2. All 30 files are present
3. No extra files are in the folder

### "Database not found" Error

Run database download first:
```bash
snakemake -c 8 check_db --use-conda
```

### Pipeline is Slow

- Reduce core count: `snakemake -c 4` uses 4 cores instead of 8
- Skip functional annotation (if not needed): set `plane: true` in config.yml
- Run steps in parallel on different computers

### Restart After Failure

```bash
snakemake -c 8 --use-conda --rerun-incomplete
```

---

## Configuration Options

In `config.yml`, you can control pipeline behavior:

| Option | Default | Effect |
| :--- | :--- | :--- |
| `backup: true` | false | Automatically save results after finishing |
| `correlation: true` | false | Include metadata correlation analysis (links genes to disease status) |
| `plane: true` | false | Skip functional annotation (faster, less disk space) |
| `keep_junk: true` | false | Don't delete temporary files (uses more disk space) |

---

## Biological Context: Why This Matters

**Peri-implantitis** is inflammation around dental implants caused by pathogenic biofilms. Understanding which microbes and genes are associated with disease is crucial for:
- Better diagnosis
- Targeted antimicrobial strategies
- Predicting implant success/failure

Biofilms have a successional structure:
- **Early colonizers** → Usually associated with health
- **Intermediate colonizers** → Transition phase
- **Late colonizers** → Often associated with disease

By analyzing your 30 MAGs and correlating them with patient metadata (age, smoking, disease status), you can identify which genes or taxa are risk factors for peri-implantitis.

---

## File Format Notes

- Input: MAGs must be `.fna.bz2` format (automatically extracted)
- Annotation output: GFF (General Feature Format)
- Phylogeny output: NWK (Newick tree format) - visualizable in FigTree, iTOL
- Pangenome output: CSV gene presence/absence matrix
- Metadata output: TSV/CSV files for statistical analysis

---

## Next Steps After Running

1. **Review QC:** Check completeness/contamination of your 30 MAGs
2. **Examine Taxonomy:** Identify what organisms you have
3. **Analyze Pangenome:** See what's core vs. accessory
4. **Visualize Tree:** Look at evolutionary relationships
5. **Correlate with Metadata:** Identify genes/taxa linked to disease status
6. **Write Report:** Synthesize findings into 2000-word report
7. **Create Presentation:** Summarize key findings in 5 slides
