"""LocationControl PC Companion Controller."""

import warnings

# Suppress urllib3 / chardet / charset_normalizer version mismatch warning from requests
warnings.filterwarnings("ignore", message=".*doesn't match a supported version!.*")
warnings.filterwarnings("ignore", category=UserWarning)

__version__ = "1.0.0"
PROTOCOL_VERSION = 1

