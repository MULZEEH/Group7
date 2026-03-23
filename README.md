# Bioinformatic Analysis of Dental Plaque MAGs
**Group Project: The "Plaque Gang"**

## 1. Project Overview
Microbes are ubiquitous and highly diverse, particularly within the human oral cavity. Traditional microbiology was limited by the "cultivation bottleneck"—the fact that most microbes cannot be grown in a lab. This project utilizes modern **metagenomic shotgun sequencing** to bypass this limitation.

### The Genomic Workflow
Our data follows this standard bioinformatics progression:
**Shotgun Sequencing** $\rightarrow$ **Short Reads** $\rightarrow$ **De-novo Assembly** $\rightarrow$ **Contigs** $\rightarrow$ **Binning** $\rightarrow$ **MAGs (Metagenome-Assembled Genomes)**.

We are specifically focusing on **SGBs (Species-level Genome Bins)** defined by MetaPhlAn4, which utilizes a database of 2.1M reference genomes to cluster MAGs into species-level groups based on marker genes.

---

## 2. Biological Context: Oral Cavity & Dental Implants
Our research focuses on the **Peri-implant microbiome**. Peri-implantitis is a disease linked to bacterial plaque that can lead to significant bone loss around dental implants.

* **Dataset:** PreBiomics BetaProgram (Plaque and Saliva samples).
* **Focus:** Plaque datasets from dental implants.
* **Key Concept:** Biofilms on teeth follow a structural successional layer:
    * **Early colonizers:** Usually associated with health.
    * **Intermediate colonizers:** Transition phase.
    * **Late colonizers:** Often associated with disease states (Peri-implantitis).
* **The Challenge:** Investigating the correlation between **uSGBs (Unknown Species-Level Genome Bins)** and disease states using log LDA scores.

---

## 3. Project Objectives
Our goal is to characterize a specific SGB consisting of **30 MAGs** recovered from dental plaque.

1.  **Quality Control (QC):** Assess the "cleanliness" (Completeness/Contamination) of the 30 FASTA files.
2.  **Taxonomic Assignment:** Determine the identity of our MAGs using global databases (GTDB).
3.  **Functional Annotation:** Predict the metabolic potential and genes of each genome.
4.  **Pangenome & Phylogeny:** Determine the core vs. accessory genome and visualize evolutionary relationships.
5.  **Metadata Association:** Correlate microbial data (taxonomy/abundance) with host factors (Age, Sex, Smoking, Disease status).

---

## 4. The Technical Pipeline

| Step | Tool | Objective |
| :--- | :--- | :--- |
| **0. Pre-processing** | `Bowtie2` | **Human Read Removal:** Filtering host DNA before analysis. |
| **1. QC** | `CheckM2` | Assess **Completeness** and **Contamination**. |
| **2. Taxonomy** | `GTDB-Tk` / `MetaPhlAn` | Assign a name to the MAG based on the Genome Taxonomy Database. |
| **3. Annotation** | `Bakta` / `Prokka` | Identify genes and metabolic pathways (GFF/GBK output). |
| **4. Pangenome** | `Roary` | Identify the **Core** vs. **Accessory** genome. |
| **5. Phylogeny** | `PhyloPhlAn``IQ-TREE 2` | Construct a high-resolution evolutionary tree. |
| **6. Statistics** | `python` / `R` | Perform Linear Regression/ANOVA to link metadata to microbial features. |

---

## 5. Administrative Details
* **Deliverables:** Written Report (~2000 words) + 8-minute Presentation (5 slides).
* **Deadline 1:** April 7th (Midnight) - Final Written Report.
* **Deadline 2:** April 8th (15:30) - Email submission to the 3 instructors.

---

## 6. Internal Q&A (Doubts)
* **Why QC on Fasta?** Even after assembly, a MAG might be "dirty" (containing DNA from multiple species) or "incomplete." We must verify its quality before trusting pangenome results.
* **Removing Human DNA?** Yes. In oral samples, human DNA can dominate. Removing it ensures we are analyzing microbial signals, not host contamination.
* **How can I have 1 MAG per sample?** Binning algorithms group contigs belonging to one species into one "bin." This MAG represents the specific strain of that species found in that specific patient.
* **Metadata Correlation:** We use **MaAsLin2** to see if the abundance of specific genes or taxa is significantly correlated with "Smoking" or "Peri-implantitis" while adjusting for "Age" and "Sex."

---

## 7. Task Allocation

### Fil
* QC Verification (CheckM2)
* Taxonomy (MetaPhlAn)
* Pangenome (Roary)
* Phylogeny (PhyloPhlAn)

### Marco
* Genome Annotation (Bakta/Prokka)
* Taxonomy testing (PhyloPhlAn)
* Phylogeny (Tree building)

### Shared
* Metadata correlation analysis (MaAsLin2/R)
* Report writing and slide preparation