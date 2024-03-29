rule _preprocess__fastp__trim:
    """Run fastp on one PE library"""
    input:
        forward_=READS / "{sample_id}.{library_id}_1.fq.gz",
        reverse_=READS / "{sample_id}.{library_id}_2.fq.gz",
    output:
        forward_=FASTP / "{sample_id}.{library_id}_1.fq.gz",
        reverse_=FASTP / "{sample_id}.{library_id}_2.fq.gz",
        unpaired1=FASTP / "{sample_id}.{library_id}_u1.fq.gz",
        unpaired2=FASTP / "{sample_id}.{library_id}_u2.fq.gz",
        html=FASTP / "{sample_id}.{library_id}_fastp.html",
        json=FASTP / "{sample_id}.{library_id}_fastp.json",
    log:
        FASTP / "{sample_id}.{library_id}.log",
    params:
        length_required=params["preprocess"]["fastp"]["length_required"],
        forward_adapter=get_forward_adapter,
        reverse_adapter=get_reverse_adapter,
    threads: 16
    resources:
        mem_mb=8 * 1024,
        runtime=240,
    conda:
        "__environment__.yml"
    shell:
        """
        fastp \
            --in1 {input.forward_} \
            --in2 {input.reverse_} \
            --out1 >(bgzip -l 9 -@ {threads} > {output.forward_}) \
            --out2 >(bgzip -l 9 -@ {threads} > {output.reverse_}) \
            --unpaired1 >(bgzip -l 9 -@ {threads} > {output.unpaired1}) \
            --unpaired2 >(bgzip -l 9 -@ {threads} > {output.unpaired2}) \
            --adapter_sequence {params.forward_adapter} \
            --adapter_sequence_r2 {params.reverse_adapter} \
            --html {output.html} \
            --json {output.json} \
            --length_required {params.length_required} \
            --thread {threads} \
            --trim_poly_g \
            --trim_poly_x \
            --verbose \
        2> {log} 1>&2
        """


rule preprocess__fastp__trim:
    """Run fastp over all libraries"""
    input:
        [
            FASTP / f"{sample_id}.{library_id}_{end}.fq.gz"
            for sample_id, library_id in SAMPLE_LIBRARY
            for end in "1 2 u1 u2".split(" ")
        ],


rule preprocess__fastp__fastqc:
    """Run fastqc over all libraries"""
    input:
        [
            FASTP / f"{sample_id}.{library_id}_{end}_fastqc.{extension}"
            for sample_id, library_id in SAMPLE_LIBRARY
            for end in ["1", "2"]
            for extension in ["html", "zip"]
        ],


rule preprocess__fastp__report:
    """Collect fastp and fastqc reports"""
    input:
        [
            FASTP / f"{sample_id}.{library_id}_fastp.json"
            for sample_id, library_id in SAMPLE_LIBRARY
        ],
        rules.preprocess__fastp__fastqc.input,


rule preprocess__fastp:
    """Run fastp and collect reports"""
    input:
        rules.preprocess__fastp__trim.input,
        rules.preprocess__fastp__report.input,
