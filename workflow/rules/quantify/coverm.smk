rule quantify__coverm__genome__:
    """Run coverm genome for one library and one mag catalogue"""
    input:
        cram=QUANT_BOWTIE2 / "{mag_catalogue}" / "{sample_id}.{library_id}.cram",
        crai=QUANT_BOWTIE2 / "{mag_catalogue}" / "{sample_id}.{library_id}.cram.crai",
        reference=REFERENCE / "mags" / "{mag_catalogue}.fa.gz",
        fai=REFERENCE / "mags" / "{mag_catalogue}.fa.gz.fai",
    output:
        tsv=touch(
            COVERM / "{mag_catalogue}/genome/{method}/{sample_id}.{library_id}.tsv"
        ),
    conda:
        "__environment__.yml"
    log:
        COVERM / "{mag_catalogue}/genome/{method}/{sample_id}.{library_id}.log",
    params:
        method="{method}",
        min_covered_fraction=params["quantify"]["coverm"]["genome"][
            "min_covered_fraction"
        ],
        separator=params["quantify"]["coverm"]["genome"]["separator"],
    shell:
        """
        ( samtools view \
            --with-header \
            --reference {input.reference} \
            {input.cram} \
        | coverm genome \
            --bam-files /dev/stdin \
            --methods {params.method} \
            --separator "{params.separator}" \
            --min-covered-fraction {params.min_covered_fraction} \
            --output-file {output.tsv} \
        ) 2> {log} 1>&2
        """


rule quantify__coverm__genome__aggregate__:
    """Aggregate all the nonpareil results into a single table"""
    input:
        get_coverm_genome_tsv_files_for_aggregation,
    output:
        COVERM / "coverm_genome_{mag_catalogue}.{method}.tsv",
    log:
        COVERM / "coverm_genome_{mag_catalogue}.{method}.log",
    conda:
        "__environment__.yml"
    params:
        input_dir=lambda w: COVERM / w.mag_catalogue / "genome" / w.method,
    shell:
        """
        Rscript --no-init-file workflow/scripts/aggregate_coverm.R \
            --input-folder {params.input_dir} \
            --output-file {output} \
        2> {log} 1>&2
        """


rule quantify__coverm__genome:
    """Run all rules to run coverm genome over all MAG catalogues"""
    input:
        [
            COVERM / f"coverm_genome_{mag_catalogue}.{method}.tsv"
            for mag_catalogue in MAG_CATALOGUES
            for method in params["quantify"]["coverm"]["genome"]["methods"]
        ],


rule quantify__coverm__contig__:
    """Run coverm contig for one library and one mag catalogue"""
    input:
        cram=QUANT_BOWTIE2 / "{mag_catalogue}" / "{sample_id}.{library_id}.cram",
        crai=QUANT_BOWTIE2 / "{mag_catalogue}" / "{sample_id}.{library_id}.cram.crai",
        reference=REFERENCE / "mags" / "{mag_catalogue}.fa.gz",
        fai=REFERENCE / "mags" / "{mag_catalogue}.fa.gz.fai",
    output:
        tsv=COVERM / "{mag_catalogue}/contig/{method}/{sample_id}.{library_id}.tsv",
    conda:
        "__environment__.yml"
    log:
        COVERM / "{mag_catalogue}/contig/{method}/{sample_id}.{library_id}.log",
    params:
        method="{method}",
    shell:
        """
        ( samtools view \
            --with-header \
            --reference {input.reference} \
            {input.cram} \
        | coverm contig \
            --bam-files /dev/stdin \
            --methods {params.method} \
            --proper-pairs-only \
            --output-file {output.tsv} \
        ) 2> {log} 1>&2
        """


rule quantify__coverm__contig__aggregate__:
    """Aggregate all the nonpareil results into a single table"""
    input:
        get_coverm_contig_tsv_files_for_aggregation,
    output:
        COVERM / "coverm_contig_{mag_catalogue}.{method}.tsv",
    log:
        COVERM / "coverm_contig_{mag_catalogue}.{method}.log",
    conda:
        "__environment__.yml"
    params:
        input_dir=lambda w: COVERM / w.mag_catalogue / "contig" / w.method,
    shell:
        """
        Rscript --no-init-file workflow/scripts/aggregate_coverm.R \
            --input-folder {params.input_dir} \
            --output-file {output} \
        2> {log} 1>&2
        """


rule quantify__coverm__contig:
    """Run all rules to run coverm contig over all MAG catalogues"""
    input:
        [
            COVERM / f"coverm_contig_{mag_catalogue}.{method}.tsv"
            for mag_catalogue in MAG_CATALOGUES
            for method in params["quantify"]["coverm"]["contig"]["methods"]
        ],


rule quantify__coverm:
    """Run both coverm overall and contig"""
    input:
        rules.quantify__coverm__genome.input,
        rules.quantify__coverm__contig.input,
