# script to better visualize the functional annotationn of the MAGs

import kegganog as kgn
import pandas as pd
import sys
# configfile: "../config.yml"
format = "png"
# check for correct number of arguments
if len(sys.argv) != 3:
    print("Usage: python visual.py <input_tsv> <output_png>")
    sys.exit(1)

# variables from config (snakemake handles the config -> parameters)
path_tsv = sys.argv[1]
path_output = sys.argv[2]
# read the KEGGaNOG TSV file
df = pd.read_csv(path_tsv, sep="\t")
# Creating Barplot
kgnstbar = kgn.stacked_barplot(
    df,
    figsize=(10, 6),
    # title="Functional Annotation of MAGs set",
    cmap="tab20",
    xlabel="MAGs Set",
    ylabel="Completeness (%)",
    edgecolor="black",
    grid=True,
)
kgnstbar.savefig(f"{path_output}stacked_barplot.{format}")
# Createing the StreamGraph (will be used as background for Barplot)
kgnstream = kgn.streamgraph(
    df,
    figsize=(10, 6),
    # title="Functional Annotation of MAGs set",
    cmap="tab20",
    xlabel="MAGs Set",
    ylabel="Completeness (%)",
    edgecolor="black",
    grid=True,
)

path_output_stream = f"{path_output}streamgraph.{format}"
kgnstream.savefig(path_output_stream)

from PIL import Image

bottom = Image.open(f"{path_output}streamgraph.{format}").convert("RGBA")
top = Image.open(f"{path_output}stacked_barplot.{format}").convert("RGBA")

bottom.paste(top, (0, 0), top)
bottom.save(f"{path_output}combined_plot.{format}")