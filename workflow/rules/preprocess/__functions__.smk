# fastp ----
def get_forward_adapter(wildcards):
    """Get forward adapter for a sample and library."""
    adapter = samples[
        (samples["sample_id"] == wildcards.sample_id)
        & (samples["library_id"] == wildcards.library_id)
    ]["forward_adapter"].tolist()[0]
    if pd.isna(adapter):
        return "AGATCGGAAGAGCACACGTCTGAACTCCAGTCA"
    return adapter


def get_reverse_adapter(wildcards):
    """Get reverse adapter for a sample and library."""
    adapter = samples[
        (samples["sample_id"] == wildcards.sample_id)
        & (samples["library_id"] == wildcards.library_id)
    ]["reverse_adapter"].tolist()[0]
    if pd.isna(adapter):
        return "AGATCGGAAGAGCGTCGTGTAGGGAAAGAGTGT"
    return adapter


# bowtie2 ----
def compose_rg_id(wildcards):
    """Compose the read group ID for bowtie2"""
    return f"{wildcards.sample_id}_{wildcards.library_id}"


def compose_rg_extra(wildcards):
    """Compose the read group extra information for bowtie2"""
    return f"LB:truseq_{wildcards.library_id}\tPL:Illumina\tSM:{wildcards.sample_id}"


def get_input_forward_for_host_mapping(wildcards):
    """Compose the forward input file"""
    if wildcards.genome == HOST_NAMES[0]:
        return FASTP / f"{wildcards.sample_id}.{wildcards.library_id}_1.fq.gz"
    genome_index = HOST_NAMES.index(wildcards.genome)
    prev_genome = HOST_NAMES[genome_index - 1]
    return (
        PRE_BOWTIE2
        / f"non{prev_genome}"
        / f"{wildcards.sample_id}.{wildcards.library_id}_1.fq.gz"
    )


def get_input_reverse_for_host_mapping(wildcards):
    """Get the reverse input file"""
    if wildcards.genome == HOST_NAMES[0]:
        return FASTP / f"{wildcards.sample_id}.{wildcards.library_id}_2.fq.gz"
    genome_index = HOST_NAMES.index(wildcards.genome)
    prev_genome = HOST_NAMES[genome_index - 1]
    return (
        PRE_BOWTIE2
        / f"non{prev_genome}"
        / f"{wildcards.sample_id}.{wildcards.library_id}_2.fq.gz"
    )


def get_input_forward_for_mag_mapping(wildcards):
    """Get the forward input file for mapping to MAGs"""
    sample_id = wildcards.sample_id
    library_id = wildcards.library_id
    if len(HOST_NAMES) == 0:
        return FASTP / f"{sample_id}.{library_id}_1.fq.gz"
    genome = HOST_NAMES[-1]
    return PRE_BOWTIE2 / f"non{genome}" / f"{sample_id}.{library_id}_1.fq.gz"


def get_input_reverse_for_mag_mapping(wildcards):
    """Get the forward input file for mapping to MAGs"""
    sample_id = wildcards.sample_id
    library_id = wildcards.library_id
    if len(HOST_NAMES) == 0:
        return FASTP / f"{sample_id}.{library_id}_2.fq.gz"
    genome = HOST_NAMES[-1]
    return PRE_BOWTIE2 / f"non{genome}" / f"{sample_id}.{library_id}_2.fq.gz"


def get_kraken2_database(wildcards):
    """Get the kraken2 database"""
    return features["databases"]["kraken2"][wildcards.kraken2_db]


def compose_out_folder_for_pre_kraken2_assign_all(wildcards):
    """Compose the output folder for pre kraken2 assign all"""
    return KRAKEN2 / f"{wildcards.kraken2_db}"


def get_host_clean_forward(wildcards):
    """Get the forward input file that is clean from hosts"""
    last_genome = HOST_NAMES[-1]
    if len(HOST_NAMES) == 0:
        return FASTP / f"{wildcards.sample_id}.{wildcards.library_id}_1.fq.gz"
    return (
        PRE_BOWTIE2
        / f"non{last_genome}"
        / f"{wildcards.sample_id}.{wildcards.library_id}_1.fq.gz"
    )


def get_host_clean_reverse(wildcards):
    """Get the forward input file that is clean from hosts"""
    last_genome = HOST_NAMES[-1]
    if len(HOST_NAMES) == 0:
        return FASTP / f"{wildcards.sample_id}.{wildcards.library_id}_2.fq.gz"
    return (
        PRE_BOWTIE2
        / f"non{last_genome}"
        / f"{wildcards.sample_id}.{wildcards.library_id}_2.fq.gz"
    )


def compose_prefix_for_nonpareil(wildcards):
    """Compose prefix for nonpareil output files"""
    return NONPAREIL / f"{wildcards.sample_id}.{wildcards.library_id}"