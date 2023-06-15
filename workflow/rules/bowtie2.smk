rule bowtie2_build_human:
    """Build bowtie2 index for the human reference

    Let the script decide to use a small or a large index based on the size of
    the reference genome.
    """
    input:
        reference=REFERENCE / "human.fa.gz",
    output:
        multiext(
            f"{REFERENCE}/human",
            ".1.bt2",
            ".2.bt2",
            ".3.bt2",
            ".4.bt2",
            ".rev.1.bt2",
            ".rev.2.bt2",
        ),
    log:
        BOWTIE2 / "build_human.log",
    benchmark:
        BOWTIE2 / "build_human.bmk"
    conda:
        "../envs/bowtie2.yml"
    params:
        output_path=REFERENCE / "human",
        extra=params["bowtie2"]["extra"],
    threads: 8
    shell:
        """
        bowtie2-build \
            --threads {threads} \
            {params.extra} \
            {input.reference} \
            {params.output_path} \
        2> {log} 1>&2
        """


rule bowtie2_map_human_one:
    """Map one library to reference genome using bowtie2

    Output SAM file is piped to samtools sort to generate a CRAM file.
    """
    input:
        forward_=FASTP / "{sample}.{library}_1.fq.gz",
        reverse_=FASTP / "{sample}.{library}_2.fq.gz",
        idx=multiext(
            f"{REFERENCE}/human",
            ".1.bt2",
            ".2.bt2",
            ".3.bt2",
            ".4.bt2",
            ".rev.1.bt2",
            ".rev.2.bt2",
        ),
        reference=REFERENCE / "human.fa.gz",
    output:
        cram=protected(BOWTIE2 / "{sample}.{library}.human.cram"),
    log:
        BOWTIE2 / "{sample}.{library}.human.log",
    benchmark:
        BOWTIE2 / "{sample}.{library}.human.bmk"
    params:
        index_prefix=REFERENCE / "human",
        extra=params["bowtie2"]["extra"],
        samtools_mem=params["bowtie2"]["samtools"]["mem_per_thread"],
        rg_id=compose_rg_id,
        rg_extra=compose_rg_extra,
        unpaired_template=lambda wildcards: BOWTIE2
        / f"{wildcards.sample}.{wildcards.library}.unpaired_%.fq.gz",
    threads: 24
    conda:
        "../envs/bowtie2.yml"
    resources:
        mem_mb=30000,
        runtime=1440,
    shell:
        """
        (bowtie2 \
            -x {params.index_prefix} \
            -1 {input.forward_} \
            -2 {input.reverse_} \
            --threads {threads} \
            --rg-id '{params.rg_id}' \
            --rg '{params.rg_extra}' \
            {params.extra} \
        | samtools sort \
            -l 9 \
            -M \
            -m {params.samtools_mem} \
            -o {output.cram} \
            --reference {input.reference} \
            --threads {threads} \
        ) 2> {log} 1>&2
        """


rule bowtie2_map_human_all:
    input:
        [BOWTIE2 / f"{sample}.{library}.human.cram" for sample, library in SAMPLE_LIB],


rule bowtie2_extract_nonhuman_one:
    input:
        cram=BOWTIE2 / "{sample}.{library}.human.cram",
        fqgz=FASTP / "{sample}.{library}_{end}.fq.gz",
        fqgz_fai=FASTP / "{sample}.{library}_{end}.fq.gz.fai",
        fqgz_gzi=FASTP / "{sample}.{library}_{end}.fq.gz.gzi",
    output:
        fqgz=BOWTIE2 / "{sample}.{library}.nonhuman_{end}.fq.gz",
    log:
        BOWTIE2 / "{sample}.{library}.nonhuman_{end}.log",
    threads: 24
    params:
        end=lambda wildcards: f"/{wildcards.end}",
    conda:
        "../envs/bowtie2.yml"
    shell:
        """
        samtools view {input.cram} \
        | awk '$3 == "*"' \
        | cut -f 1 \
        | awk '{{print $0"{params.end}"}}' \
        | sort -u \
        | xargs samtools fqidx {input.fqgz}  \
        | bgzip -l 9 -@ {threads} \
        > {output.fqgz}
        """


rule bowtie2_extract_nonhuman_all:
    input:
        [
            BOWTIE2 / f"{sample}.{library}.nonhuman_{end}.fq.gz"
            for sample, library in SAMPLE_LIB
            for end in ["1", "2"]
        ],


rule bowtie2_build_chicken:
    """Build bowtie2 index for the human reference

    Let the script decide to use a small or a large index based on the size of
    the reference genome.
    """
    input:
        reference=REFERENCE / "chicken.fa.gz",
    output:
        multiext(
            f"{REFERENCE}/chicken",
            ".1.bt2",
            ".2.bt2",
            ".3.bt2",
            ".4.bt2",
            ".rev.1.bt2",
            ".rev.2.bt2",
        ),
    log:
        BOWTIE2 / "build_chicken.log",
    benchmark:
        BOWTIE2 / "build_chicken.bmk"
    conda:
        "../envs/bowtie2.yml"
    params:
        output_path=REFERENCE / "chicken",
        extra=params["bowtie2"]["extra"],
    threads: 8
    shell:
        """
        bowtie2-build \
            --threads {threads} \
            {params.extra} \
            {input.reference} \
            {params.output_path} \
        2> {log} 1>&2
        """


