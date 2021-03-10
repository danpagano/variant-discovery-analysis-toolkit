# *C. elegans* variant discovery analysis toolkit

This is a package of workflows designed to process *C. elegans* whole genome resequencing data
and identify single-nucleotide variants (SNVs) and strutural variants (SVs).
```
USAGE
vda.sh <workflow> [options]

EXAMPLE
vda.sh call-background-variants [options]

WORKFLOWS
vda-unmapped				Identify variants in an unmapped sample.
vda-mapped				Identify variants in a mapped sample.
call-background-variants		Call background variants in a sample.
call-mapping-variants			Call mapping variants in a sample.
compile-background-variants		Compile background variants among samples derived from the same parent.
clean-mapping-variants			Subtract background variants from mapping variants.
in-silico-complementation		Run in-silico complementation analysis.
```
