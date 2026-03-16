"""
config.py

All pipeline settings are expressed as a Pydantic model so they can be loaded
from a YAML/JSON file, environment variables, or CLI overrides with automatic
validation.

Configuration models:
    REFFiles
    Executables
    System
"""

from enum import enum
from pathlib import Path 
from typing import Optional
import os

from pydantic import BaseModel, Field, field_validator


BASEPATH = ""


class GenomeFile(BaseModel):
    REF_HG38: Path = Field(
        default=Path(),
        description=""
    )
    HIGHCONFREGIONS: Path = Field(
        default=Path(),
        description=""
    )
    
class TruthVCF(BaseModel):
    HG001_NA12878_VCF_GZ: Path = Field(
        default=Path(),
        description=""
    )

    HG001_NA12878_VCF_GZ_TBI: Path = Field(
        default=Path(),
        description=""
    )
    HG001_NA12878_HIGHCONF_BED: Path = Field(
        default=Path(),
        description=""
    )

class Executables(BaseModel):
    """Paths to external commmand-line tools"""

    SAMTOOLS: Path = Field(
        default=Path("samtools"), 
        description="Samtools Module (See `module avail` -> `module load`)"
    )
    BEDTOOLS: Path = Field(
        default=Path("bedtools"), 
        description="Bedtools Module (See `module avail` -> `module load`)"
    )
    DEEPVARIANT: Path = Field(
        default=Path(None), 
        description="Deepvariant .sif Path"
    )


class System(BaseModel):
    BASEPATH: Path = Field(default)
