def get_bowtie2_for_library_reports(wildcards):
    sample = wildcards.sample
    library = wildcards.library
    return [
        BOWTIE2 / f"{sample}.{library}.{genome}.{report}"
        for genome in GENOMES
        for report in BAM_REPORTS
    ]