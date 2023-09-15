# imports
import argparse
from azureml.core import Workspace

# setup argparse
parser = argparse.ArgumentParser()
args = parser.parse_args()

# get workspace
ws = Workspace.from_config()

# process webservices
for webservice in ws.webservices:
    pass

# process compute targets
for compute_target in ws.compute_targets:
    pass
