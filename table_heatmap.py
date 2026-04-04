import sys

import pandas as pd
from scipy.stats import fisher_exact


df_roary = pd.read_csv(sys.argv[1], low_memory=False)
meta = pd.read_csv(sys.argv[2], sep='\t')
new_meta = meta.copy()

# 2. CLEAN IDs & PREPARE MATRIX
meta['magID_clean'] = meta['magID'].astype(str).str.replace('.fna', '', regex=False).str.replace('-', '_')
sample_data = df_roary.iloc[:, 14:]
sample_data.columns = [c.replace('.fna', '').replace('-', '_') for c in sample_data.columns]
pa_matrix = sample_data.notnull().astype(int)
pa_matrix.index = df_roary['Gene']

# 3. DEFINE GROUPS
g_a_ids = [i for i in meta[meta['study_group'] == 'periimplantitis']['magID_clean'] if i in pa_matrix.columns]
g_b_ids = [i for i in meta[meta['study_group'] == 'healthy']['magID_clean'] if i in pa_matrix.columns]
n_a, n_b = len(g_a_ids), len(g_b_ids)

# 4. CALCULATE FREQUENCIES AND FISHER P-VALUES
stats_list = []
print(f"Analyzing all {len(pa_matrix)} genes...")

for gene in pa_matrix.index:
    a_pres = pa_matrix.loc[gene, g_a_ids].sum()
    b_pres = pa_matrix.loc[gene, g_b_ids].sum()
    
    # Calculate percentages
    perc_a = round((a_pres / n_a) * 100, 1)
    perc_b = round((b_pres / n_b) * 100, 1)
    
    # Run Fisher Exact Test
    _, p_val = fisher_exact([[a_pres, n_a - a_pres], [b_pres, n_b - b_pres]])
    
    stats_list.append({
        'Gene': gene,
        'Peri_%': perc_a,
        'Healthy_%': perc_b,
        'Raw_P_Value': p_val
    })

# 5. CREATE RESULTS TABLE
results_df = pd.DataFrame(stats_list).set_index('Gene')

# 6. APPLY THE 70/30 FILTER (OR VICE VERSA)
# Condition 1: High in Peri (>70), Low in Healthy (<30)
# Condition 2: High in Healthy (>70), Low in Peri (<30)
interesting_genes = results_df[
    ((results_df['Peri_%'] > 70) & (results_df['Healthy_%'] < 30)) |
    ((results_df['Healthy_%'] > 70) & (results_df['Peri_%'] < 30))
].copy()

# Add Annotations from original Roary file
interesting_genes = interesting_genes.join(df_roary.set_index('Gene')[['Annotation']])

# Sort by most significant (lowest p-value)
interesting_genes = interesting_genes.sort_values('Raw_P_Value')

interesting_genes.to_csv('High_Contrast_Genes.tsv', sep='\t')
print(f"\nFound {len(interesting_genes)} genes matching the 70/30 criteria:")
print(interesting_genes[['Peri_%', 'Healthy_%', 'Raw_P_Value', 'Annotation']].head(20))

# Add information in the metadata about the presence/absence of these genes
# rename the magID column to sample_id
new_meta.rename(columns={'magID': 'sample_id'}, inplace=True)

for gene in interesting_genes.index:
    for mag in new_meta['sample_id']:
        if df_roary[df_roary['Gene'] == gene][mag].notnull().any():
            new_meta.loc[new_meta['sample_id'] == mag, gene] = int(1)
        else:
            new_meta.loc[new_meta['sample_id'] == mag, gene] = int(0)

new_meta['study_group'] = new_meta['study_group'].apply(lambda x: 1 if x == 'periimplantitis' else (0.5 if x == 'mucositis' else 0))
new_meta.to_csv('metadata_with_genes.tsv', sep='\t', index=False)

# also change the study_group from categorical to range 1 to 0 and 0.5 if mucositis
