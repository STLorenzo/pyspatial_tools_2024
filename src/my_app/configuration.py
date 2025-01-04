"""
This module provides the Configuration class for managing application settings.
"""

import os
from pathlib import Path
import yaml


class Configuration:
    _instance = None

    def __init__(self):
        self._default_config: dict = {}
        self._config: dict = {}

    def __new__(cls, *args, **kwargs):
        if not cls._instance:
            cls._instance = super().__new__(cls, *args, **kwargs)
            cls._instance._initialize()
        return cls._instance
    
    @property
    def default_config(self):
        return self._default_config

    @property
    def config(self):
        return self._config
    
    @config.setter
    def config(self, value):
        self._config = value
    
    

    def _initialize(self):
        self.default_config = self._load_default_config()
        self.config = self.default_config.copy()

        default_config_path = Path(__file__).parent / "default_config.yaml"
        if os.path.exists(default_config_path):
            with open(default_config_path, "r") as f:
                return yaml.safe_load(f)
        return {}

    def load_config_from_file(self, config_path):
        if os.path.exists(config_path):
            with open(config_path, "r") as f:
                file_config = yaml.safe_load(f)
                self.config.update(file_config)

    def override_config(self, **kwargs):
        self.config.update(kwargs)





# Usage example:
# config = Configuration()
# config.load_config_from_file('/path/to/config.yaml')
# config.override_config(key1='value1', key2='value2')
# current_config = config.get_config()
