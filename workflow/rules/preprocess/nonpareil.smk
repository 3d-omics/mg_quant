rule preprocess__nonpareil__:
    """Run nonpareil over one sample

    NOTE: Nonpareil only ask for one of the pair-end reads
    NOTE: it has to be fastq. The process substitution trick does not work
    NOTE: in case that nonpareil fails for low coverage samples, it creates empty files
    """
    input:
        cram=get_host_clean_cram,
        reference=REFERENCE / f"{LAST_HOST}.fa.gz",
    output:
        npa=touch(NONPAREIL / "run" / "{sample_id}.{library_id}.npa"),
        npc=touch(NONPAREIL / "run" / "{sample_id}.{library_id}.npc"),
        npl=touch(NONPAREIL / "run" / "{sample_id}.{library_id}.npl"),
        npo=touch(NONPAREIL / "run" / "{sample_id}.{library_id}.npo"),
    log:
        NONPAREIL / "run" / "{sample_id}.{library_id}.log",
    conda:
        "__environment__.yml"
    params:
        prefix=lambda w: NONPAREIL / "run" / f"{w.sample_id}.{w.library_id}",
    shell:
        """
        samtools fastq \
            --threads {threads} \
            --reference {input.reference} \
            -1 {params.prefix}_1.fq \
            -2 /dev/null \
            -0 /dev/null \
            -f 12 \
            {input.cram} \
        2> {log} 1>&2

        nonpareil \
            -s {params.prefix}_1.fq \
            -T kmer \
            -b {params.prefix} \
            -f fastq \
            -t {threads} \
        2>> {log} \
        1>&2 || true

        rm --force --verbose {params.prefix}_1.fq 2>> {log} 1>&2
        """


rule preprocess__nonpareil__curves__:
    """Export nonpareil results to json for multiqc"""
    input:
        NONPAREIL / "run" / "{sample_id}.{library_id}.npo",
    output:
        NONPAREIL / "run" / "{sample_id}.{library_id}.json",
    log:
        NONPAREIL / "run" / "{sample_id}.{library_id}.json.log",
    conda:
        "__environment__.yml"
    params:
        labels=lambda w: f"{w.sample_id}.{w.library_id}",
    shell:
        """
        Rscript --no-init-file $(which NonpareilCurves.R) \
            --labels {params.labels} \
            --json {output} \
            {input} \
        2> {log} 1>&2
        """


rule preprocess__nonpareil__aggregate__:
    """Aggregate all the nonpareil results into a single table"""
    input:
        [
            NONPAREIL / "run" / f"{sample_id}.{library_id}.{suffix}"
            for sample_id, library_id in SAMPLE_LIBRARY
            for suffix in ["npa", "npc", "npl", "npo"]
        ],
    output:
        tsv=NONPAREIL / "nonpareil.tsv",
    log:
        NONPAREIL / "nonpareil.log",
    conda:
        "__environment__.yml"
    params:
        input_dir=NONPAREIL / "run",
    shell:
        """
        Rscript --no-init-file workflow/scripts/aggregate_nonpareil.R \
            --input-folder {params.input_dir} \
            --output-tsv {output.tsv} \
        2> {log} 1>&2
        """


rule preprocess__nonpareil:
    """Run nonpareil over all samples and produce JSONs for multiqc"""
    input:
        [
            NONPAREIL / "run" / f"{sample_id}.{library_id}.json"
            for sample_id, library_id in SAMPLE_LIBRARY
        ],
        NONPAREIL / "nonpareil.tsv",
