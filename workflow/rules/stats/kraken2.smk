# rule stats_kraken2_assign_one:
#     """Run kraken2 over one library and using one database."""
#     input:
#         forward_=FASTP / "{sample}.{library}_1.fq.gz",
#         reverse_=FASTP / "{sample}.{library}_2.fq.gz",
#         database=get_kraken2_database,
#     output:
#         out_gz=KRAKEN2 / "{kraken2_db}/{sample}.{library}.out.gz",
#         report=KRAKEN2 / "{kraken2_db}/{sample}.{library}.report",
#     log:
#         log=KRAKEN2 / "{kraken2_db}/{sample}.{library}.log",
#     conda:
#         "stats.yml"
#     threads: 24
#     resources:
#         mem_mb=params["kraken2"]["mem_mb"],
#         runtime=60,
#     params:
#         is_paired=is_paired,
#     shell:
#         """
#         if [[ {params.is_paired} = "True" ]] ; then
#             kraken2 \
#                 --db {input.database} \
#                 --threads {threads} \
#                 --paired \
#                 --gzip-compressed \
#                 --output >(pigz > {output.out_gz}) \
#                 --report {output.report} \
#                 {input.forward_} \
#                 {input.reverse_} \
#             > {log} 2>&1
#         else
#             kraken2 \
#                 --db {input.database} \
#                 --threads {threads} \
#                 --gzip-compressed \
#                 --output >(pigz > {output.out_gz}) \
#                 --report {output.report} \
#                 {input.forward_} \
#             > {log} 2>&1
#         fi
#         """


rule pre_kraken2_assign_all:
    """Run kraken2 over all samples at once using the /dev/shm/ trick.

    NOTE: /dev/shm may be not empty after the job is done.
    """
    input:
        files=[
            FASTP / f"{sample}.{library}_{ending}.fq.gz"
            for sample, library in SAMPLE_LIB_PE + SAMPLE_LIB_SE
            for ending in ["1", "2"]
        ],
        database=get_kraken2_database,
    output:
        out_gzs=[
            KRAKEN2 / "{kraken2_db}" / f"{sample}.{library}.out.gz"
            for sample, library in SAMPLE_LIB_PE + SAMPLE_LIB_SE
        ],
        reports=[
            KRAKEN2 / "{kraken2_db}" / f"{sample}.{library}.report"
            for sample, library in SAMPLE_LIB_PE + SAMPLE_LIB_SE
        ],
    log:
        KRAKEN2 / "{kraken2_db}.log",
    threads: 24
    resources:
        mem_mb=params["stats"]["kraken2"]["memory_gb"] * 1024,
        runtime=60,
    params:
        in_folder=FASTP,
        out_folder=compose_out_folder_for_pre_kraken2_assign_all,
        kraken_db_shm="/dev/shm/{kraken2_db}",
    conda:
        "stats.yml"
    shell:
        """
        mapfile -t sample_ids < <(find "{params.in_folder}" -name "*_1.fq.gz" -exec basename {{}} _1.fq.gz \;)

        {{
            mkdir --parents {params.kraken_db_shm}
            mkdir --parents {params.out_folder}

            rsync \
                -Pravt \
                {input.database}/*.k2d \
                {params.kraken_db_shm} \
            2> {log} 1>&2

            for sample_id in ${{sample_ids[@]}} ; do \

                kraken2 \
                    --db {params.kraken_db_shm} \
                    --threads {threads} \
                    --gzip-compressed \
                    --output >(pigz > {params.out_folder}/${{sample_id}}.out.gz) \
                    --report {params.out_folder}/${{sample_id}}.report \
                    --memory-mapping \
                    {params.in_folder}/${{sample_id}}_1.fq.gz \
                    {params.in_folder}/${{sample_id}}_2.fq.gz \
                2> {params.out_folder}/${{sample_id}}.log  1>&2

            done
        }} || {{
            echo "Failed job" 2>> {log} 1>&2
        }}

        rm -rfv {params.kraken_db_shm} 2>>{log} 1>&2
        """


rule stats_kraken2_assign_all:
    input:
        [
            KRAKEN2 / f"{kraken2_db}/{sample}.{library}.report"
            for sample, library in SAMPLE_LIB_PE + SAMPLE_LIB_SE
            for kraken2_db in KRAKEN2_DBS
        ],


rule stats_kraken2_report_all:
    input:
        rules.stats_kraken2_assign_all.input,


rule stats_kraken2:
    input:
        rules.stats_kraken2_assign_all.input,
        rules.stats_kraken2_report_all.input,