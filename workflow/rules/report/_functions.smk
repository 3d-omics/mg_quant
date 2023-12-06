def get_reads_reports_for_library_reports(wildcards):
    """Compose the paths for the reads reports"""
    sample = wildcards.sample
    library = wildcards.library
    return [READS / f"{sample}.{library}_{end}_fastqc.zip" for end in ["1", "2"]]


def get_fastp_reports_for_library_reports(wildcards):
    """Compose the paths for the fastp reports"""
    sample = wildcards.sample
    library = wildcards.library
    return [
        FASTP / f"{sample}.{library}_fastp.json",
        FASTP / f"{sample}.{library}_1_fastqc.zip",
        FASTP / f"{sample}.{library}_2_fastqc.zip",
    ]


def get_bowtie2_host_for_library_reports(wildcards):
    """Compose the paths for the bowtie2_hosts reports"""
    sample = wildcards.sample
    library = wildcards.library
    return [
        PRE_BOWTIE2 / host_name / f"{sample}.{library}.{report}"
        for host_name in HOST_NAMES
        for report in BAM_REPORTS
    ]


def get_bowtie2_mags_for_library_reports(wildcards):
    """Compose the paths for the bowtie2_mags reports"""
    sample = wildcards.sample
    library = wildcards.library
    return [
        QUANT_BOWTIE2 / mag_catalogue / f"{sample}.{library}.{report}"
        for mag_catalogue in MAG_CATALOGUES
        for report in ["stats.tsv", "flagstats.txt"]
    ]


def get_kraken2_for_library_reports(wildcards):
    """Compose the paths for the kraken2 reports"""
    sample = wildcards.sample
    library = wildcards.library
    return [
        KRAKEN2 / kraken2_db / f"{sample}.{library}.report"
        for kraken2_db in KRAKEN2_DBS
    ]


def get_report_step_kraken2_reports(wildcards):
    """Get all reports for the kraken2 step"""
    kraken2_db = wildcards.kraken2_db
    return [
        KRAKEN2 / kraken2_db / f"{sample}.{library}.report"
        for sample, library in SAMPLE_LIBRARY
    ]
