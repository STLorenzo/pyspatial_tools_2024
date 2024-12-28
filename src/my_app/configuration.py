import os
import yaml

class Configuration:
    _instance = None

    def __new__(cls, *args, **kwargs):
        if not cls._instance:
            cls._instance = super(Configuration, cls).__new__(cls, *args, **kwargs)
            cls._instance._initialize()
        return cls._instance

    def _initialize(self):
        self.default_config = self._load_default_config()
        self.config = self.default_config.copy()

    def _load_default_config(self):
        default_config_path = os.path.join(os.path.dirname(__file__), 'default_config.yaml')
        if os.path.exists(default_config_path):
            with open(default_config_path, 'r') as f:
                return yaml.safe_load(f)
        return {}

    def load_config_from_file(self, config_path):
        if os.path.exists(config_path):
            with open(config_path, 'r') as f:
                file_config = yaml.safe_load(f)
                self.config.update(file_config)

    def override_config(self, **kwargs):
        self.config.update(kwargs)

    def get_config(self):
        return self.config

# Usage example:
# config = Configuration()
# config.load_config_from_file('/path/to/config.yaml')
# config.override_config(key1='value1', key2='value2')
# current_config = config.get_config()