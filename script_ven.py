# script to create a Venn diagram of the gene presence/absence data for the three conditions (healthy, mucositis, periimplantitis)
import pandas as pd
import matplotlib.pyplot as plt
from matplotlib_venn import venn3

# List of your file paths
files = ['tmp/healthy/output/gene_presence_absence.csv', 'tmp/mucositis/output/gene_presence_absence.csv', 'tmp/periimplantitis/output/gene_presence_absence.csv']

# Use a list comprehension to load and filter genes in one go
# It reads the CSV, filters for seq >= 9, and grabs the 'Gene' column as a set
gene_sets = []
for f in files:
    print(f"Processing: {f}")
    df = pd.read_csv(f)
    
    # 1. Filter the rows
    # 2. Select the 'Gene' column
    # 3. Drop any empty values (NaN)
    # 4. Convert to a set for Venn math
    filtered_genes = set(df[df["No. isolates"] >= 8]["Gene"].dropna())
    
    gene_sets.append(filtered_genes)

print(f"Done! Set sizes: {[len(s) for s in gene_sets]}")

# Create the Venn Diagram
plt.figure(figsize=(10, 7))
venn = venn3(
    subsets=gene_sets, 
    set_labels=('HEALTHY', 'MUCOSITIS', 'PERIIMPPLITIS')
)


plt.title("Genes Present in Each Condition (> 70%)")
plt.show()