rule bowtie2_map_chicken_one:
    """Map one library to reference genome using bowtie2

    Output SAM file is piped to samtools sort to generate a CRAM file.
    """
    input:
        forward_=BOWTIE2 / "{sample}.{library}.nonhuman_1.fq.gz",
        reverse_=BOWTIE2 / "{sample}.{library}.nonhuman_2.fq.gz",
        idx=multiext(
            f"{REFERENCE}/chicken",
            ".1.bt2",
            ".2.bt2",
            ".3.bt2",
            ".4.bt2",
            ".rev.1.bt2",
            ".rev.2.bt2",
        ),
        reference=REFERENCE / "chicken.fa.gz",
    output:
        cram=protected(BOWTIE2 / "{sample}.{library}.chicken.cram"),
    log:
        BOWTIE2 / "{sample}.{library}.chicken.log",
    benchmark:
        BOWTIE2 / "{sample}.{library}.chicken.bmk"
    params:
        index_prefix=REFERENCE / "chicken",
        extra=params["bowtie2"]["extra"],
        samtools_mem=params["bowtie2"]["samtools"]["mem_per_thread"],
        rg_id=compose_rg_id,
        rg_extra=compose_rg_extra,
    threads: 24
    conda:
        "../envs/bowtie2.yml"
    resources:
        mem_mb=30000,
        runtime=1440,
    shell:
        """
        (bowtie2 \
            -x {params.index_prefix} \
            -1 {input.forward_} \
            -2 {input.reverse_} \
            --threads {threads} \
            --rg-id '{params.rg_id}' \
            --rg '{params.rg_extra}' \
            {params.extra} \
        | samtools sort \
            -l 9 \
            -M \
            -m {params.samtools_mem} \
            -o {output.cram} \
            --reference {input.reference} \
            --threads {threads} \
        ) 2> {log} 1>&2
        """


rule bowtie2_map_chicken_all:
    input:
        [BOWTIE2 / f"{sample}.{library}.chicken.cram" for sample, library in SAMPLE_LIB],


rule bowtie2_index_nonhuman_one:
    input:
        fqgz=BOWTIE2 / "{sample}.{library}.nonhuman_{end}.fq.gz",
    output:
        fqgz_fai=BOWTIE2 / "{sample}.{library}.nonhuman_{end}.fq.gz.fai",
        fqgz_gzi=BOWTIE2 / "{sample}.{library}.nonhuman_{end}.fq.gz.gzi",
    conda:
        "../envs/bowtie2.yml"
    log:
        BOWTIE2 / "{sample}.{library}.nonhuman_{end}.index.log",
    shell:
        "samtools fqidx {input.fqgz} 2> {log} 1>&2"


rule bowtie2_extract_nonchicken_one:
    input:
        cram=BOWTIE2 / "{sample}.{library}.chicken.cram",
        fqgz=BOWTIE2 / "{sample}.{library}.nonhuman_{end}.fq.gz",
        fqgz_fai=BOWTIE2 / "{sample}.{library}.nonhuman_{end}.fq.gz.fai",
        fqgz_gzi=BOWTIE2 / "{sample}.{library}.nonhuman_{end}.fq.gz.gzi",
    output:
        fqgz=BOWTIE2 / "{sample}.{library}.nonchicken_{end}.fq.gz",
    log:
        BOWTIE2 / "{sample}.{library}.nonchicken_{end}.log",
    threads: 24
    params:
        end=lambda wildcards: f"/{wildcards.end}",
    conda:
        "../envs/bowtie2.yml"
    shell:
        """
        samtools view {input.cram} \
        | awk '$3 == "*"' \
        | cut -f 1 \
        | awk '{{print $0"{params.end}"}}' \
        | sort -u \
        | xargs samtools fqidx {input.fqgz}  \
        | bgzip -l 9 -@ {threads} \
        > {output.fqgz}
        """


rule bowtie2_extract_nonchicken_all:
    input:
        [
            BOWTIE2 / f"{sample}.{library}.nonchicken_{end}.fq.gz"
            for sample, library in SAMPLE_LIB
            for end in ["1", "2"]
        ],


# rule bowtie2_report_all:
#     """Generate bowtie2 reports for all libraries:
#     - samtools stats
#     - samtools flagstats
#     - samtools idxstats
#     """
#     input:
#         [
#             BOWTIE2 / f"{sample}.{library}.{report}"
#             for sample, library in SAMPLE_LIB
#             for report in BAM_REPORTS
#         ],


rule bowtie2:
    """Run bowtie2 on all libraries and generate reports"""
    input:
        # rules.bowtie2_report_all.input,
        rules.bowtie2_extract_nonchicken_all.input,