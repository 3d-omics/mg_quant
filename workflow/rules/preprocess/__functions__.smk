# fastp ----
def get_adapter(wildcards, forward_or_reverse):
    """Get forward or reverse adapter"""
    assert forward_or_reverse in ["forward_adapter", "reverse_adapter"]
    return samples[
        (samples["sample_id"] == wildcards.sample_id)
        & (samples["library_id"] == wildcards.library_id)
    ][forward_or_reverse].tolist()[0]


def get_forward_adapter(wildcards):
    """Get forward adapter for a sample and library."""
    return get_adapter(wildcards, "forward_adapter")


def get_reverse_adapter(wildcards):
    """Get reverse adapter for a sample and library."""
    return get_adapter(wildcards, "reverse_adapter")


# bowtie2 ----
def compose_rg_id(wildcards):
    """Compose the read group ID for bowtie2"""
    return f"{wildcards.sample_id}_{wildcards.library_id}"


def compose_rg_extra(wildcards):
    """Compose the read group extra information for bowtie2"""
    return f"LB:truseq_{wildcards.library_id}\tPL:Illumina\tSM:{wildcards.sample_id}"


def get_input_for_host_mapping(wildcards, forward_or_reverse):
    """Get the forward or reverse file for host mapping"""
    assert forward_or_reverse in ["forward_filename", "reverse_filename"]
    sample_id = wildcards.sample_id
    library_id = wildcards.library_id
    genome = wildcards.genome
    end = 1 if forward_or_reverse == "forward_filename" else 2
    if genome == HOST_NAMES[0]:
        return FASTP / f"{sample_id}.{library_id}_{end}.fq.gz"
    genome_index = HOST_NAMES.index(genome)
    previous_genome = HOST_NAMES[genome_index - 1]
    return (
        PRE_BOWTIE2 / f"non{previous_genome}" / f"{sample_id}.{library_id}_{end}.fq.gz"
    )


def get_input_forward_for_host_mapping(wildcards):
    """Compose the forward input file"""
    return get_input_for_host_mapping(wildcards, "forward_filename")


def get_input_reverse_for_host_mapping(wildcards):
    """Compose the forward input file"""
    return get_input_for_host_mapping(wildcards, "reverse_filename")


# Kraken2 ----
def get_kraken2_database(wildcards):
    """Get the kraken2 database"""
    return features["databases"]["kraken2"][wildcards.kraken2_db]


def compose_out_folder_for_pre_kraken2_assign_all(wildcards):
    """Compose the output folder for pre kraken2 assign all"""
    return KRAKEN2 / f"{wildcards.kraken2_db}"


# Nonpareil ----
def compose_prefix_for_nonpareil(wildcards):
    """Compose prefix for nonpareil output files"""
    return NONPAREIL / f"{wildcards.sample_id}.{wildcards.library_id}"


# last fastq files ----
def get_host_clean(wildcards, forward_or_reverse):
    """Get the input file that is clean from hosts"""
    assert forward_or_reverse in ["forward_clean", "reverse_clean"]
    end = 1 if forward_or_reverse == "forward_clean" else 2
    last_genome = HOST_NAMES[-1]
    sample_id = wildcards.sample_id
    library_id = wildcards.library_id
    if len(HOST_NAMES) == 0:
        return FASTP / f"{sample_id}.{library_id}_{end}.fq.gz"
    return PRE_BOWTIE2 / f"non{last_genome}" / f"{sample_id}.{library_id}_{end}.fq.gz"


def get_host_clean_forward(wildcards):
    """Get the forward input file that is clean from hosts"""
    return get_host_clean(wildcards, "forward_clean")


def get_host_clean_reverse(wildcards):
    """Get the forward input file that is clean from hosts"""
    return get_host_clean(wildcards, "reverse_clean")
