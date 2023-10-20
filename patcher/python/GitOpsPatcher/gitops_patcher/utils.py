import yaml
import json

def parse_config(config_path):
    with open(config_path, 'r') as file:
        return yaml.load(file, Loader=yaml.FullLoader)

def update_nested_dict(data, keys, value):
    for key in keys[:-1]:
        data = data.setdefault(key, {})
    data[keys[-1]] = value
