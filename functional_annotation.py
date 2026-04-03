# preparation script from genes more than n in set and prepare protein files
import pandas as pd
import matplotlib.pyplot as plt
import re
from Bio import SeqIO

def ID_from_gene_name(gene_name, file):
    """Maps a Roary Gene Name to a specific sample's Gene ID and MAG name."""
    try:
        df = pd.read_csv(file) 
        row = df[df['Gene'].str.strip() == gene_name]
        
        if row.empty:
            return None

        # Metadata in Roary usually ends at 'Avg group size nuc'
        start_col_index = df.columns.get_loc('Avg group size nuc') + 1
        sample_columns = df.columns[start_col_index:]
        
        for mag_id in sample_columns:
            gene_id = row[mag_id].values[0]
            if pd.notna(gene_id) and str(gene_id).strip() != "":
                return (gene_id, mag_id)
        return None
    except Exception as e:
        print(f"Error processing {file}: {e}")
        return None

def ID_to_AA_seq(gene_id, fasta_file):
    """Retrieves the amino acid sequence from a FASTA file given a Gene ID."""
    for record in SeqIO.parse(fasta_file, "fasta"):
        if record.id == str(gene_id):
            return str(record.seq)
    return None

def clean_group_genes(gene_set):
    """Removes genes starting with 'group_' (unannotated Roary clusters)."""
    to_remove = {g for g in gene_set if re.match(r'^group_.*', g)}
    return gene_set - to_remove

def prepare_file(gene_list, output_file):
    with open(output_file, 'a') as f:
        for gene, seq in gene_list:
            f.write(f"> {gene}\n{seq}\n")


def main():
    # 1. Setup File Paths
    files = [
        'tmp/healthy/output/gene_presence_absence.csv', 
        'tmp/mucositis/output/gene_presence_absence.csv', 
        'tmp/periimplantitis/output/gene_presence_absence.csv',
        'tmp/smoking/output/gene_presence_absence.csv'
    ]

    # 2. Load and filter Gene Sets (Isolates >= 9)
    raw_sets = []
    for f in files:
        print(f"Processing: {f}")
        df = pd.read_csv(f)
        # Filter for prevalence and remove NaNs
        filtered = set(df[df["No. isolates"] >= 5]["Gene"].dropna())
        raw_sets.append(filtered)

    # 3. Perform Set Logic (Venn/Pie Data)
    # raw_sets order: 0: Healthy, 1: Mucositis, 2: Periimplantitis
    h, m, p = raw_sets[0], raw_sets[1], raw_sets[2]

    pie_data = {
        "Only Healthy": h - (m | p),
        "Only Mucositis": m - (h | p),
        "Only Periimplantitis": p - (h | m),
        "Healthy & Mucositis": (h & m) - p,
        "Healthy & Periimplantitis": (h & p) - m,
        "Mucositis & Periimplantitis": (m & p) - h,
        "Common Core": h & m & p
    }

    # Optional clean for hypotetical proteins
    # 4. Clean "group_" genes from all sets
    # print("\nCleaning unannotated 'group_' genes...")
    # for label, g_set in pie_data.items():
    #     before = len(g_set)
    #     pie_data[label] = clean_group_genes(g_set)
    #     after = len(pie_data[label])
    #     print(f"{label}: Removed {before - after} group genes. Remaining: {after}")

    # 5. Example: Extracting sequences for "Only Periimplantitis" genes
    # This is where your pipeline connects to the functional enrichment step
    print("\n--- Example Sequence Extraction (Periimplantitis Specific) ---")
    target_genes = [list(pie_data["Only Periimplantitis"]), list(pie_data["Only Mucositis"]), list(pie_data["Only Healthy"]) ]
    labels = ["Only Periimplantitis", "Only Mucositis", "Only Healthy"]
    # Path to the pan-genome reference created by Roary 
    # REMEMBER THAT THE OUTPUT FOLDER IS WRONG, I NEED TO CHANGE IT 
    peri_csv = "results/pangenome/output1/gene_presence_absence.csv"
    n = 0
    # for loop with iter over the targetted list
    for target in target_genes:
        for gene in target:
            mapping = ID_from_gene_name(gene, peri_csv)
            if mapping:
                g_id, mag = mapping
                sequence = ID_to_AA_seq(g_id, f"results/annotations/{mag}/{mag}.faa")
                if sequence:
                    print(f"Gene: {gene} | ID: {g_id} | MAG: {mag} | Seq Length: {len(sequence)}\n Sequence: {sequence[:60]}...") # Print first 60 AA
                    prepare_file([(gene, sequence)], f"{labels[n]}_prot.faa")
        n+=1

if __name__ == "__main__":
    main()